`default_nettype none
module front_panel (
  input         clk,
  input         reset,
  output [7:0]  vga_r,
  output [7:0]  vga_b,
  output [7:0]  vga_g,
  output        vga_hs,
  output        vga_vs,
  output        vga_de,
  input [15:0]  addrLEDs,
  input [7:0]   dataLEDs,
  input [7:0]   statusLEDs,
  input [3:0]   otherLEDs
);

  parameter HA = 640;
  parameter HS  = 96;
  parameter HFP = 16;
  parameter HBP = 48;
  parameter HT  = HA + HS + HFP + HBP;
  parameter HB = 0;
  parameter HB2 = HB/2;

  parameter VA = 480;
  parameter VS  = 2;
  parameter VFP = 11;
  parameter VBP = 31;
  parameter VT  = VA + VS + VFP + VBP;
  parameter VB = 230;
  parameter VB2 = VB/2;

  assign vga_hs = !(hc >= HA + HFP && hc < HA + HFP + HS);
  assign vga_vs = !(vc >= VA + VFP && vc < VA + VFP + VS);
  assign vga_de = !(hc >= HA || vc >= VA);

  reg [9:0] hc = 0;
  reg [9:0] vc = 0;

  wire [9:0] x = hc;
  reg [8:0] y = vc - VB2;

  always @(posedge clk) begin
    if (hc == HT - 1) begin
      hc <= 0;
      if (vc == VT - 1) vc <= 0;
      else vc <= vc + 1;
    end else hc <= hc + 1;
  end

  reg [9:0] addr_led_x[0:15];
  reg [8:0] addr_led_y[0:15];
  reg [9:0] addr_sw_x[0:15];
  reg [8:0] addr_sw_y[0:15];
  reg [9:0] data_led_x[0:7];
  reg [8:0] data_sw_y[0:7];
  reg [9:0] data_sw_x[0:7];
  reg [8:0] data_led_y[0:7];
  reg [9:0] status_led_x[0:7];
  reg [8:0] status_led_y[0:7];
  reg [9:0] other_led_x[0:3];
  reg [8:0] other_led_y[0:3];
  wire [15:0] in_addr_led;
  wire [15:0] in_addr_sw;
  wire [7:0] in_data_led;
  wire [7:0] in_data_sw;
  wire [7:0] in_status_led;
  wire [3:0] in_other_led;
  wire [15:0] lit_addr_led;
  wire [7:0] lit_data_led;
  wire [7:0] lit_status_led;
  wire [3:0] lit_other_led;
 
  integer j;

  initial begin
    addr_led_x[0] = 565;
    addr_led_x[1] = 542;
    addr_led_x[2] = 518;
    addr_led_x[3] = 483;
    addr_led_x[4] = 459;
    addr_led_x[5] = 436;
    addr_led_x[6] = 400;
    addr_led_x[7] = 377;
    addr_led_x[8] = 353;
    addr_led_x[9] = 317;
    addr_led_x[10] = 294;
    addr_led_x[11] = 270;
    addr_led_x[12] = 234;
    addr_led_x[13] = 211;
    addr_led_x[14] = 187;
    addr_led_x[15] = 152;
    for (j=0;j<16;j=j+1) addr_led_y[j] = 89;

    addr_sw_x[0] = 565;
    addr_sw_x[1] = 542;
    addr_sw_x[2] = 518;
    addr_sw_x[3] = 483;
    addr_sw_x[4] = 459;
    addr_sw_x[5] = 436;
    addr_sw_x[6] = 400;
    addr_sw_x[7] = 377;
    addr_sw_x[8] = 353;
    addr_sw_x[9] = 317;
    addr_sw_x[10] = 294;
    addr_sw_x[11] = 270;
    addr_sw_x[12] = 234;
    addr_sw_x[13] = 211;
    addr_sw_x[14] = 187;
    addr_sw_x[15] = 152;
    for (j=0;j<16;j=j+1) addr_sw_y[j] = 133;

    data_led_x[0] = 565;
    data_led_x[1] = 542;
    data_led_x[2] = 518;
    data_led_x[3] = 483;
    data_led_x[4] = 459;
    data_led_x[5] = 436;
    data_led_x[6] = 400;
    data_led_x[7] = 377;
    for (j=0;j<8;j=j+1) data_led_y[j] = 42;

    data_sw_x[0] = 565;
    data_sw_x[1] = 542;
    data_sw_x[2] = 518;
    data_sw_x[3] = 483;
    data_sw_x[4] = 459;
    data_sw_x[5] = 436;
    data_sw_x[6] = 400;
    data_sw_x[7] = 377;
    for (j=0;j<8;j=j+1) data_sw_y[j] = 70;

    status_led_x[0] = 294;
    status_led_x[1] = 271;
    status_led_x[2] = 248;
    status_led_x[3] = 223;
    status_led_x[4] = 200;
    status_led_x[5] = 177;
    status_led_x[6] = 154;
    status_led_x[7] = 129;
    for (j=0;j<8;j=j+1) status_led_y[j] = 42;
    other_led_x[0] = 106;
    other_led_x[1] = 83;
    other_led_x[2] = 106;
    other_led_x[3] = 83;
    other_led_y[0] = 42;
    other_led_y[1] = 42;
    other_led_y[2] = 89;
    other_led_y[3] = 89;
  end

  generate
  genvar i;
    for(i=0;i<16;i++) begin
      assign in_addr_led[i]  = (y == addr_led_y[i] || y == addr_led_y[i] - 1 || y == addr_led_y[i] + 1) &&
                               (x == addr_led_x[i] || x == addr_led_x[i] - 1 || x == addr_led_x[i] + 1);
    end
    for(i=0;i<16;i++) begin
      assign in_addr_sw[i]  = (y == addr_sw_y[i] || y == addr_sw_y[i] - 1 || y == addr_sw_y[i] + 1) &&
                              (x == addr_sw_x[i] || x == addr_sw_x[i] - 1 || x == addr_sw_x[i] + 1);
    end
    for(i=0;i<8;i++) begin
      assign in_data_led[i]  = (y == data_led_y[i] || y == data_led_y[i] - 1 || y == data_led_y[i] + 1) &&
                               (x == data_led_x[i] || x == data_led_x[i] - 1 || x == data_led_x[i] + 1);
    end
    for(i=0;i<8;i++) begin
      assign in_data_sw[i]  = (y == data_sw_y[i] || y == data_sw_y[i] - 1 || y == data_sw_y[i] + 1) &&
                              (x == data_sw_x[i] || x == data_sw_x[i] - 1 || x == data_sw_x[i] + 1);
    end
    for(i=0;i<8;i++) begin
      assign in_status_led[i]  = (y == status_led_y[i] || y == status_led_y[i] - 1 || y == status_led_y[i] + 1) &&
                               (x == status_led_x[i] || x == status_led_x[i] - 1 || x == status_led_x[i] + 1);
    end
    for(i=0;i<4;i++) begin
      assign in_other_led[i]  = (y == other_led_y[i] || y == other_led_y[i] - 1 || y == other_led_y[i] + 1) &&
                               (x == other_led_x[i] || x == other_led_x[i] - 1 || x == other_led_x[i] + 1);
    end
    for(i=0;i<16;i++) begin
      assign lit_addr_led[i]  = in_addr_led[i] && addrLEDs[i];
    end
    for(i=0;i<8;i++) begin
      assign lit_data_led[i]  = in_data_led[i] && dataLEDs[i];
    end
    for(i=0;i<8;i++) begin
      assign lit_status_led[i]  = in_status_led[i] && statusLEDs[i];
    end
    for(i=0;i<4;i++) begin
      assign lit_other_led[i]  = in_other_led[i] && otherLEDs[i];
    end
  endgenerate

  wire in_led = vga_de && (|in_addr_led || |in_data_led || |in_status_led || |in_other_led);
  wire in_sw = vga_de && (|in_addr_sw || |in_data_sw);

  wire lit_led = |lit_addr_led || |lit_data_led || |lit_status_led || |lit_other_led;

  reg [3:0] color;
  reg [23:0] pixel;
  wire [17:0] back_addr = y * 640 + x;

  img_memory #(.ADDR_WIDTH(18), .FILENAME("../roms/background.mem")) background (
    .clk(clk),
    .addr(back_addr),
    .dout(color)
  );

  palette_memory #(.ADDR_WIDTH(4), .FILENAME("../roms/background_palette.mem")) background_palette (
    .clk(clk),
    .addr(color),
    .dout(pixel)
  );

  wire in_panel = vga_de && y < 250;
  wire border = vga_de && y < 250 && (x < 2 || x > 637 || y < 2 || y > 247);

  assign vga_r = border ? 0 : in_sw ? 0 : in_led ? 8'hff : in_panel ? pixel[23:16] : 0;
  assign vga_g = border ? 0 : in_sw ? 8'hff : in_led ? (lit_led ? 8'hff : 0) : in_panel ? pixel[15:8] : 0;
  assign vga_b = border ? 8'hff : in_sw ? 0 : in_led ? (lit_led ? 8'hff : 0) : in_panel ? pixel[7:0] : 0;

endmodule

