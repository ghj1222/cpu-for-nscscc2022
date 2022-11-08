module ctrl(
	input if_stop_req,
	input id_stop_req,
	input ex_stop_req,
	input mem_stop_req,
	output reg[4:0] stall
);

always @* begin
	     if (mem_stop_req == 1) stall = 5'b01111;
	else if (ex_stop_req == 1) stall = 5'b00111;
	else if (id_stop_req == 1) stall = 5'b00011;
	else if (if_stop_req == 1) stall = 5'b00011;
	else stall = 5'b00000;
end

endmodule