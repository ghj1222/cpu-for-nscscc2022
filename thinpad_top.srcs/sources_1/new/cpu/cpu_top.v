module cpu(
	input wire clk,
	input wire rst,
	
	// 指令存储器信号
	output   wire[31:0]  rom_addr, // 地址
	output   wire        rom_ce_n, // 使能
	input   wire[31:0]   rom_data, // 读出的数据
	input   wire         rom_miss, // 是否失败
	
	// 数据存储器信号
	output   wire[31:0]  ram_addr,   //地址
	output   wire[31:0]  ram_data_w, //写入数据
	input    wire[31:0]  ram_data_r, //读取数据
	output   wire[3:0]   ram_be_n,   //字节使能
	output   wire        ram_ce_n,   //存储器使能
	output   wire        ram_oe_n,   //读使能
	output   wire        ram_we_n    //写使能
);

//---------------------STALL
wire if_stop_req;
wire id_stop_req;
wire ex_stop_req;
wire mem_stop_req;
wire[4:0] stall;
//---------------------JUMP
wire jreq;
wire[31:0] jpc;
//---------------------PC
wire[31:0]  if_i_pc;
wire        if_i_ce;
//---------------------IF
wire[31:0]  if_o_pc;
wire[31:0]  if_o_inst;
wire        if_o_valid;
//---------------------IFID
wire[31:0]  id_i_pc;
wire[31:0]  id_i_inst;
wire        id_i_valid;
//---------------------ID
wire[5:0]   id_o_aluop;
wire[31:0]  id_o_num1;
wire[31:0]  id_o_num2;
wire[31:0]  id_o_memaddr;
wire[4:0]   id_o_waddr;
//----------------------IDEX
wire[5:0]   ex_i_aluop;
wire[31:0]  ex_i_num1;
wire[31:0]  ex_i_num2;
wire[31:0]  ex_i_memaddr;
wire[4:0]   ex_i_waddr;
//----------------------EX
wire[5:0]   ex_o_aluop;
wire[31:0]  ex_o_result;
wire[31:0]  ex_o_memaddr;
wire[4:0]   ex_o_waddr;
wire        ex_o_wunknown;
//----------------------EXMEM
wire[5:0]   mem_i_aluop;
wire[31:0]  mem_i_result;
wire[31:0]  mem_i_memaddr;
wire[4:0]   mem_i_waddr;
//----------------------MEM
wire[31:0]  mem_o_wdata;
wire[4:0]   mem_o_waddr;
wire[31:0]  mem_o_ffdata;
wire        mem_o_wunknown;
//----------------------MEMWB
wire[31:0]  wb_wdata;
wire[4:0]   wb_waddr;
//----------------------IDREG
wire[4:0]   id_raddr1;
wire[4:0]   id_raddr2;
wire[31:0]  id_rdata1;
wire[31:0]  id_rdata2;
wire        id_rmiss;
//----------------------MODULES
pc u_pc(
.clk(clk),
.rst(rst),
.stall(stall),
.jreq(jreq),
.jpc(jpc),
.pc(if_i_pc),
.ce(if_i_ce),
.nxt_rom_addr(rom_addr),
.nxt_rom_ce_n(rom_ce_n)
);
ifetch u_if(
.i_pc(if_i_pc),
.i_ce(if_i_ce),
.o_pc(if_o_pc),
.o_inst(if_o_inst),
.o_valid(if_o_valid),
.rom_data(rom_data),
.rom_miss(rom_miss),
.stop_req(if_stop_req)
);

if_id u_if_id(
.clk(clk),
.rst(rst),
.stall(stall),
.i_pc(if_o_pc),
.i_inst(if_o_inst),
.i_valid(if_o_valid),
.o_pc(id_i_pc),
.o_inst(id_i_inst),
.o_valid(id_i_valid)
);

id u_id(
.pc(id_i_pc),
.inst(id_i_inst),
.valid(id_i_valid),
.aluop(id_o_aluop),
.num1(id_o_num1),
.num2(id_o_num2),
.memaddr(id_o_memaddr),
.waddr(id_o_waddr),
.raddr1(id_raddr1),
.raddr2(id_raddr2),
.rdata1(id_rdata1),
.rdata2(id_rdata2),
.rmiss(id_rmiss),
.jpc(jpc),
.jreq(jreq),
.stop_req(id_stop_req)
);

id_ex u_id_ex(
.clk(clk),
.rst(rst),
.stall(stall),
.i_aluop(id_o_aluop),
.i_num1(id_o_num1),
.i_num2(id_o_num2),
.i_memaddr(id_o_memaddr),
.i_waddr(id_o_waddr),
.o_aluop(ex_i_aluop),
.o_num1(ex_i_num1),
.o_num2(ex_i_num2),
.o_memaddr(ex_i_memaddr),
.o_waddr(ex_i_waddr)
);

ex u_ex(
.i_aluop(ex_i_aluop),
.i_num1(ex_i_num1),
.i_num2(ex_i_num2),
.i_memaddr(ex_i_memaddr),
.i_waddr(ex_i_waddr),
.o_aluop(ex_o_aluop),
.o_result(ex_o_result),
.o_memaddr(ex_o_memaddr),
.o_waddr(ex_o_waddr),
.o_wunknown(ex_o_wunknown),
.stop_req(ex_stop_req),

.ram_data_w(ram_data_w),
.ram_be_n(ram_be_n),
.ram_ce_n(ram_ce_n),
.ram_oe_n(ram_oe_n),
.ram_we_n(ram_we_n)
);

assign ram_addr = ex_o_memaddr;

ex_mem u_ex_mem(
.clk(clk),
.rst(rst),
.stall(stall),
.i_aluop(ex_o_aluop),
.i_result(ex_o_result),
.i_memaddr(ex_o_memaddr),
.i_waddr(ex_o_waddr),
.o_aluop(mem_i_aluop),
.o_result(mem_i_result),
.o_memaddr(mem_i_memaddr),
.o_waddr(mem_i_waddr)
);

mem u_mem(
.i_aluop(mem_i_aluop),
.i_result(mem_i_result),
.i_memaddr(mem_i_memaddr),
.i_waddr(mem_i_waddr),
.o_wdata(mem_o_wdata),
.o_waddr(mem_o_waddr),
.o_wunknown(mem_o_wunknown),
.o_ffdata(mem_o_ffdata),
.ram_data_r(ram_data_r),

.stop_req(mem_stop_req)
);

mem_wb u_mem_wb(
.clk(clk),
.rst(rst),
.stall(stall),
.i_wdata(mem_o_wdata),
.i_waddr(mem_o_waddr),
.o_wdata(wb_wdata),
.o_waddr(wb_waddr)
);

regfile u_regfile(
.clk(clk),
.rst(rst),
.raddr1(id_raddr1),
.raddr2(id_raddr2),
.rdata1(id_rdata1),
.rdata2(id_rdata2),
.rmiss(id_rmiss),
.wdata(wb_wdata),
.waddr(wb_waddr),
.waddr1(mem_o_waddr),
.wdata1(mem_o_ffdata),
.wunknown1(mem_o_wunknown),
.waddr2(ex_o_waddr),
.wdata2(ex_o_result),
.wunknown2(ex_o_wunknown)
);

ctrl u_ctrl(
.if_stop_req(if_stop_req),
.id_stop_req(id_stop_req),
.ex_stop_req(ex_stop_req),
.mem_stop_req(mem_stop_req),
.stall(stall)
);


endmodule