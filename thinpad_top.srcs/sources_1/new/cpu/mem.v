module mem(
	input    wire[5:0]      i_aluop,
	input    wire[31:0]     i_result,
	input    wire[31:0]     i_memaddr,
	input    wire[4:0]      i_waddr,
	output   reg [31:0]     o_wdata,
	output   wire[4:0]      o_waddr,
	output   reg            o_wunknown,
	output   reg [31:0]     o_ffdata,
	
	input    wire[31:0]     ram_data_r,
	
	output   wire           stop_req
);

assign o_waddr = i_waddr;

assign stop_req = 0;

// o_wdata
// ram_data_w
// ram_be_n
// ram_oe_n
// ram_we_n

always @* begin
	if (i_aluop[5] == 1) begin
		if (i_aluop[3] == 1) begin // sb, sw
			o_wdata = 0;
			o_wunknown = 0;
			o_ffdata = 0;
		end else begin // lb, lw
		    o_wunknown = 1;
		    o_ffdata = 0;
			if (i_aluop[1:0] == 3) begin // lw
				o_wdata = ram_data_r;
			end else begin // lb
				case (i_memaddr[1:0])
					3:       o_wdata = {{24{ram_data_r[31]}}, ram_data_r[31:24]};
					2:       o_wdata = {{24{ram_data_r[23]}}, ram_data_r[23:16]};
					1:       o_wdata = {{24{ram_data_r[15]}}, ram_data_r[15:8]};
					default: o_wdata = {{24{ram_data_r[7]}}, ram_data_r[7:0]};
				endcase
			end
		end
	end else begin
		o_wdata = i_result;
		o_ffdata = i_result;
		o_wunknown = 0;
	end
end


endmodule