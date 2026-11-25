`timescale 1ns/1ps


module alu_tb;

reg [7:0] a;
reg [7:0] b;
reg [1:0] op;

wire [7:0] result;
wire zflag;


alu dut(
	.a(a),
	.b(b),
	.op(op),
	.result(result),
	.zflag(zflag)
	

);

	initial begin
		 a = 8'd5;   b = 8'd3;   op = 2'b00; #10;
		 $display("ADD 5+3   = %h z=%b (expect 08 0)", result, zflag);

		 a = 8'hFF;  b = 8'h01;  op = 2'b00; #10;
		 $display("ADD FF+01 = %h z=%b (expect 00 1)", result, zflag);

		 a = 8'd9;   b = 8'd1;   op = 2'b01; #10;
		 $display("SUB 9-1   = %h z=%b (expect 08 0)", result, zflag);

		 a = 8'h00;  b = 8'h01;  op = 2'b01; #10;
		 $display("SUB 00-01 = %h z=%b (expect FF 0)", result, zflag);

		 a = 8'hAA;  b = 8'h55;  op = 2'b10; #10;
		 $display("AND AA&55 = %h z=%b (expect 00 1)", result, zflag);

		 a = 8'hAA;  b = 8'h55;  op = 2'b11; #10;
		 $display("OR  AA|55 = %h z=%b (expect FF 0)", result, zflag);

		 $stop;
	end

endmodule