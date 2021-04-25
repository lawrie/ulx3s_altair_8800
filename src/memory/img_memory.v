module img_memory(
  input clk,
  input [ADDR_WIDTH-1:0] addr,
  output reg [3:0] dout
);

  parameter FILENAME = "";

  parameter integer ADDR_WIDTH = 8;

  reg [3:0] rom[0:(2 ** ADDR_WIDTH)-1];
  
  initial
  begin
    if (FILENAME!="")
		  $readmemh(FILENAME, rom);
  end

  always @(posedge clk)
  begin
	dout <= rom[addr];
  end
endmodule
