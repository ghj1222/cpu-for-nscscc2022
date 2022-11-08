module regfile(
	input   wire        clk,
	input   wire        rst,
	
	// ID
	input   wire[4:0]   raddr1,
	input   wire[4:0]   raddr2,
	output  reg[31:0]   rdata1,
	output  reg[31:0]   rdata2,
	output  wire        rmiss,
	
	// WB
	input   wire[4:0]   waddr,
	input   wire[31:0]  wdata,
	
	// MEM
	input   wire[4:0]   waddr1,
	input   wire[31:0]  wdata1,
	input   wire        wunknown1,
	// EX
	input   wire[4:0]   waddr2,
	input   wire[31:0]  wdata2,
	input   wire        wunknown2
);

reg[31:0] regfile[0:31];

always @(posedge clk) begin
	if (rst == 1) begin
		regfile[0] <= 0; regfile[1] <= 0; regfile[2] <= 0; regfile[3] <= 0;
		regfile[4] <= 0; regfile[5] <= 0; regfile[6] <= 0; regfile[7] <= 0;
		regfile[8] <= 0; regfile[9] <= 0; regfile[10] <= 0; regfile[11] <= 0;
		regfile[12] <= 0; regfile[13] <= 0; regfile[14] <= 0; regfile[15] <= 0;
		regfile[16] <= 0; regfile[17] <= 0; regfile[18] <= 0; regfile[19] <= 0;
		regfile[20] <= 0; regfile[21] <= 0; regfile[22] <= 0; regfile[23] <= 0;
		regfile[24] <= 0; regfile[25] <= 0; regfile[26] <= 0; regfile[27] <= 0;
		regfile[28] <= 0; regfile[29] <= 0; regfile[30] <= 0; regfile[31] <= 0;
	end else begin
		if (waddr != 0) regfile[waddr] <= wdata;
	end
end

// rmiss
assign rmiss = (wunknown2 == 1 && waddr2 != 0 && (waddr2 == raddr1 || waddr2 == raddr2))
            || (wunknown1 == 1 && waddr1 != 0 && (waddr1 == raddr1 || waddr1 == raddr2));

// r1
always @* begin
	if (raddr1 == 0) rdata1 = 0;
	else if (raddr1 == waddr2) rdata1 = wdata2;
	else if (raddr1 == waddr1) rdata1 = wdata1;
	else if (raddr1 == waddr ) rdata1 = wdata;
	else rdata1 = regfile[raddr1];
end

// r2
always @* begin
	if (raddr2 == 0) rdata2 = 0;
	else if (raddr2 == waddr2) rdata2 = wdata2;
	else if (raddr2 == waddr1) rdata2 = wdata1;
	else if (raddr2 == waddr ) rdata2 = wdata;
	else rdata2 = regfile[raddr2];
end

endmodule
