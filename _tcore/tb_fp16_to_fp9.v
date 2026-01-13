
module tb_fp16_to_fp9;
	reg [15:0]	fp16;
	wire [8:0]	fp9;
	wire		invalid,underflow,overflow;

	fp16_to_fp9 uut(
		.fp16(fp16),
		.fp9(fp9),
		.invalid(invalid),
		.underflow(underflow),
		.overflow(overflow)
);

	reg [15:0]	test_cases [0:9];
	reg [8:0]	expected_results [0:9];
	reg [2:0]	expected_flags [0:9];

	integer		i;
	integer		error_count;
	
	initial	begin
		initialize_test_cases();
		error_count = 0;

		for (i=0;i<10;i=i+1) begin
			fp16 = test_cases[i];
			#10;
			check_result(i);
		end
    
		$display("Test Summary:");
		$display("Total test cases:%0d",10);
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
			test_cases[0] = 16'h0000;
			expected_results[0] = 9'h000;
			expected_flags[0] = 3'b000;

			test_cases[1] = 16'h8000;
			expected_results[1] = 9'h100;
			expected_flags[1] = 3'b000;

			test_cases[2] = 16'h3C00;
			expected_results[2] = 9'h078;
			expected_flags[2] = 3'b000;

			test_cases[3] = 16'hBC00;
			expected_results[3] = 9'h178;
			expected_flags[3] = 3'b000;

			test_cases[4] = 16'h7C00;
			expected_results[4] = 9'h0F0;
			expected_flags[4] = 3'b000;

			test_cases[5] = 16'hFC00;
			expected_results[5] = 9'h1F0;
			expected_flags[5] = 3'b000;

			test_cases[6] = 16'h7FFF;
			expected_results[6] = 9'h0F1;
			expected_flags[6] = 3'b100;

			test_cases[7] = 16'h7BFF;
			expected_results[7] = 9'h0F0;
			expected_flags[7] = 3'b001;

			test_cases[8] = 16'h0001;
			expected_results[8] = 9'h000;
			expected_flags[8] = 3'b010;

			test_cases[9] = 16'h03FF;
			expected_results[9] = 9'h001;
			expected_flags[9] = 3'b000;

		end
	endtask
	
	task check_result;
		input integer test_num;
		reg pass;
		begin
			pass = 1;
			if(fp9 !== expected_results[test_num]) begin
			$display("ERROR:FP9 mismatch");
			$display("Error at time %t:[Test %d] FP9 MISMATCH!",$time,test_num);
                        $display(" -> Expected FP9: 9'h%h",expected_results[test_num]);
                        $display(" -> Actual FP9: 9'h%h",fp9);
			pass = 0;
			end

			if({invalid,underflow,overflow} !== expected_flags[test_num]) begin
			$display("%b\t%b\t\t%b\t\tERROR:Flags mismatch",$time,fp16,fp9,expected_results[test_num],invalid,underflow,overflow);
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
		$dumpfile("fp16_to_fp9.vcd");
		$dumpfile("fp16_to_fp9.fsdb");
		$dumpvars(0,tb_fp16_to_fp9);
	end

endmodule















































































		 















