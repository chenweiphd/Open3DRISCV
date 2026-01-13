
module tb_fp4_to_fp9;
	reg [7:0]	packed_fp4;
	reg		select_high;
	wire [8:0]	fp9;
	wire		invalid,underflow,overflow;
    reg [7:0]	test_cases [0:19];
	reg [8:0]	expected_results [0:19];
	reg [2:0]	expected_flags [0:19];
	reg 		expected_select[0:19];
	fp4_to_fp9 uut(
		.packed_fp4(packed_fp4),
		.fp9(fp9),
		.select_high(select_high),
		.invalid(invalid),
		.underflow(underflow),
		.overflow(overflow)
);
	

	integer		i;
	integer		error_count;
	initial	begin
		initialize_test_cases();
		error_count = 0;

		for (i=0;i<20;i=i+1) begin
			packed_fp4 = test_cases[i];
			select_high = expected_select[i];
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
			test_cases[0] = 8'h00;
			expected_select[0] = 1'b0;		
			expected_results[0] = 9'h000;
			expected_flags[0] = 3'b000;

			test_cases[1] = 8'h00;
			expected_select[1] = 1'b1;
			expected_results[1] = 9'h000;
			expected_flags[1] = 3'b000;

			test_cases[2] = 8'h80;
			expected_select[2] = 1'b1;
			expected_results[2] = 9'h100;
			expected_flags[2] = 3'b000;

			test_cases[3] = 8'h80;
			expected_select[3] = 1'b1;
			expected_results[3] = 9'h100;
			expected_flags[3] = 3'b000;

			test_cases[4] = 8'h51;
			expected_select[4] = 1'b0;
			expected_results[4] = 9'h008;
			expected_flags[4] = 3'b000;

			test_cases[5] = 8'h51;
			expected_select[5] = 1'b1;
			expected_results[5] = 9'h0F8;
			expected_flags[5] = 3'b000;

			test_cases[6] = 8'h84;
			expected_select[6] = 1'b0;
			expected_results[6] = 9'h0f8;
			expected_flags[6] = 3'b000;

			test_cases[7] = 8'h84;
			expected_select[7] = 1'b1;
			expected_results[7] = 9'h100;
			expected_flags[7] = 3'b000;

			test_cases[8] = 8'h21;
			expected_select[8] = 1'b0;
			expected_results[8] = 9'h008;
			expected_flags[8] = 3'b000;

			test_cases[9] = 8'h21;
			expected_select[9] = 1'b1;
			expected_results[9] = 9'h078;
			expected_flags[9] = 3'b000;

			test_cases[10] = 8'hE0;
			expected_select[10] = 1'b0;
			expected_results[10] = 9'h000;
			expected_flags[10] = 3'b000;

			test_cases[11] = 8'hE0;
			expected_select[11] = 1'b1;
			expected_results[11] = 9'h1f8;
			expected_flags[11] = 3'b000;

			test_cases[12] = 8'hF0;
			expected_select[12] = 1'b0;
			expected_results[12] = 9'h000;
			expected_flags[12] = 3'b000;

			test_cases[13] = 8'hF0;
			expected_select[13] = 1'b1;
			expected_results[13] = 9'h1F9;
			expected_flags[13] = 3'b100;

			test_cases[14] = 8'hF2;
			expected_select[14] = 1'b0;
			expected_results[14] = 9'h078;
			expected_flags[14] = 3'b000;

			test_cases[15] = 8'hF2;
			expected_select[15] = 1'b1;
			expected_results[15] = 9'h1F9;
			expected_flags[15] = 3'b100;

			test_cases[16] = 8'h3C;
			expected_select[16] = 1'b0;
			expected_results[16] = 9'h1f8;
			expected_flags[16] = 3'b000;

			test_cases[17] = 8'h3C;
			expected_select[17] = 1'b1;
			expected_results[17] = 9'h07c;
			expected_flags[17] = 3'b000;

			test_cases[18] = 8'hB3;
			expected_select[18] = 1'b0;
			expected_results[18] = 9'h07C;
			expected_flags[18] = 3'b000;

			test_cases[19] = 8'hA2;
			expected_select[19] = 1'b1;
			expected_results[19] = 9'h178;
			expected_flags[19] = 3'b000;
		end
	endtask
	
	task check_result;
		input integer test_num;
		reg pass;
		begin
			pass = 1;
			if(fp9 !== expected_results[test_num]) begin
                        pass = 0;
			$display("ERROR:FP9 mismatch");
                        $display("Error at time %t:[Test %d] FP9 MISMATCH!",$time,test_num);
                        $display(" -> Expected FP9: 9'h%h",expected_results[test_num]);
                        $display(" -> Actual FP9: 9'h%h",fp9);
			end

			if({invalid,underflow,overflow} !== expected_flags[test_num]) begin
			pass = 0;
			$display("ERROR:Flags mismatch");
                        $display("Error at time %t:[Test %d] FLAGS MISMATCH!",$time,test_num);
                        $display(" -> Expected Flags: 3'b%b",expected_flags[test_num]);
                      	
			end

			if(!pass) begin
			error_count = error_count + 1;
			//$display("Expected flags:%b",expected_flags[test_num]);
                        
			end else begin
			$display("PASS: [Test %d]",test_num);
			end
		end
	endtask
	
	initial begin
		$dumpfile("fp4_to_fp9.vcd");
		$fsdbDumpfile("fp4_to_fp9.fsdb");
		$fsdbDumpvars("+all",tb_fp4_to_fp9);
	end

endmodule















































































		 















