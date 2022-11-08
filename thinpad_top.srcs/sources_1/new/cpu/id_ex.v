module id_ex(
	input wire clk,
	input wire rst,
	
	input[4:0]    stall,
	
	input[5:0]   i_aluop,
	input[31:0]  i_num1,
	input[31:0]  i_num2,
	input[31:0]  i_memaddr,
	input[4:0]   i_waddr,
	
	output[5:0]   o_aluop,
	output[31:0]  o_num1,
	output[31:0]  o_num2,
	output[31:0]  o_memaddr,
	output[4:0]   o_waddr
);

reg[5:0] aluop;
reg[31:0] num1;
reg[31:0] num2;
reg[31:0] memaddr;
reg[4:0] waddr;

assign o_aluop = aluop;
assign o_num1 = num1;
assign o_num2 = num2;
assign o_memaddr = memaddr;
assign o_waddr = waddr;

always @(posedge clk) begin
	if (rst == 1) begin
		aluop <= 0;
		num1 <= 0;
		num2 <= 0;
		memaddr <= 0;
		waddr <= 0;
	end else if (stall[1] == 1 && stall[2] == 0) begin
		aluop <= 0;
		num1 <= 0;
		num2 <= 0;
		memaddr <= 0;
		waddr <= 0;
	end else if (stall[2] == 1) begin
		aluop <= aluop;
		num1 <= num1;
		num2 <= num2;
		memaddr <= memaddr;
		waddr <= waddr;
	end else begin
		aluop <= i_aluop;
		num1 <= i_num1;
		num2 <= i_num2;
		memaddr <= i_memaddr;
		waddr <= i_waddr;
	end
end

endmodule
