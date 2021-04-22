module top
(
  input clk_25mhz,
  input ftdi_txd,
  output ftdi_rxd,
  input [6:0] btn,
  input [3:0] sw,
  inout  [27:0] gp,gn,
  output [7:0] led
);

  wire [15:0] diag16;
  wire [7:0] dataLEDs;
  wire [7:0] debugLEDs;
  reg [7:0] dir = 0;
  wire [7:0] sense;
  wire [7:0] status;

  generate
    genvar i;
    for(i = 0; i < 4; i = i+1) begin
      assign gn[17-i] = diag16[8+i];
      assign gp[17-i] = diag16[12+i];
      assign gn[24-i] = diag16[i];
      assign gp[24-i] = diag16[4+i];

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
  assign status = {interrupt_ack, n_memWR, io_stack, halt_ack, ioWR, m1, ioRD, memRD};

  always @(posedge clk_25mhz) begin
    reset_cnt <= reset_cnt + !resetn;
  end

  altair machine(
    .clk(clk_25mhz),
    .reset(~resetn),
    .rx(ftdi_txd),
    .tx(ftdi_rxd),
    .dataLEDs(dataLEDs),
    .addrLEDs(diag16),
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

endmodule
