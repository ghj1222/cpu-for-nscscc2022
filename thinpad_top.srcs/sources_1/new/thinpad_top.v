`default_nettype none

module thinpad_top(
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入（备用，可不用）

    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到“ON”时为1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,         //Flash片选信号，低有效
    output wire flash_oe_n,         //Flash读使能信号，低有效
    output wire flash_we_n,         //Flash写使能信号，低有效
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
);

/* =========== Demo code begin =========== */

// PLL分频示例
wire locked, clk1, clk2;
pll_example clock_gen 
 (
  .clk_in1(clk_50M),
  .clk_out1(clk1),
  .clk_out2(clk2),
  .reset(reset_btn),
  .locked(locked)
 );

reg reset1, reset2;

always @(posedge clk1 or negedge locked) begin
    if (~locked) reset1 <= 1;
    else        reset1 <= 0;
end

always @(posedge clk2 or negedge locked) begin
    if (~locked) reset2 <= 1;
    else     reset2 <= 0;
end

parameter ClkFrequency = 60 * 1000000;
wire clk = clk1;
wire rst = reset1;


wire[31:0] rom_addr;
wire       rom_ce_n;
wire[31:0] rom_data;
wire       rom_miss;

wire[31:0] ram_addr;
wire[31:0] ram_data_w;
wire[31:0] ram_data_r;
wire[3:0]  ram_be_n;
wire       ram_ce_n;
wire       ram_oe_n;
wire       ram_we_n;

bus #(.ClkFrequency(ClkFrequency),.Baud(9600))
u_bus(
	.clk(clk),
	.rst(rst),
	.rom_addr(rom_addr),
	.rom_ce_n(rom_ce_n),
	.rom_data(rom_data),
	.rom_miss(rom_miss),
	.ram_addr(ram_addr),
	.ram_data_w(ram_data_w),
	.ram_data_r(ram_data_r),
	.ram_be_n(ram_be_n),
	.ram_ce_n(ram_ce_n),
	.ram_oe_n(ram_oe_n),
	.ram_we_n(ram_we_n),
	.base_ram_data(base_ram_data),
	.base_ram_addr(base_ram_addr),
	.base_ram_ce_n(base_ram_ce_n),
	.base_ram_oe_n(base_ram_oe_n),
	.base_ram_we_n(base_ram_we_n),
	.base_ram_be_n(base_ram_be_n),
	.ext_ram_data(ext_ram_data),
	.ext_ram_addr(ext_ram_addr),
	.ext_ram_ce_n(ext_ram_ce_n),
	.ext_ram_oe_n(ext_ram_oe_n),
	.ext_ram_we_n(ext_ram_we_n),
	.ext_ram_be_n(ext_ram_be_n),
	.txd(txd),
	.rxd(rxd)
);

cpu u_cpu(
	.clk(clk),
	.rst(rst),
	.rom_addr(rom_addr),
	.rom_ce_n(rom_ce_n),
	.rom_data(rom_data),
	.rom_miss(rom_miss),
	.ram_addr(ram_addr),
	.ram_data_w(ram_data_w),
	.ram_data_r(ram_data_r),
	.ram_be_n(ram_be_n),
	.ram_ce_n(ram_ce_n),
	.ram_oe_n(ram_oe_n),
	.ram_we_n(ram_we_n)
);

// led和数码管计时器，用于在板子打上花火

reg[31:0] counter;
reg[15:0] led_bits;
reg[3:0] num0;
reg[3:0] num1;
wire counter_end = (counter == 49999999);
wire num0_end = (num0 == 9) && counter_end;
wire num1_end = (num1 == 9) && num0_end;

assign leds = led_bits;
SEG7_LUT segL(.oSEG1(dpy0), .iDIG(num0));
SEG7_LUT segH(.oSEG1(dpy1), .iDIG(num1));

always @(posedge clk_50M or posedge reset_btn) begin
	if(reset_btn) begin
		led_bits <= 16'h1;
	end else if (counter_end) begin
		led_bits <= {led_bits[14:0],led_bits[15]};
	end
end

always @(posedge clk_50M or posedge reset_btn) begin
	if (reset_btn) begin
		counter <= 0;
	end else if (counter_end) begin
		counter <= 0;
	end else begin
		counter <= counter + 1;
	end
end


always @(posedge clk_50M or posedge reset_btn) begin
	if (reset_btn) begin
		num0 <= 0;
	end else if (num0_end) begin
		num0 <= 0;
	end else if (counter_end) begin
		num0 <= num0 + 1;
	end
end


always @(posedge clk_50M or posedge reset_btn) begin
	if (reset_btn) begin
		num1 <= 0;
	end else if (num1_end) begin
		num1 <= 0;
	end else if (num0_end) begin
		num1 <= num1 + 1;
	end
end

//图像输出演示，分辨率800x600@75Hz，像素时钟为50MHz
wire [11:0] hdata;
wire [11:0] vdata;
//assign video_red = hdata < 266 ? 3'b111 : 0; //红色竖条
//assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //绿色竖条
//assign video_blue = hdata >= 532 ? 2'b11 : 0; //蓝色竖条

assign {video_red, video_green, video_blue} = {hdata[8:5],vdata[8:5]};


assign video_clk = clk_50M;
vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    .clk(clk_50M), 
    .hdata(hdata), //横坐标
    .vdata(vdata),      //纵坐标
    .hsync(video_hsync),
    .vsync(video_vsync),
    .data_enable(video_de)
);
/* =========== Demo code end =========== */

endmodule
