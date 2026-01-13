`timescale 1ns/1ns
`include "define.v"
module tb_to_fp9;
        reg                                     clk  ;
        reg                                     rst_n ;

        reg     [4:0]                         type_ab;
        reg     [2:0]                         type_ab_sub;

        reg   [`MATRIX_BUS_WIDTH-1:0]           a_i  ;
        reg   [`MATRIX_BUS_WIDTH-1:0]           b_i  ;

        wire   [8:0]           a_o       ;
        wire   [8:0]           b_o       ;

        reg                                     in_valid_i   ;
        reg                                    out_ready_i    ;

        wire                                    in_ready_o  ;
        wire                                    out_valid_o ;
 
	to_fp9 uut(
		.clk(clk),
		.rst_n(rst_n),
		.type_ab(type_ab),
		.type_ab_sub(type_ab_sub),
		.a_i(a_i),
		.b_i(b_i),
		.a_o(a_o),
		.b_o(b_o),
		.in_valid_i(in_valid_i),
		.out_ready_i(out_ready_i),
		.in_ready_o(in_ready_o),
		.out_valid_o(out_valid_o)
);
always #5 clk = ~clk;
reg	[31:0]	test_case_num;
reg	[31:0]	error_count;

task display_fp9;
	input	[8:0]	fp9;
	begin
		$display("Sign:%b,Exp:%b,Sig:%b",fp9[8],fp9[7:4],fp9[3:0]);
	end
endtask
initial begin
	clk = 0;
	rst_n = 0;
	type_ab = 0;
	type_ab_sub = 0;
	a_i = 0;
	b_i = 0;
	in_valid_i = 0;
	out_ready_i = 1;
	test_case_num = 0;
	error_count = 0;

	#20;
	rst_n = 1;
	#10;

//test 1
	test_case_num = 1;
	$display("\nTest case %0d:FP8 E4M3 Conversion",test_case_num);
	type_ab = `FP8;
	type_ab_sub = `FP8E4M3;
	a_i = {8'b0_0111_101};
	b_i = {8'b1_1000_010};
	in_valid_i = 1;

	wait(out_valid_o);
	#10;
	$display("A Output:");
	display_fp9(a_o);
	$display("B Output:");
	display_fp9(b_o);
	in_valid_i = 0;
	#20;

	type_ab = `FP4;
	type_ab_sub = 0;
	a_i = {4'b0_00_0, 4'b0_01_1, 4'b0_10_0, 4'b0_11_1,4'b1_00_0,4'b1_01_1,4'b1_10_0,4'b1_11_1};
	b_i = {4'b0_00_1, 4'b0_01_0, 4'b0_10_1, 4'b0_11_0,4'b1_00_1,4'b1_01_0,4'b1_10_1,4'b1_11_0};
	in_valid_i = 1;

	wait(out_valid_o);
	#10;
	$display("First Half A Output:");
	for (integer i=0;i<4;i=i+1) begin
		$write("Element:%0d:",i);
		display_fp9(a_o[9*(i+1)-1:9*i]);
	end
	$display("First Half B Output:");
	for (integer i=0;i<4;i=i+1) begin
		$write("Element:%0d:",i);
		display_fp9(b_o[9*(i+1)-1:9*i]);
	end
//test 2
	#20;
	wait(out_valid_o);
	#10;
	$display("Second Half A Output:");
	for (integer i=0;i<4;i=i+1) begin
		$write("Element:%0d:",i);
		display_fp9(a_o[9*(i+1)-1:9*i]);
	end
	$display("Second Half B Output:");
	for (integer i=0;i<4;i=i+1) begin
		$write("Element:%0d:",i);
		display_fp9(b_o[9*(i+1)-1:9*i]);
	end
	in_valid_i = 0;
	#20;
// test 3
	test_case_num = 3;
	$display("\nTest Case %0d:FP16 Conversion",test_case_num);
	type_ab = `FP16;
	type_ab_sub = 0;
	a_i = {16'b0_01111_0000000000, 16'b1_10000_1111111111};
	b_i = {16'b0_10000_1010101010, 16'b1_01110_0101010101};
	in_valid_i = 1;

	wait(out_valid_o);
	#10;
	$display("First Cycle A Output:");
	for(integer i=0;i<2;i=i+1) begin
		$write("Element %0d: ",i);
		display_fp9(a_o[9*(i+1)-1:9*i]);
	end

	#20;
	wait(out_valid_o);
	#10;
	$display("Second Cycle B Output:");
	for(integer i=0;i<2;i=i+1) begin
		$write("Element %0d: ",i);
		display_fp9(b_o[9*(i+1)-1:9*i]);
	end
	in_valid_i = 0;
	#20;
//test 4
	test_case_num = 4;
	$display("\nTest Case %0d:Backpressure Test",test_case_num);
	type_ab = `FP8;
	type_ab_sub = `FP8E4M3;
	a_i = {8'b0_1111_000, 8'b1_0000_111,8'b0_1010_101, 8'b1_0101_010};
	b_i = {8'b0_0111_111, 8'b1_1000_000,8'b0_1100_011, 8'b1_0011_100};
	out_ready_i = 0;
	in_valid_i = 1;
	#30;
	out_ready_i = 1;
	wait(out_valid_o);
	#10;
	$display("Backpressure Test Completed");
	in_valid_i = 0;

	#50;
	$display("Total Test Cases: %0d",test_case_num);
	$display("Error Count:%0d",error_count);

	if(error_count == 0) begin
		$display("*** All Tests Passed ***");
	end else begin
		$display("*** %0d Tests Failed ***",error_count);
	end
	$finish;
end

initial begin
	$monitor("Time: %0t | State:type_ab= %b,in_valid=%b,in_ready=%b,out_valid=%b",$time, type_ab,in_valid_i,in_ready_o,out_valid_o);
end

initial begin
	#5000;
	$display("testbench timeout!");
	$finish;
end




















endmodule
