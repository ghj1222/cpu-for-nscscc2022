/*
�ļ�˵��������ģ�顣
�ڿ��ʱ������������ʱ������Ϣ��
*/
module bus(
	// ʱ�Ӻ͸�λ�ź�
	input   wire        clk,
	input   wire        rst,
	
	// ָ���ź�
	input   wire[31:0]  rom_addr, // ��ַ
	input   wire        rom_ce_n, // ʹ��
	output  reg[31:0]   rom_data, // ����������
	output  reg         rom_miss, // �Ƿ�ʧ��
	
	// �洢���ź�
	input   wire[31:0]  ram_addr,   //��ַ
	input   wire[31:0]  ram_data_w, //д������
	output  reg[31:0]   ram_data_r, //��ȡ����
	input   wire[3:0]   ram_be_n,   //�ֽ�ʹ��
	input   wire        ram_ce_n,   //�洢��ʹ��
	input   wire        ram_oe_n,   //��ʹ��
	input   wire        ram_we_n,   //дʹ��
	
	//BaseRAM�ź�
    inout  wire[31:0] base_ram_data,  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output wire[19:0] base_ram_addr, //BaseRAM��ַ
    output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire base_ram_ce_n,       //BaseRAMƬѡ������Ч
    output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����Ч
    output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����Ч��

    //ExtRAM�ź�
    inout  wire[31:0] ext_ram_data,  //ExtRAM����
    output wire[19:0] ext_ram_addr, //ExtRAM��ַ
    output wire[3:0] ext_ram_be_n,  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire ext_ram_ce_n,       //ExtRAMƬѡ������Ч
    output wire ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,       //ExtRAMдʹ�ܣ�����Ч��
	
	// ֱ�������ź�
	output  wire        txd,
	input   wire        rxd
);

parameter ClkFrequency = 25000000; // 25MHz
parameter Baud = 115200;

/*
ģ��ʱ��readΪ�첽��writeΪͬ��
rom��ram��ȡͬһƬ�洢����ram�Ķ�ȡ���������أ�rom����miss=1
miss������ˮ����ͣģ�飬miss=1ʱ����ס��ˮ�ߵ�ȡָ�����벻��
rom����ce=0 �޲�����ce=1
ram��:we=0; д:we=1��oe=0; �޲�����(we=1��oe=1)��ce=1
0x80000000-0x803FFFFF base_ram
0x80400000-0x807FFFFF ext_ram
0xBFD003F8 serial_data
0xBFD003FC serial_stat
*/

// ��������
wire rom_read  = (rom_ce_n == 0);
wire rom_nop   = (rom_ce_n == 1);
wire ram_read  = (ram_we_n == 1 && ram_oe_n == 0 && ram_ce_n == 0);
wire ram_write = (ram_we_n == 0 && ram_ce_n == 0);
wire ram_nop   = (ram_ce_n == 1 || (ram_we_n == 1 && ram_oe_n == 1));

// ����Ƭѡ
wire rom_base = (rom_nop == 0) && (rom_addr >= 32'h80000000) && (rom_addr < 32'h80400000);
wire rom_ext  = (rom_nop == 0) && (rom_addr >= 32'h80400000) && (rom_addr < 32'h80800000);
wire ram_base = (ram_nop == 0) && (ram_addr >= 32'h80000000) && (ram_addr < 32'h80400000);
wire ram_ext  = (ram_nop == 0) && (ram_addr >= 32'h80400000) && (ram_addr < 32'h80800000);
wire ram_serial_data = (ram_nop == 0) && (ram_addr == 32'hBFD003F8);
wire ram_serial_stat = (ram_nop == 0) && (ram_addr == 32'hBFD003FC);


wire rom_ban = (rom_base && ram_base) || (rom_ext && ram_ext);



// ����һ���ڵ� base оƬ�����ź�

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

// �� ext оƬ�����ź�
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





// ���ڿ���ģ��

wire rxd_data_ready; // Ϊ1�����յ�����
reg rxd_clear; // ���괮�ڸ�һ��ʱ�����ڵ�1
wire[7:0] rxd_data; // ����ֱ�Ӷ��Ĵ���

wire txd_busy; // Ϊ1�����޷���������
reg txd_start; // д����ʱ��1�����ڵ�1
reg[7:0] txd_data; // д����ʱ��1�����ڵ�����

wire[31:0] serial_stat = {30'b0, rxd_data_ready, ~txd_busy};

async_receiver #(.ClkFrequency(ClkFrequency),.Baud(Baud)) //����ģ���9600�޼���λ
    ext_uart_r(
        .clk(clk),                           //<- �ⲿʱ���ź�
        .RxD(rxd),                           //<- �ⲿ�����ź�����
        .RxD_data_ready(rxd_data_ready),     //-> ���ݽ��յ���־
        .RxD_clear(rxd_clear),               //<- ������ձ�־
        .RxD_data(rxd_data)                  //-> ���յ���һ�ֽ�����
    );

async_transmitter #(.ClkFrequency(ClkFrequency),.Baud(Baud)) //����ģ�飬9600�޼���λ
    ext_uart_t(
        .clk(clk),                      //<- �ⲿʱ���ź�
        .TxD(txd),                      //-> �����ź����
        .TxD_busy(txd_busy),            //-> ������æ״ָ̬ʾ
        .TxD_start(txd_start),          //<- ��ʼ�����ź�
        .TxD_data(txd_data)             //<- �����͵�����
    );

reg[7:0] rxd_data_out;

// rxd_clear �ڶ������ݵ���һʱ���������
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

// txd_start, txd_data ��������
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



// ���������ź� ram_data_r
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

// ����ָ���ź� rom_data �� rom_miss



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