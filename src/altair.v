module altair(
	input clk,
	input pauseModeSW,
	input stepPB,
	input reset,
	input rx,
	output tx,
	output sync,
	output interrupt_ack,
	output n_memWR,
	output io_stack,
	output halt_ack,
	output ioWR,
	output m1,
	output ioRD,
	output memRD,
	output inte_o,
	output [7:0] dataLEDs,
	output [15:0] addrLEDs,
	output [7:0] debugLEDs,
	input [7:0] dataOraddrIn,
	input [7:0] addrOrSenseIn,
	input examinePB,
	input examine_nextPB,
	input depositPB,
	input deposit_nextPB,
	input resetPB
);
	reg ce2 = 0;
	reg intr = 0;	
	reg [7:0] idata;
	wire [15:0] addr;
	wire wr_n;
	wire inta_n;
	wire [7:0] odata;

	reg [7:0] ram_in;

	reg[7:0] sysctl;
	
	assign dataLEDs = idata;
	assign addrLEDs = addr;
	assign interrupt_ack = sysctl[0];
	assign n_memWR = ~sysctl[1];
	assign io_stack = sysctl[2];
	assign halt_ack = sysctl[3];
	assign ioWR = sysctl[4];
	assign m1 = sysctl[5];
	assign ioRD = sysctl[6];
	assign memRD = sysctl[7];

	assign debugLEDs = {onestep, examine_next_en, rd_examine_next, examine_en, rd_examine, pauseModeSW, rst_n, reset};

	// Memory is sync so need one more clock to write/read
	// This slows down CPU
	always @(posedge clk) begin
		ce2 <= !ce2;
	end

	// Single-step
	reg stepkey;
	reg onestep;

        always @(posedge clk) begin
    		stepkey <= stepPB;
    		onestep <= stepkey & ~stepPB;
	end

	wire depositPB_DB;
	wire depositPB_OK = depositPB && pauseModeSW;;
	wire depositPB_DN;
	wire depositPB_UP;
	wire deposit_latch;
	wire deposit_en = deposit_latch && pauseModeSW;
	wire [7:0] deposit_in;

	wire deposit_nextPB_DB;
	wire deposit_nextPB_OK = deposit_nextPB && pauseModeSW;
	wire deposit_nextPB_DN;
	wire deposit_nextPB_UP;
	wire deposit_next_latch;
	wire deposit_next_examine_latch;
	wire deposit_next_en = deposit_latch && pauseModeSW;
	wire deposit_examine_next_en = deposit_next_examine_latch && pauseModeSW;
	wire [7:0] deposit_next_in;
	wire [7:0] deposit_next_out;
	reg  rd_deposit_examine_next;

	wire examinePB_DB;
	wire examinePB_OK = examinePB && pauseModeSW;
	wire examinePB_DN;
	wire examinePB_UP;
	wire examine_latch;
	wire examine_en = examine_latch && pauseModeSW;
	wire [7:0] examine_out;
	reg  rd_examine;

	wire examine_nextPB_DB;
	wire examine_nextPB_OK = examine_nextPB && pauseModeSW;
	wire examine_nextPB_DN;
	wire examine_nextPB_UP;
	wire examine_next_latch;
	wire examine_next_en = examine_next_latch && pauseModeSW;
	wire [7:0] examine_next_out;
	reg rd_examine_next;

	wire resetPB_DB;
	wire resetPB_OK = resetPB && pauseModeSW;
        wire resetPB_DN;
	wire resetPB_UP;
	wire reset_latch;
	wire rd_reset;
	wire [7:0] reset_out;
	wire reset_en;
	
	wire rd_sense;
	wire [7:0] sense_sw_out;

	reg  [7:0] rcnt = 8'h00;
  	wire rst_n = (rcnt == 8'hFF);

	wire [7:0] rom_out;
	wire [7:0] stack_out;
	wire [7:0] rammain_out;
	wire [7:0] boot_out;
	wire [7:0] sio_out;
	
	wire boot;
	
	reg wr_stack;
	reg wr_rammain;
	reg wr_sio;
	
	wire rd;

	reg rd_boot;
	reg rd_stack;
	reg rd_rammain;
	reg rd_rom;
	reg rd_sio;

	wire ce = onestep | (ce2 & examine_en) | (ce2 & examine_next_en) | (ce2 & !pauseModeSW);
	
	always @(*) begin
		rd_boot = 0;
		rd_stack = 0;
		rd_rammain = 0;
		rd_rom = 0;
		rd_sio = 0;
		rd_examine = 0;
		rd_examine_next = 0;
		rd_deposit_examine_next = 0;
		idata = 8'hff;		
		casex ({boot, sysctl[6], examine_en, examine_next_en, deposit_examine_next_en, addr[15:8]})
			// Deposit examine next
			{5'b00001,8'bxxxxxxxx}: begin idata = deposit_next_out; rd_deposit_examine_next = rd; end
			// Examine
			{5'b00100,8'bxxxxxxxx}: begin idata = examine_out; rd_examine = rd; end
			// Examine next
			{5'b00010,8'bxxxxxxxx}: begin idata = examine_next_out; rd_examine_next = rd; end
			// Turn-key BOOT
			{5'b10000,8'bxxxxxxxx}: begin idata = boot_out; rd_boot = rd; end       // any address
			// MEM MAP
			{5'b00000,8'b000xxxxx}: begin idata = rammain_out; rd_rammain = rd; end // 0x0000-0x1fff
			{5'b00000,8'b11111011}: begin idata = stack_out; rd_stack = rd; end     // 0xfb00-0xfbff
			{5'b00000,8'b11111101}: begin idata = rom_out; rd_rom = rd; end         // 0xfd00-0xfdff
			// I/O MAP - addr[15:8] == addr[7:0] for this section
			{5'b01000,8'b000x000x}: begin idata = sio_out; rd_sio = rd; end         // 0x00-0x01 0x10-0x11 
		endcase
	end

	always @(*) begin
		wr_stack = 0;
		wr_sio = 0;
		wr_rammain = 0;
		ram_in = odata;

		casex ({sysctl[4], deposit_en, deposit_next_en, addr[15:8]})
			// Deposit
			{3'b010,8'b000xxxxx}: begin wr_rammain = 1; ram_in = deposit_in; end
			{3'b010,8'b11111011}: begin wr_stack = 1; ram_in = deposit_in; end
			// Deposit next
			{3'b001,8'b000xxxxx}: begin wr_rammain = 1; ram_in = deposit_next_in; end
			{3'b001,8'b11111011}: begin wr_stack = 1; ram_in = deposit_next_in; end
			// MEM MAP
			{3'b000,8'b000xxxxx}: wr_rammain = ~wr_n; // 0x0000-0x1fff
			{3'b000,8'b11111011}: wr_stack = ~wr_n;   // 0xfb00-0xfbff
							          // 0xfd00-0xfdff read-only
			// I/O MAP - addr[15:8] == addr[7:0] for this section
			{3'b100,8'b000x000x}: wr_sio     = ~wr_n; // 0x00-0x01 0x10-0x11 
		endcase
	end
	
	always @(posedge clk) begin
		if (reset)
		begin
			rcnt <= 8'h00;
		end
		else
		begin
			if (sync) sysctl <= odata;
			if (rcnt != 8'hFF)
				rcnt <= rcnt + 8'h01;
		end
	end
	
	i8080 cpu(
		.clk(clk),
		.ce(ce),
		.reset(reset),
		.intr(intr),
		.idata(idata),
		.addr(addr),
		.sync(sync),
		.rd(rd),
		.wr_n(wr_n),
		.inta_n(inta_n),
		.odata(odata),
		.inte_o(inte_o)
	);
	
	jmp_boot boot_ff(
		.clk(clk),
		.reset(reset),
		.rd(rd_boot),
		.data_out(boot_out),
		.valid(boot)
	);
	
	rom_memory #(.ADDR_WIDTH(8),.FILENAME("../roms/turnmon.bin.mem")) rom(
		.clk(clk),
		.addr(addr[7:0]),
		.rd(rd_rom),
		.data_out(rom_out)
	);
	
	ram_memory #(.ADDR_WIDTH(8)) stack(
		.clk(clk),
		.addr(addr[7:0]),
		.data_in(ram_in),
		.rd(rd_stack),
		.we(wr_stack),
		.data_out(stack_out)
	);
	
	ram_memory #(.ADDR_WIDTH(13),.FILENAME("../roms/basic4k32.bin.mem")) mainmem(
		.clk(clk),
		.addr(addr[12:0]),
		.data_in(ram_in),
		.rd(rd_rammain),
		.we(wr_rammain),
		.data_out(rammain_out)
	);
	
	mc6850 sio(
		.clk(clk),
		.reset(reset),
		.addr(addr[0]),
		.data_in(odata),
		.rd(rd_sio),
		.we(wr_sio),
		.data_out(sio_out),
		.ce(ce),
		.rx(rx),
		.tx(tx));

	///////// DEPOSIT ////////////
	debounce_pb deposit_DB (
		.clk(clk),
		.i_btn(depositPB_OK),
		.o_state(depositPB_DB),
		.o_ondn(depositPB_DN),
		.o_onup(depositPB_UP)
	);

 	deposit deposit_ff (
		.clk(clk),
		.reset(~rst_n),
		.deposit(depositPB_DN),
		.data_sw(dataOraddrIn),
		.data_out(deposit_in),
		.deposit_latch(deposit_latch)
  	);

	///////// DEPOSIT NEXT ////////////
	debounce_pb deposit_next_DB (
		.clk(clk),
		.i_btn(deposit_nextPB_OK),
		.o_state(deposit_nextPB_DB),
		.o_ondn(deposit_nextPB_DN),
		.o_onup(deposit_nextPB_UP)
	);

	deposit_next deposit_next_ff (
		.clk(clk),
		.reset(~rst_n),
		.rd(rd_deposit_examine_next),
		.deposit(deposit_nextPB_DN),
		.data_sw(dataOraddrIn),
		.deposit_out(deposit_next_in),
		.deposit_latch(deposit_next_latch),
		.data_out(deposit_next_out),
		.examine_latch(deposit_next_examine_latch)
  	);

	///////// EXAMINE ////////////
	debounce_pb examine_DB (
		.clk(clk),
		.i_btn(examinePB_OK),
		.o_state(examinePB_DB),
		.o_ondn(examinePB_DN),
		.o_onup(examinePB_UP)
	);

	examine examine_ff (
		.clk(clk),
		.reset(~rst_n),
		.rd(rd_examine),
		.examine(examinePB_DN),
		.data_out(examine_out),
		.lo_addr(dataOraddrIn),
		.hi_addr(addrOrSenseIn),
		.examine_latch(examine_latch)
  	);

	///////// EXAMINE NEXT ////////////
	debounce_pb examine_next_DB (
		.clk(clk),
		.i_btn(examine_nextPB_OK),
		.o_state(examine_nextPB_DB),
		.o_ondn(examine_nextPB_DN),
		.o_onup(examine_nextPB_UP)
  	);

	examine_next examine_next_ff (
		.clk(clk),
		.reset(~rst_n),
		.rd(rd_examine_next),
		.examine(examine_nextPB_DN),
		.data_out(examine_next_out),
		.examine_latch(examine_next_latch)
	);

	///////// RESET ////////////
	debounce_pb reset_DB (
		.clk(clk),
		.i_btn(resetPB_OK),
		.o_state(resetPB_DB),
		.o_ondn(resetPB_DN),
		.o_onup(resetPB_UP)
	);
	
	reset reset_ff (
		.clk(clk),
		.reset(~rst_n),
		.rd(rd_reset),
		.reset_in(resetPB_DN),
		.data_out(reset_out),
		.reset_latch(reset_latch)
	);

	///////// SENSE SWITCHES ////////////
	sense_switch sense_sw (
		.clk(clk),
		.rd(rd_sense),
		.data_out(sense_sw_out),
		.switch_settings(addrOrSenseIn) // 0xFD for basic
	);

endmodule
