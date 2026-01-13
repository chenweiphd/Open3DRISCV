`timescale 1ns/1ps

module fadd_s1_tb;

    // 参数定义
    parameter EXPWIDTH = 5;
    parameter PRECISION = 8;
    parameter OUTPC = 4;
    
    // 输入信号
    reg [EXPWIDTH+PRECISION-1:0] a_i;
    reg [EXPWIDTH+PRECISION-1:0] b_i;
    reg [2:0] RM_i;
    reg b_inter_valid_i;
    reg b_inter_flags_is_nan_i;
    reg b_inter_flags_is_inf_i;
    reg b_inter_flags_is_inv_i;
    reg b_inter_flags_overflow_i;
    
    // 输出信号
    wire [2:0] out_rm_0;
    wire out_far_sign_0;
    wire [EXPWIDTH-1:0] out_far_exp_;
    wire [OUTPC+2:0] out_far_sig_o;
    wire out_near_sign_o;
    wire [EXPWIDTH-1:0] out_near_exp_;
    wire [OUTPC+2:0] out_near_sig_o;
    wire out_special_case_valid_o;
    wire out_special_case_iv_o;
    wire out_special_case_nan_o;
    wire out_special_case_inf_sign_0;
    wire out_small_add_o;
    wire out_far_mul_of_o;
    wire out_near_sig_is_zero_0;
    wire out_sel_far_path_o;
    
    // 实例化被测模块
    fadd_s1 #(
        .EXPWIDTH(EXPWIDTH),
        .PRECISION(PRECISION),
        .OUTPC(OUTPC)
    ) dut (
        .a_i(a_i),
        .b_i(b_i),
        .RM_i(RM_i),
        .b_inter_valid_i(b_inter_valid_i),
        .binter_flags_is_nan_i(b_inter_flags_is_nan_i),
        .b_inter_flags_is_inf_i(b_inter_flags_is_inf_i),
        .binter_flags_is_inv_i(b_inter_flags_is_inv_i),
        .binter_flags_overflow_i(b_inter_flags_overflow_i),
        .out_rm_0(out_rm_0),
        .out_far_sign_0(out_far_sign_0),
        .out_far_exp_(out_far_exp_),
        .out_far_sig_o(out_far_sig_o),
        .out_near_sign_o(out_near_sign_o),
        .out_near_exp_(out_near_exp_),
        .out_near_sig_o(out_near_sig_o),
        .out_special_case_valid_o(out_special_case_valid_o),
        .out_special_case_iv_o(out_special_case_iv_o),
        .out_special_case_nan_o(out_special_case_nan_o),
        .out_special_case_inf_sign_0(out_special_case_inf_sign_0),
        .out_small_add_o(out_small_add_o),
        .out_far_mul_of_o(out_far_mul_of_o),
        .out_near_sig_is_zero_0(out_near_sig_is_zero_0),
        .out_sel_far_path_o(out_sel_far_path_o)
    );
    
    // 任务：设置输入并等待
    task set_inputs;
        input [EXPWIDTH+PRECISION-1:0] a_val;
        input [EXPWIDTH+PRECISION-1:0] b_val;
        input [2:0] rm_val;
        begin
            a_i = a_val;
            b_i = b_val;
            RM_i = rm_val;
            #10;
        end
    endtask
    
    // 任务：测试特殊情况
    task test_special_case;
        input [EXPWIDTH+PRECISION-1:0] a_val;
        input [EXPWIDTH+PRECISION-1:0] b_val;
        input string description;
        begin
            $display("Testing %s", description);
            set_inputs(a_val, b_val, 3'b000);
            #20;
            $display("  Result: far_sign=%b, far_exp=%b, far_sig=%b", 
                     out_far_sign_0, out_far_exp_, out_far_sig_o);
            $display("  Special cases: valid=%b, nan=%b, inf=%b", 
                     out_special_case_valid_o, out_special_case_nan_o, out_special_case_inf_sign_0);
            $display("---");
        end
    endtask
    
    // 主测试过程
    initial begin
        // 初始化信号
        a_i = 0;
        b_i = 0;
        RM_i = 3'b000;  // RNE (Round to Nearest Even)
        b_inter_valid_i = 0;
        b_inter_flags_is_nan_i = 0;
        b_inter_flags_is_inf_i = 0;
        b_inter_flags_is_inv_i = 0;
        b_inter_flags_overflow_i = 0;
        
        $display("Starting fadd_s1 Testbench");
        $display("========================");
        
        // 等待初始化
        #20;
        
        // 测试1: 正常加法 (1.0 + 1.0)
        $display("Test 1: Normal Addition (1.0 + 1.0)");
        // 假设格式: 1位符号 + 5位指数 + 8位尾数
        // 1.0 = 0 01111 00000000 (指数偏移后为15，实际指数为0)
        set_inputs(14'b0_01111_00000000, 14'b0_01111_00000000, 3'b000);
        #20;
        $display("  Input A: %b", a_i);
        $display("  Input B: %b", b_i);
        $display("  Output: far_sign=%b, far_exp=%b, far_sig=%b", 
                 out_far_sign_0, out_far_exp_, out_far_sig_o);
        $display("  Near path: sign=%b, exp=%b, sig=%b", 
                 out_near_sign_o, out_near_exp_, out_near_sig_o);
        $display("  Path select: far_path=%b", out_sel_far_path_o);
        $display("---");
        
        // 测试2: 不同指数的加法 (1.0 + 2.0)
        $display("Test 2: Different Exponent Addition (1.0 + 2.0)");
        // 2.0 = 0 10000 00000000 (指数为1)
        set_inputs(14'b0_01111_00000000, 14'b0_10000_00000000, 3'b000);
        #20;
        $display("  Result: far_sign=%b, far_exp=%b, far_sig=%b", 
                 out_far_sign_0, out_far_exp_, out_far_sig_o);
        $display("---");
        
        // 测试3: 减法 (2.0 - 1.0)
        $display("Test 3: Subtraction (2.0 - 1.0)");
        set_inputs(14'b0_10000_00000000, 14'b1_01111_00000000, 3'b000);
        #20;
        $display("  Result: far_sign=%b, far_exp=%b, far_sig=%b", 
                 out_far_sign_0, out_far_exp_, out_far_sig_o);
        $display("---");
        
        // 测试4: 特殊情况 - 无穷大
        $display("Test 4: Infinity Cases");
        // +INF = 0 11111 00000000
        test_special_case(14'b0_11111_00000000, 14'b0_01111_00000000, "Positive Infinity + Normal");
        
        // 测试5: 特殊情况 - NaN
        $display("Test 5: NaN Cases");
        // NaN = 0 11111 00000001
        test_special_case(14'b0_11111_00000001, 14'b0_01111_00000000, "NaN + Normal");
        
        // 测试6: 零值运算
        $display("Test 6: Zero Operations");
        // 0 = 0 00000 00000000
        set_inputs(14'b0_00000_00000000, 14'b0_00000_00000000, 3'b000);
        #20;
        $display("  0 + 0: sign=%b, exp=%b, sig=%b, small_add=%b", 
                 out_near_sign_o, out_near_exp_, out_near_sig_o, out_small_add_o);
        $display("---");
        
        // 测试7: 不同舍入模式
        $display("Test 7: Different Rounding Modes");
        $display("  RNE (000):");
        set_inputs(14'b0_01111_10000000, 14'b0_01111_10000000, 3'b000);
        #10;
        $display("    Result sig: %b", out_near_sig_o);
        
        $display("  RTZ (001):");
        set_inputs(14'b0_01111_10000000, 14'b0_01111_10000000, 3'b001);
        #10;
        $display("    Result sig: %b", out_near_sig_o);
        $display("---");
        
        // 测试8: 远路径选择
        $display("Test 8: Far Path Selection");
        set_inputs(14'b0_10000_00000000, 14'b0_00000_00000000, 3'b000);
        #20;
        $display("  Large exp diff: sel_far_path=%b", out_sel_far_path_o);
        $display("---");
        
        // 结束测试
        $display("Testbench completed!");
        $finish;
    end
    
    // 监控输出变化
    always @(out_far_sign_0 or out_far_exp_ or out_far_sig_o) begin
        if ($time > 0) begin
            $display("Time %0t: Far path output changed - sign=%b, exp=%b, sig=%b", 
                     $time, out_far_sign_0, out_far_exp_, out_far_sig_o);
        end
    end
    
    // 波形生成 (用于仿真查看)
    initial begin
        $dumpfile("fadd_s1_tb.vcd");
        $dumpvars(0, fadd_s1_tb);
    end

endmodule

