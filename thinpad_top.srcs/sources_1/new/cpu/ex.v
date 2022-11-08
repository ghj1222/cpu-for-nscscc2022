module ex(
	input   wire[5:0]    i_aluop,
	input   wire[31:0]   i_num1,
	input   wire[31:0]   i_num2,
	input   wire[31:0]   i_memaddr,
	input   wire[4:0]    i_waddr,
	output  wire[5:0]    o_aluop,
	output  reg [31:0]   o_result,
	
	output  wire[4:0]    o_waddr,
	output  wire         o_wunknown,
	output  wire         stop_req,
	
	output  wire[31:0]   o_memaddr,
	output  reg[31:0]       ram_data_w,
	output   reg [3:0]      ram_be_n,
	output   wire           ram_ce_n,
	output   reg            ram_oe_n,
	output   reg            ram_we_n
);

assign stop_req = 0;
assign o_wunknown = (i_aluop[5] == 1 && i_aluop[3] == 0);
assign o_waddr = i_waddr;
assign o_memaddr = i_memaddr;
assign o_aluop = i_aluop;

wire[31:0] mul_result = i_num1*i_num2;
reg[31:0] shift_result;

always @* begin
    case (i_aluop[1:0])
        3:       shift_result = (i_num2>>i_num1[4:0])|({32{i_num2[31]}}<<(6'd32-{1'b0,i_num1[4:0]}));
        2:		 shift_result = i_num2>>i_num1[4:0];
        default: shift_result = i_num2<<i_num1[4:0];
    endcase
end

reg[31:0] calc_result;

always @* begin
		case (i_aluop[2:0])
			7: calc_result = {i_num2, 16'b0};
			6: calc_result = i_num1 ^ i_num2;
			5: calc_result = i_num1 | i_num2;
			4: calc_result = i_num1 & i_num2;
			// 我忘了verilog的小于号是有符号还是无符号的了。
			// 如果是有符号那么下面这么写是对的：
			3: calc_result = ({1'b0,i_num1} < {1'b0,i_num2}); // SLTU
			2: calc_result = (i_num1 < i_num2); // SLT
			// 如果无符号那么就要这么写
			//3: calc_result = (i_num1 < i_num2); // SLTU
			//2: calc_result = ({i_num1[31]^1'b1,i_num1[30:0]} < {i_num2[31]^1'b1,i_num2[30:0]}); // SLT
			1: calc_result = i_num1 - i_num2;
			default: calc_result = i_num1 + i_num2;
		endcase
end

always @* begin
	if (i_aluop[5] == 1) // l, s
		o_result = i_num2;
	else if (i_aluop[4] == 1) // *
		o_result = mul_result;
	else if (i_aluop[3] == 1)
	   o_result = calc_result;
	else if (i_aluop[2] == 1) 
		o_result = shift_result;
    else begin
		o_result = i_num2;
	end
end

// mem

always @* begin
	if (i_aluop[5] == 1) begin
		if (i_aluop[3] == 1) begin // sb, sw
			if (i_aluop[1:0] == 3) begin // sw
				ram_data_w = o_result;
				ram_be_n = 0;
			end else begin // sb
				ram_data_w = {4{o_result[7:0]}};
				case (i_memaddr[1:0])
					3:       ram_be_n = 4'b0111;
					2:       ram_be_n = 4'b1011;
					1:       ram_be_n = 4'b1101;
					default: ram_be_n = 4'b1110;
				endcase
			end
			ram_oe_n = 1;
			ram_we_n = 0;
		end else begin // lb, lw
			if (i_aluop[1:0] == 3) begin // lw
			end else begin // lb
			end
			ram_data_w = 0;
			ram_be_n = 0;
			ram_oe_n = 0;
			ram_we_n = 1;
		end
	end else begin
		ram_data_w = 0;
		ram_be_n = 4'b0;
		ram_oe_n = 1;
		ram_we_n = 1;
	end
end

assign ram_ce_n = 0;


endmodule