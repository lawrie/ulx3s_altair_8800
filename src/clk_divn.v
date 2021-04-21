module clk_divn_even (
  input clk, 
  input reset, 
  output clk_out
);

  parameter WIDTH = 3; // Width of the register required
  parameter N = 6;      // We will divide by 12 for example in this case even number

  reg [WIDTH-1:0] r_reg;
  wire [WIDTH-1:0] r_nxt;
  reg clk_track;

  always @(posedge clk or posedge reset)

    begin
      if (reset)
        begin
          r_reg <= 0;
          clk_track <= 1'b0;
        end

      else if (r_nxt == N)
        begin
          r_reg <= 0;
          clk_track <= ~clk_track;
        end

      else 
        r_reg <= r_nxt;
    end

  assign r_nxt = r_reg + 1;   	      
  assign clk_out = clk_track;
endmodule

module clk_divn_odd (
  input clk,
  input reset, 
  output clk_out
);

  parameter WIDTH = 3;
  parameter N = 5; // odd number required

  reg [WIDTH-1:0] pos_count, neg_count;
  wire [WIDTH-1:0] r_nxt;

  always @(posedge clk)
    if (reset)
      pos_count <=0;
    else if (pos_count == N - 1) 
      pos_count <= 0;
    else 
      pos_count<= pos_count + 1;

  always @(negedge clk)
    if (reset)
      neg_count <=0;
    else  if (neg_count == N - 1) 
      neg_count <= 0;
    else 
      neg_count<= neg_count + 1; 

  assign clk_out = ((pos_count > (N>>1)) | (neg_count > (N>>1))); 
endmodule


module clk_div (
    input clk,
    input rst,
    output reg clk_div
    );
 
 parameter constantNumber = 25;
 
 reg [31:0] count;
 
  always @ (posedge(clk), posedge(rst))
  begin
    if (rst == 1'b1)
        count <= 32'b0;
    else if (count == constantNumber - 1)
        count <= 32'b0;
    else
        count <= count + 1;
  end

  always @ (posedge(clk), posedge(rst))
  begin
    if (rst == 1'b1)
        clk_div <= 1'b0;
    else if (count == constantNumber - 1)
        clk_div <= ~clk_div;
    else
        clk_div <= clk_div;
  end

endmodule
