
module tb_fp32_to_fp161;
	reg [31:0]	fp32;
	wire [15:0]	fp16;
	wire		invalid,underflow,overflow;

	fp32_to_fp161 uut(
		.fp32(fp32),
		.fp16(fp16),
		.invalid(invalid),
		.underflow(underflow),
		.overflow(overflow)
);
	reg [31:0]	test_cases [0:19];
	reg [15:0]	expected_results [0:19];
	reg [2:0]	expected_flags [0:19];

	integer		i;
	integer		error_count;
	initial	begin
		initialize_test_cases();
		error_count = 0;

		for (i=0;i<20;i=i+1) begin
			fp32 = test_cases[i];
			#10;
			check_result(i);
		end
    
		$display("Test Summary:");
		$display("Total test cases:%0d",20);
		$display("Errors:%0d",error_count);

		if(error_count == 0) begin
			$display("All tests passed!");
		end else begin
			$display("Some tests failed!");
		end
		#10;
		$finish;
	end

	task initialize_test_cases;
		begin
			test_cases[0] = 32'h00000000;
			expected_results[0] = 16'h0000;
			expected_flags[0] = 3'b000;

			test_cases[1] = 32'h80000000;
			expected_results[1] = 16'h8000;
			expected_flags[1] = 3'b000;

			test_cases[2] = 32'h2F800000;
			expected_results[2] = 16'h3C00;
			expected_flags[2] = 3'b000;

			test_cases[3] = 32'hBF800000;
			expected_results[3] = 16'hBC00;
			expected_flags[3] = 3'b000;

			test_cases[4] = 32'h7F800000;
			expected_results[4] = 16'h7C00;
			expected_flags[4] = 3'b000;

			test_cases[5] = 32'hFF800000;
			expected_results[5] = 16'hFC00;
			expected_flags[5] = 3'b000;

			test_cases[6] = 32'h7FFFFFFF;
			expected_results[6] = 16'h7FFF;
			expected_flags[6] = 3'b100;

			test_cases[7] = 32'h3DCCCCCD;
			expected_results[7] = 16'h2E66;
			expected_flags[7] = 3'b000;

			test_cases[8] = 32'h7F000000;
			expected_results[8] = 16'h7C00;
			expected_flags[8] = 3'b001;

			test_cases[9] = 32'h00000001;
			expected_results[9] = 16'h0000;
			expected_flags[9] = 3'b010;

			test_cases[10] = 32'h007FFFFF;
			expected_results[10] = 16'h03FF;
			expected_flags[10] = 3'b000;

			test_cases[11] = 32'h40490FDB;
			expected_results[11] = 16'h4248;
			expected_flags[11] = 3'b000;

			test_cases[12] = 32'hC0490FDB;
			expected_results[12] = 16'hC248;
			expected_flags[12] = 3'b000;

			test_cases[13] = 32'h477FE000;
			expected_results[13] = 16'h7BFF;
			expected_flags[13] = 3'b000;

			test_cases[14] = 32'h38800000;
			expected_results[14] = 16'h0400;
			expected_flags[14] = 3'b000;

			test_cases[15] = 32'h3F802000;
			expected_results[15] = 16'h3C01;
			expected_flags[15] = 3'b000;

			test_cases[16] = 32'h477FF000;
			expected_results[16] = 16'h7C00;
			expected_flags[16] = 3'b001;

			test_cases[17] = 32'h41200000;
			expected_results[17] = 16'h4900;
			expected_flags[17] = 3'b000;

			test_cases[18] = 32'hC1200000;
			expected_results[18] = 16'hC900;
			expected_flags[18] = 3'b000;

			test_cases[19] = 32'h33FFFFFF;
			expected_results[19] = 16'h0001;
			expected_flags[19] = 3'b000;
		end
	endtask
	
	task check_result;
		input integer test_num;
		reg pass;
		begin
			pass = 1;
			if(fp16 !== expected_results[test_num]) begin
			$display("ERROR:FP16 mismatch");
			pass = 0;
			end

			if({invalid,underflow,overflow} !== expected_flags[test_num]) begin
			$display("%b\t%b\t\t%b\t\tERROR:Flags mismatch",$time,fp32,fp16,expected_results[test_num],invalid,underflow,overflow);
			pass = 0;
			end

			if(!pass) begin
			error_count = error_count + 1;
			$display("Expected flags:%b",expected_flags[test_num]);
			end else begin
			$display("PASS");
			end
		end
	endtask
	
	initial begin
		$dumpfile("fp32_to_fp161.vcd");
		$dumpvars(0,tb_fp32_to_fp161);
	end

endmodule















































































		 















