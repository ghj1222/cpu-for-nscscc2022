module if_id(
	input clk,
	input rst,
	
	input[4:0]    stall,
	
	input[31:0]   i_pc,
	input[31:0]   i_inst,
	input         i_valid,
	
	output[31:0]  o_pc,
	output[31:0]  o_inst,
	output        o_valid
);

reg[31:0] pc;
reg[31:0] inst;
reg       valid;

assign o_pc = pc;
assign o_inst = inst;
assign o_valid = valid;

always @(posedge clk) begin
	if (rst == 1) begin
		pc <= 0;
		inst <= 0;
		valid <= 0;
	end else if (stall[0] == 1 && stall[1] == 0) begin
		pc <= 0;
		inst <= 0;
		valid <= 0;
	end else if (stall[1] == 1) begin
		pc <= pc;
		inst <= inst;
		valid <= valid;
	end else begin
		pc <= i_pc;
		inst <= i_inst;
		valid <= i_valid;
	end
end

endmodule
