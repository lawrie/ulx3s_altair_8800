`default_nettype none
module front_panel (
  input         clk,
  input         reset,
  output [7:0]  vga_r,
  output [7:0]  vga_b,
  output [7:0]  vga_g,
  output        vga_hs,
  output        vga_vs,
  output        vga_de
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

  reg [9:0] y = vc - VB2;

  always @(posedge clk) begin
    if (hc == HT - 1) begin
      hc <= 0;
      if (vc == VT - 1) vc <= 0;
      else vc <= vc + 1;
    end else hc <= hc + 1;
  end

  reg [3:0] color;
  reg [23:0] pixel;

  img_memory #(.ADDR_WIDTH(18), .FILENAME("../roms/background.mem")) background (
    .clk(clk),
    .addr(y * 640 + hc),
    .dout(color)
  );

  palette_memory #(.ADDR_WIDTH(4), .FILENAME("../roms/background_palette.mem")) background_palette (
    .clk(clk),
    .addr(color),
    .dout(pixel)
  );

  wire in_panel = vga_de && y < 250;

  assign vga_r = in_panel ? pixel[23:16] : 0;
  assign vga_g = in_panel ? pixel[15:8] : 0;
  assign vga_b = in_panel ? pixel[7:0] : 0;

endmodule

