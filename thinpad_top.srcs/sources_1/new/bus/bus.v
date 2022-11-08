/*
文件说明：总线模块。
在跨过时钟周期上升沿时返回信息。
*/
module bus(
	// 时钟和复位信号
	input   wire        clk,
	input   wire        rst,
	
	// 指令信号
	input   wire[31:0]  rom_addr, // 地址
	input   wire        rom_ce_n, // 使能
	output  reg[31:0]   rom_data, // 读出的数据
	output  reg         rom_miss, // 是否失败
	
	// 存储器信号
	input   wire[31:0]  ram_addr,   //地址
	input   wire[31:0]  ram_data_w, //写入数据
	output  reg[31:0]   ram_data_r, //读取数据
	input   wire[3:0]   ram_be_n,   //字节使能
	input   wire        ram_ce_n,   //存储器使能
	input   wire        ram_oe_n,   //读使能
	input   wire        ram_we_n,   //写使能
	
	//BaseRAM信号
    inout  wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共用
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效果

    //ExtRAM信号
    inout  wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效果
	
	// 直连串口信号
	output  wire        txd,
	input   wire        rxd
);

parameter ClkFrequency = 25000000; // 25MHz
parameter Baud = 115200;

/*
模块时序：read为异步，write为同步
rom和ram读取同一片存储器，ram的读取会正常返回，rom返回miss=1
miss接入流水线暂停模块，miss=1时将按住流水线的取指和译码不动
rom读：ce=0 无操作：ce=1
ram读:we=0; 写:we=1且oe=0; 无操作：(we=1且oe=1)或ce=1
0x80000000-0x803FFFFF base_ram
0x80400000-0x807FFFFF ext_ram
0xBFD003F8 serial_data
0xBFD003FC serial_stat
*/

// 解析操作
wire rom_read  = (rom_ce_n == 0);
wire rom_nop   = (rom_ce_n == 1);
wire ram_read  = (ram_we_n == 1 && ram_oe_n == 0 && ram_ce_n == 0);
wire ram_write = (ram_we_n == 0 && ram_ce_n == 0);
wire ram_nop   = (ram_ce_n == 1 || (ram_we_n == 1 && ram_oe_n == 1));

// 解析片选
wire rom_base = (rom_nop == 0) && (rom_addr >= 32'h80000000) && (rom_addr < 32'h80400000);
wire rom_ext  = (rom_nop == 0) && (rom_addr >= 32'h80400000) && (rom_addr < 32'h80800000);
wire ram_base = (ram_nop == 0) && (ram_addr >= 32'h80000000) && (ram_addr < 32'h80400000);
wire ram_ext  = (ram_nop == 0) && (ram_addr >= 32'h80400000) && (ram_addr < 32'h80800000);
wire ram_serial_data = (ram_nop == 0) && (ram_addr == 32'hBFD003F8);
wire ram_serial_stat = (ram_nop == 0) && (ram_addr == 32'hBFD003FC);


wire rom_ban = (rom_base && ram_base) || (rom_ext && ram_ext);



// 给下一周期的 base 芯片分配信号

wire[31:0] base_ram_data_r = base_ram_data;
reg[31:0] base_ram_data_w;
reg[19:0] base_ram_addr_buf;
reg[3:0]  base_ram_be_n_buf;
reg       base_ram_ce_n_buf;
reg       base_ram_oe_n_buf;
reg       base_ram_we_n_buf;

assign base_ram_data = base_ram_data_w;
assign base_ram_addr = base_ram_addr_buf;
assign base_ram_be_n = base_ram_be_n_buf;
assign base_ram_ce_n = base_ram_ce_n_buf;
assign base_ram_oe_n = base_ram_oe_n_buf;
assign base_ram_we_n = base_ram_we_n_buf;

always @(posedge clk) begin
	if (rst == 1) begin
		base_ram_ce_n_buf <= 1;
		base_ram_we_n_buf <= 1;
		base_ram_oe_n_buf <= 1;
		base_ram_be_n_buf <= 4'b0000;
		base_ram_addr_buf <= 0;
		base_ram_data_w <= 32'hzzzzzzzz;
	end else if (ram_base && ram_write) begin
		base_ram_ce_n_buf <= 0;
		base_ram_we_n_buf <= 0;
		base_ram_oe_n_buf <= 1;
		base_ram_be_n_buf <= ram_be_n;
		base_ram_addr_buf <= ram_addr[21:2];
		base_ram_data_w <= {(ram_be_n[3] ? 8'hzz : ram_data_w[31:24]),
						 (ram_be_n[2] ? 8'hzz : ram_data_w[23:16]),
						 (ram_be_n[1] ? 8'hzz : ram_data_w[15:8]),
						 (ram_be_n[0] ? 8'hzz : ram_data_w[7:0])};
	end else if (ram_base && ram_read) begin
		base_ram_ce_n_buf <= 0;
		base_ram_we_n_buf <= 1;
		base_ram_oe_n_buf <= 0;
		base_ram_be_n_buf <= ram_be_n;
		base_ram_addr_buf <= ram_addr[21:2];
		base_ram_data_w <= 32'hzzzzzzzz;
	end else if (rom_base) begin
		base_ram_ce_n_buf <= 0;
		base_ram_we_n_buf <= 1;
		base_ram_oe_n_buf <= 0;
		base_ram_be_n_buf <= 4'b0000;
		base_ram_addr_buf <= rom_addr[21:2];
		base_ram_data_w <= 32'hzzzzzzzz;
	end else begin
		base_ram_ce_n_buf <= 0;
		base_ram_we_n_buf <= 1;
		base_ram_oe_n_buf <= 1;
		base_ram_be_n_buf <= 4'b0000;
		base_ram_addr_buf <= 0;
		base_ram_data_w <= 32'hzzzzzzzz;
	end
end

// 给 ext 芯片分配信号
wire[31:0] ext_ram_data_r = ext_ram_data;
reg[31:0] ext_ram_data_w;
reg[19:0] ext_ram_addr_buf;
reg[3:0]  ext_ram_be_n_buf;
reg       ext_ram_ce_n_buf;
reg       ext_ram_oe_n_buf;
reg       ext_ram_we_n_buf;

assign ext_ram_data = ext_ram_data_w;
assign ext_ram_addr = ext_ram_addr_buf;
assign ext_ram_be_n = ext_ram_be_n_buf;
assign ext_ram_ce_n = ext_ram_ce_n_buf;
assign ext_ram_oe_n = ext_ram_oe_n_buf;
assign ext_ram_we_n = ext_ram_we_n_buf;

always @(posedge clk) begin
	if (rst == 1) begin
		ext_ram_ce_n_buf <= 1;
		ext_ram_we_n_buf <= 1;
		ext_ram_oe_n_buf <= 1;
		ext_ram_be_n_buf <= 4'b0000;
		ext_ram_addr_buf <= 0;
		ext_ram_data_w <= 32'hzzzzzzzz;
	end else if (ram_ext && ram_write) begin
		ext_ram_ce_n_buf <= 0;
		ext_ram_we_n_buf <= 0;
		ext_ram_oe_n_buf <= 1;
		ext_ram_be_n_buf <= ram_be_n;
		ext_ram_addr_buf <= ram_addr[21:2];
		ext_ram_data_w <= {(ram_be_n[3] ? 8'hzz : ram_data_w[31:24]),
						 (ram_be_n[2] ? 8'hzz : ram_data_w[23:16]),
						 (ram_be_n[1] ? 8'hzz : ram_data_w[15:8]),
						 (ram_be_n[0] ? 8'hzz : ram_data_w[7:0])};
	end else if (ram_ext && ram_read) begin
		ext_ram_ce_n_buf <= 0;
		ext_ram_we_n_buf <= 1;
		ext_ram_oe_n_buf <= 0;
		ext_ram_be_n_buf <= ram_be_n;
		ext_ram_addr_buf <= ram_addr[21:2];
		ext_ram_data_w <= 32'hzzzzzzzz;
	end else if (rom_ext) begin
		ext_ram_ce_n_buf <= 0;
		ext_ram_we_n_buf <= 1;
		ext_ram_oe_n_buf <= 0;
		ext_ram_be_n_buf <= 4'b0000;
		ext_ram_addr_buf <= rom_addr[21:2];
		ext_ram_data_w <= 32'hzzzzzzzz;
	end else begin
		ext_ram_ce_n_buf <= 0;
		ext_ram_we_n_buf <= 1;
		ext_ram_oe_n_buf <= 1;
		ext_ram_be_n_buf <= 4'b0000;
		ext_ram_addr_buf <= 0;
		ext_ram_data_w <= 32'hzzzzzzzz;
	end
end





// 串口控制模块

wire rxd_data_ready; // 为1代表收到数据
reg rxd_clear; // 读完串口给一个时钟周期的1
wire[7:0] rxd_data; // 可以直接读的串口

wire txd_busy; // 为1代表无法发送数据
reg txd_start; // 写串口时给1个周期的1
reg[7:0] txd_data; // 写串口时给1个周期的内容

wire[31:0] serial_stat = {30'b0, rxd_data_ready, ~txd_busy};

async_receiver #(.ClkFrequency(ClkFrequency),.Baud(Baud)) //接收模块＿9600无检验位
    ext_uart_r(
        .clk(clk),                           //<- 外部时钟信号
        .RxD(rxd),                           //<- 外部串行信号输入
        .RxD_data_ready(rxd_data_ready),     //-> 数据接收到标志
        .RxD_clear(rxd_clear),               //<- 清除接收标志
        .RxD_data(rxd_data)                  //-> 接收到的一字节数据
    );

async_transmitter #(.ClkFrequency(ClkFrequency),.Baud(Baud)) //发设模块，9600无检验位
    ext_uart_t(
        .clk(clk),                      //<- 外部时钟信号
        .TxD(txd),                      //-> 串行信号输出
        .TxD_busy(txd_busy),            //-> 发设器忙状态指示
        .TxD_start(txd_start),          //<- 开始发送信号
        .TxD_data(txd_data)             //<- 待发送的数据
    );

reg[7:0] rxd_data_out;

// rxd_clear 在读出数据的下一时钟申请清除
always @(posedge clk) begin
	if (rst == 1) begin
		rxd_clear <= 1; rxd_data_out <= 0;
	end else if (rxd_clear == 1) begin
		rxd_clear <= 0; rxd_data_out <= 0;
	end else if (ram_read && ram_serial_data && rxd_data_ready) begin
		rxd_clear <= 1; rxd_data_out <= rxd_data;
	end else begin
		rxd_clear <= 0; rxd_data_out <= 0;
	end
end

// txd_start, txd_data 发送数据
always @(posedge clk) begin
	if (rst == 1) begin
		txd_start <= 0; txd_data <= 0;
	end else if (txd_start == 1) begin
		txd_start <= 0; txd_data <= 0;
	end else if (ram_write && ram_serial_data && ~txd_busy) begin
		txd_start <= 1; txd_data <= ram_data_w;
	end else begin
		txd_start <= 0; txd_data <= 0;
	end
end



reg ram_read_nxt;
reg ram_base_nxt;
reg ram_ext_nxt;
reg ram_serial_data_nxt;
reg ram_serial_stat_nxt;
reg rom_read_nxt;
reg rom_base_nxt;
reg rom_ext_nxt;

always @(posedge clk) begin
	rom_miss <= rom_ban;
	ram_read_nxt <= ram_read;
	ram_base_nxt <= ram_base;
	ram_ext_nxt <= ram_ext;
	ram_serial_data_nxt <= ram_serial_data;
	ram_serial_stat_nxt <= ram_serial_stat;
	rom_read_nxt <= rom_read;
	rom_base_nxt <= rom_base;
	rom_ext_nxt <= rom_ext;
end



// 反馈数据信号 ram_data_r
always @* begin
	if (ram_read_nxt == 0) begin
		ram_data_r = 0;
	end else if (ram_base_nxt) begin
		ram_data_r = base_ram_data_r;
	end else if (ram_ext_nxt) begin
		ram_data_r = ext_ram_data_r;
	end else if (ram_serial_data_nxt) begin
		ram_data_r = rxd_data_out;
	end else if (ram_serial_stat_nxt) begin
		ram_data_r = serial_stat;
	end else begin
		ram_data_r = 0;
	end
end

// 反馈指令信号 rom_data 咿 rom_miss



always @* begin
	if (rom_read_nxt == 0) begin
		rom_data = 0;
	end else if (rom_miss) begin
		rom_data = 0;
	end else if (rom_base_nxt) begin
		rom_data = base_ram_data_r;
	end else if (rom_ext_nxt) begin
		rom_data = ext_ram_data_r;
	end else begin
		rom_data = 0;
	end
end


endmodule