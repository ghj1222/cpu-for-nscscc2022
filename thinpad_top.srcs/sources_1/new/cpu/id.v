module id(

	input wire[31:0]   pc,
	input wire[31:0]   inst,
	input              valid,
	
	output reg[5:0]    aluop,
	output reg[31:0]   num1,
	output reg[31:0]   num2,
	output wire[31:0]  memaddr,
	output reg[4:0]    waddr,
	
	// regfile
	output[4:0]   raddr1,
	output[4:0]   raddr2,
	input[31:0]   rdata1,
	input[31:0]   rdata2,
	input         rmiss,
	
	// PC
	output reg[31:0]  jpc,
	output reg       jreq,
	
	output        stop_req
);

`define ALU_NOP  6'b000000

`define ALU_ADD  6'b001000
`define ALU_SUB  6'b001001

`define ALU_SLT  6'b001010
`define ALU_SLTU 6'b001011
// 读寄存器
assign raddr1 = inst[25:21];
assign raddr2 = inst[20:16];
assign stop_req = rmiss;

wire[31:0] rs = rdata1;
wire[31:0] rt = rdata2;
wire[4:0] rt_addr = inst[20:16];
wire[4:0] rd_addr = inst[15:11];


// 立即数解码
wire[31:0] s_imm = {{16{inst[15]}}, inst[15:0]};
wire[31:0] z_imm = {16'b0, inst[15:0]};
wire[31:0] j_imm = {pc[31:28], inst[25:0], 2'b00};
wire[31:0]  sa   = {27'b0, inst[10:6]};

wire[31:0] npc   = pc+4+{s_imm[29:0], 2'b00};

assign memaddr = rs + s_imm;

// aluop
// num1
// num2
// waddr
// jreq
// jpc

always @* begin
	if (valid == 0) begin
		aluop = `ALU_NOP;
		num1 = 0;
		num2 = 0;
		waddr = 0;
		jreq = 0;
		jpc = 0;
	end else if (inst[31] == 1) begin // lb,lw,sb,sw
		aluop = inst[31:26];
		num1 = rs;
		num2 = rt;
		if (inst[29] == 1) waddr = 0;  // s
		else               waddr = rt_addr; // l
		jreq = 0;
		jpc = 0;
	end else if (inst[30] == 1) begin
		aluop = inst[31:26];
		num1 = rs;
		num2 = rt;
		waddr = rd_addr;
		jreq = 0;
		jpc = 0;
	end else if (inst[29] == 1) begin
		if (inst[28] == 1) begin
			aluop = inst[31:26];
			num1 = rs;
			num2 = z_imm;
			waddr = rt_addr;
			jreq = 0;
			jpc = 0;
		end else begin
			aluop = `ALU_ADD;
			num1 = rs;
			num2 = s_imm;
			waddr = rt_addr;
			jreq = 0;
			jpc = 0;
		end
	end else if (inst[28] == 1) begin
		aluop = `ALU_NOP;
		num1 = 0;
		num2 = 0;
		waddr = 0;
		jpc = npc;
		case (inst[27:26])
			3:       jreq = (rs[31] == 0 && rs != 0);//(rs > 0);
			2:       jreq = (rs[31] == 1 || rs == 0);//(rs <= 0);
			1:       jreq = (rs != rt);
			default: jreq = (rs == rt);
		endcase
	end else if (inst[27] == 1) begin
		aluop = `ALU_NOP;
		num1 = 0;
		if (inst[26] == 1) begin num2 = pc+8; waddr = 31; end
		else               begin num2 = 0;    waddr = 0;  end
		jpc = j_imm;
		jreq = 1;
	end else if (inst[26] == 1) begin
		aluop = `ALU_NOP;
		num1 = 0;
		num2 = 0;
		waddr = 0;
		jpc = npc;
		if (inst[16] == 1) jreq = (rs[31] == 0); //(rs >= 0);
		else               jreq = (rs[31] == 1); // (rs < 0);
	end else if (inst[5] == 1) begin
		if (inst[3] == 1) begin
		  if (inst[0]==1) aluop=`ALU_SLTU;
		 else     aluop = `ALU_SLT;
		      
		 end
		else if (inst[2] == 1) aluop = {4'b0011, inst[1:0]};
		else if (inst[1] == 1) aluop = `ALU_SUB;
		else                   aluop = `ALU_ADD;
		num1 = rs;
		num2 = rt;
		waddr = rd_addr;
		jpc = 0;
		jreq = 0;
	end else if (inst[3] == 1) begin
		aluop = `ALU_NOP;
		num1 = 0;
		num2 = pc+8;
		waddr = rd_addr;
		jreq = 1;
		jpc = rs;
	end else if (inst[2] == 1) begin
		aluop = inst[5:0];
		num1 = rs;
		num2 = rt;
		waddr = rd_addr;
		jreq  =0;
		jpc = 0;
	end else begin
		aluop = {4'b0001, inst[1:0]};
		num1 = sa;
		num2 = rt;
		waddr = rd_addr;
		jreq = 0;
		jpc = 0;
	end
end

endmodule