`default_nettype none
module top
(
  // Clock
  input         clk_25mhz,
  // Uart
  input         ftdi_txd,
  output        ftdi_rxd,
  // Keyboard
  input         usb_fpga_bd_dp,
  input         usb_fpga_bd_dn,
  output        usb_fpga_pu_dp,
  output        usb_fpga_pu_dn,
  // Buttons
  input [6:0]   btn,
  // Switches
  input [3:0]   sw,
  // GPIO
  inout  [27:0] gp,gn,
  // SPI from ESP32
  input         wifi_gpio16,
  input         wifi_gpio5,
  output        wifi_gpio0,
  inout   [3:0] sd_d,  
  // HDMI
  output [3:0]  gpdi_dp,
  output [3:0]  gpdi_dn,
  // Leds
  output [7:0]  led
);

  // ===============================================================
  // Clock generation
  // ===============================================================
  wire [3:0] clocks;
  ecp5pll
  #(
      .in_hz( 25*1000000),
    .out0_hz(125*1000000),
    .out1_hz( 25*1000000),
  )
  ecp5pll_inst
  (
    .clk_i(clk_25mhz),
    .clk_o(clocks)
  );

  wire clk_vga = clocks[1];
  wire clk_cpu = clocks[1];
  wire clk_hdmi = clocks[0];

  // ===============================================================
  // Reset generation
  // ===============================================================
  reg [5:0] reset_cnt;
  wire resetn = &reset_cnt;
  
  always @(posedge clk_25mhz) begin
    reset_cnt <= reset_cnt + !resetn;
  end

  // ===============================================================
  // Signals
  // ===============================================================
  wire [15:0] addrLEDs;
  wire [7:0]  dataLEDs;
  wire [7:0]  debugLEDs;
  wire [7:0]  sense;
  wire        interrupt_ack, n_memWR, io_stack, halt_ack, ioWR, m1, ioRD, memRD;

  wire [7:0]  red;
  wire [7:0]  green;
  wire [7:0]  blue;
  wire        hsync;
  wire        vsync;
  wire        vga_de;

  wire [3:0]  otherLEDs = {wt, hlda, inte, protect};
  wire [7:0]  statusLEDs = {memRD, ioRD, m1, ioWR, halt_ack, io_stack, n_memWR, interrupt_ack};

  reg [7:0]   dir = 0; // Dummy to make tri-state work
  reg         protect = 0, inte = 0, hlda = 0, wt = ~sw[0];

  reg [6:0]   r_btn_joy;
  reg [7:0]   r_cpu_control;
  wire        spi_load = r_cpu_control[1];
  wire [10:0] ps2_key;
  wire [31:0] spi_ram_addr;
  wire        spi_ram_wr, spi_ram_rd;
  wire [7:0]  spi_ram_di;
  wire [7:0]  spi_ram_do;

  // ===============================================================
  // Built-in leds
  // ===============================================================
  assign led = statusLEDs;

  // ===============================================================
  // GPIO pins
  // ===============================================================
  generate
    genvar i;
    for(i = 0; i < 4; i = i+1) begin
      assign gn[17-i] = addrLEDs[8+i];
      assign gp[17-i] = addrLEDs[12+i];
      assign gn[24-i] = addrLEDs[i];
      assign gp[24-i] = addrLEDs[4+i];

      assign gp[i] = dir[i] ? 1'b0 : 1'bz;
      assign gn[i] = dir[i] ? 1'b0 : 1'bz;
      assign sense[i] = gn[3-i];
      assign sense[4+i] = gp[3-i];
    end
  endgenerate

  // ===============================================================
  // Altair 8800
  // ===============================================================
  altair machine(
    .clk(clk_cpu),
    .reset(~resetn),
    .rx(ftdi_txd),
    .tx(ftdi_rxd),
    .dataLEDs(dataLEDs),
    .addrLEDs(addrLEDs),
    .debugLEDs(debugLEDs),
    .dataOraddrIn(sense),
    .addrOrSenseIn(8'b0),
    .stepPB(btn[1]),
    .pauseModeSW(~sw[0]),
    .examinePB(btn[2]),
    .examine_nextPB(btn[3]),
    .depositPB(btn[4]),
    .deposit_nextPB(btn[5]),
    .resetPB(~btn[0]),
    .interrupt_ack(interrupt_ack),
    .n_memWR(n_memWR),
    .io_stack(io_stack),
    .halt_ack(halt_ack),
    .ioWR(ioWR),
    .m1(m1),
    .ioRD(ioRD),
    .memRD(memRD),
    .ram_out(spi_ram_do),
    .spi_load(spi_load),
    .spi_ram_addr(spi_ram_addr[12:0]),
    .spi_ram_wr(spi_ram_wr && spi_ram_addr[31:24] == 8'h00),
    .spi_ram_rd(spi_ram_rd),
    .spi_ram_di(spi_ram_di)
  );

  // ===============================================================
  // Front panel
  // ===============================================================
  front_panel fp (
    .clk(clk_vga),
    .vga_r(red),
    .vga_g(green),
    .vga_b(blue),
    .vga_de(vga_de),
    .vga_hs(hsync),
    .vga_vs(vsync),
    .addrLEDs(addrLEDs),
    .dataLEDs(dataLEDs),
    .statusLEDs(statusLEDs),
    .otherLEDs(otherLEDs),
    .left(ps2_key == 11'h76b),
    .right(ps2_key == 11'h774),
    .up(ps2_key == 11'h775),
    .down(ps2_key == 11'h772)
  );

  // ===============================================================
  // SPI Slave from ESP32
  // ===============================================================
  wire        irq;

  assign sd_d[3] = 1'bz; // FPGA pin pullup sets SD card inactive at SPI bus
  assign wifi_gpio0 = ~irq;

  spi_ram_btn #(
    .c_sclk_capable_pin(1'b0),
    .c_addr_bits(32)
  ) spi_ram_btn_inst (
    .clk(clk_cpu),
    .csn(~wifi_gpio5),
    .sclk(wifi_gpio16),
    .mosi(sd_d[1]), // wifi_gpio4
    .miso(sd_d[2]), // wifi_gpio12
    .btn(r_btn_joy),
    .irq(irq),
    .wr(spi_ram_wr),
    .rd(spi_ram_rd),
    .addr(spi_ram_addr),
    .data_in(spi_ram_do),
    .data_out(spi_ram_di)
  );

  always @(posedge clk_cpu) begin
    if (spi_ram_wr && spi_ram_addr[31:24] == 8'hFF) begin
      r_cpu_control <= spi_ram_di;
    end
  end

  // ===============================================================
  // OSD
  // ===============================================================
  wire [7:0] osd_vga_r, osd_vga_g, osd_vga_b;
  wire osd_vga_hsync, osd_vga_vsync, osd_vga_blank;

  spi_osd #(
    .c_start_x(62), .c_start_y(80),
    .c_chars_x(64), .c_chars_y(20),
    .c_init_on(0),
    .c_char_file("osd.mem"),
    .c_font_file("font_bizcat8x16.mem")
  ) spi_osd_inst (
    .clk_pixel(clk_vga), .clk_pixel_ena(1),
    .i_r(red),
    .i_g(green),
    .i_b(blue),
    .i_hsync(~hsync), .i_vsync(~vsync), .i_blank(~vga_de),
    .i_csn(~wifi_gpio5), .i_sclk(wifi_gpio16), .i_mosi(sd_d[1]), // .o_miso(),
    .o_r(osd_vga_r), .o_g(osd_vga_g), .o_b(osd_vga_b),
    .o_hsync(osd_vga_hsync), .o_vsync(osd_vga_vsync), .o_blank(osd_vga_blank)
  );

  // ===============================================================
  // Convert VGA to HDMI
  // ===============================================================
  HDMI_out vga2dvid (
    .pixclk(clk_vga),
    .pixclk_x5(clk_hdmi),
    .red(osd_vga_r),
    .green(osd_vga_g),
    .blue(osd_vga_b),
    .vde(~osd_vga_blank),
    .hSync(osd_vga_hsync),
    .vSync(osd_vga_vsync),
    .gpdi_dp(gpdi_dp),
    .gpdi_dn(gpdi_dn)
  );

  // ===============================================================
  // Joystick for OSD control and games
  // ===============================================================
  always @(posedge clk_cpu) r_btn_joy <= btn;

  // ===============================================================
  // Keyboard
  // ===============================================================
  assign usb_fpga_pu_dp = 1; // pull-ups for us2 connector
  assign usb_fpga_pu_dn = 1;

  // Get PS/2 keyboard events
  ps2 ps2_kbd (
    .clk(clk_cpu),
    .ps2_clk(usb_fpga_bd_dp),
    .ps2_data(usb_fpga_bd_dn),
    .ps2_key(ps2_key)
  );

endmodule
