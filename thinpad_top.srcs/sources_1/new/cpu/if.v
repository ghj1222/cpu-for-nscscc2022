module ifetch(

	// from PC
	input[31:0]     i_pc,
	input           i_ce,
	
	output[31:0]    o_pc,
	output[31:0]    o_inst,
	output          o_valid,
	
	// Inst_memory
	input[31:0]     rom_data,
	input           rom_miss,
	
	output          stop_req
);

assign o_pc = i_pc;
assign o_inst = rom_data;

assign stop_req = rom_miss;
assign o_valid = (~rom_miss) && (i_ce);

endmodule
