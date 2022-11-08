module mem_wb(
	input wire clk,
	input wire rst,
	
	input wire[4:0]   stall,
	
	input wire[4:0]    i_waddr,
	input wire[31:0]   i_wdata,
	
	output wire[4:0]   o_waddr,
	output wire[31:0]  o_wdata
);

reg[4:0] waddr;
reg[31:0] wdata;

assign o_waddr = waddr;
assign o_wdata = wdata;

always @(posedge clk) begin
	if (rst == 1) begin
		waddr <= 0;
		wdata <= 0;
	end else if (stall[3] == 1 && stall[4] == 0) begin
		waddr <= 0;
		wdata <= 0;
	end else if (stall[4] == 1) begin
		waddr <= waddr;
		wdata <= wdata;
	end else begin
		waddr <= i_waddr;
		wdata <= i_wdata;
	end
end

endmodule
