module ex_mem(
	input clk,
	input rst,

	input[4:0]   stall,
	
	input[5:0]   i_aluop,
	input[31:0]  i_result,
	input[31:0]  i_memaddr,
	input[4:0]   i_waddr,
	
	output[5:0]   o_aluop,
	output[31:0]  o_result,
	output[31:0]  o_memaddr,
	output[4:0]   o_waddr
);


reg[5:0] aluop;
reg[31:0] result;
reg[31:0] memaddr;
reg[4:0] waddr;


assign o_aluop = aluop;
assign o_result = result;
assign o_memaddr = memaddr;
assign o_waddr = waddr;

always @(posedge clk) begin
	if (rst == 1) begin
		aluop <= 0;
		result <= 0;
		memaddr <= 0;
		waddr <= 0;
	end else if (stall[2] == 1 && stall[3] == 0) begin
		aluop <= 0;
		result <= 0;
		memaddr <= 0;
		waddr <= 0;
	end else if (stall[3] == 1) begin
		aluop <= aluop;
		result <= result;
		memaddr <= memaddr;
		waddr <= waddr;
	end else begin
		aluop <= i_aluop;
		result <= i_result;
		memaddr <= i_memaddr;
		waddr <= i_waddr;
	end
end

endmodule
