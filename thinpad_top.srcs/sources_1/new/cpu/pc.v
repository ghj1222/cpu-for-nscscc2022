module pc(
	input wire clk,
	input wire rst,
	
	input wire[4:0]    stall,
	
	input wire[31:0]   jpc,
	input              jreq,
	
	
	output wire[31:0]  nxt_rom_addr,
	output wire        nxt_rom_ce_n,
	
	output reg[31:0]   pc,
	output reg         ce
);

wire[31:0] npc;
wire nce;

assign nce = (rst == 1) ? 0 : 1;
assign npc = (rst == 1) ? 0 : (ce == 0) ? 32'h80000000: (stall[0] == 1) ? pc : (jreq == 1) ? jpc : pc + 4;

assign nxt_rom_addr = npc;
assign nxt_rom_ce_n = ~nce;


always @(posedge clk) pc <= npc;
always @(posedge clk) ce <= nce;

endmodule
