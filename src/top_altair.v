module top
(
  // Clock
  input clk_25mhz,
  // Uart
  input ftdi_txd,
  output ftdi_rxd,
  // Buttons
  input [6:0] btn,
  // Switches
  input [3:0] sw,
  // GPIO
  inout  [27:0] gp,gn,
  // HDMI
  output [3:0]  gpdi_dp,
  output [3:0]  gpdi_dn,
  // Leds
  output [7:0] led
);

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
  wire clk_hdmi = clocks[0];

  wire [15:0] addrLEDs;
  wire [7:0] dataLEDs;
  wire [7:0] debugLEDs;
  reg [7:0] dir = 0;
  wire [7:0] sense;
  wire [7:0] statusLEDs;

  wire   [7:0]  red;
  wire   [7:0]  green;
  wire   [7:0]  blue;
  wire          hsync;
  wire          vsync;
  wire          vga_de;

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

  assign led = dataLEDs;

  reg [5:0] reset_cnt;
  wire resetn = &reset_cnt;

  wire interrupt_ack, n_memWR, io_stack, halt_ack, ioWR, m1, ioRD, memRD;
  assign statusLEDS = {interrupt_ack, n_memWR, io_stack, halt_ack, ioWR, m1, ioRD, memRD};

  always @(posedge clk_25mhz) begin
    reset_cnt <= reset_cnt + !resetn;
  end

  altair machine(
    .clk(clk_vga),
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
    .memRD(memRD)
  );

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
    .statusLEDs(statusLEDs)
  );

  // ===============================================================
  // Convert VGA to HDMI
  // ===============================================================
  HDMI_out vga2dvid (
    .pixclk(clk_vga),
    .pixclk_x5(clk_hdmi),
    .red(red),
    .green(green),
    .blue(blue),
    .vde(vga_de),
    .hSync(hsync),
    .vSync(vsync),
    .gpdi_dp(gpdi_dp),
    .gpdi_dn(gpdi_dn)
  );

endmodule
