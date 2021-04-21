module prg_memory(
  input clk,
  input [ADDR_WIDTH-1:0] addr,
  input [DATA_WIDTH-1:0] data_in,
  input rd,
  input we,
  output reg [DATA_WIDTH-1:0] data_out
);
  parameter integer ADDR_WIDTH = 8;
  parameter integer DATA_WIDTH = 8;
  parameter integer RAM_DATA_LEN = 8;
  
  parameter reg [DATA_WIDTH-1:0] RAM_DATA [0 : RAM_DATA_LEN-1]   = '{8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
  
  reg [DATA_WIDTH-1:0] ram[0:(2 ** ADDR_WIDTH)-1];
  
  //parameter FILENAME = "";

//  initial
//  begin
//    if (FILENAME!="")
//		  $readmemh(FILENAME, ram);
//  end
  initial
  begin
    for(int ii=0; ii<(2 ** ADDR_WIDTH)-1; ii++) begin : init_loop
      if (ii < RAM_DATA_LEN)
        ram[ii] = RAM_DATA[ii];
      else
        ram[ii] = 8'h00;
    end
  end
  
  always @(posedge clk)
  begin
    if (we)
      ram[addr] <= data_in;
    if (rd)
      data_out <= ram[addr];
  end
endmodule
