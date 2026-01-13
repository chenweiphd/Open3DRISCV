`timescale 1ns / 1ps
`include "define.v"

module tb_to_fp8_con;
 localparam CLK_PERIOD = 10;
 localparam A_I_WIDTH= 512;
 localparam B_I_WIDTH= 512;
 localparam A_O_WIDTH= 36;
 localparam B_O_WIDTH= 36;
 localparam OUTPUT_BUS_WIDTH =32;

 reg        clk;
 reg        rst_n;
 reg [4:0]  type_ab;
 reg [2:0]  type_ab_sub;
 reg [A_I_WIDTH-1:0]  a_i;
 reg [B_I_WIDTH-1:0]  b_i;
 reg                  in_valid_i;
 reg                  out_ready_i;

 wire [A_O_WIDTH-1:0] a_o;
 wire [B_O_WIDTH-1:0] b_o;
 wire                 in_ready_o;
 wire                 out_valid_o;

 to_fp8_con u_dot(
    .clk         (clk),
    .rst_n       (rst_n),
    .type_ab     (type_ab),
    .type_ab_sub (type_ab_sub),
    .a_i         (a_i),
    .b_i         (b_i),
    .in_valid_i  (in_valid_i),
    .out_ready_i (out_ready_i),

    .a_o         (a_o),
    .b_o         (b_o),
    .in_ready_o  (in_ready_o),
    .out_valid_o (out_valid_o)

 );

 always #(CLK_PERIOD/2)clk = ~clk;
 initial begin
       $display("Simulation Started.");
       //initial and reset
       clk         =0;
       rst_n       =0;
       type_ab     =0;
       type_ab_sub =0;
       a_i         =0;
       b_i         =0;
       in_valid_i  =0;
       out_ready_i =0;

       #(CLK_PERIOD *5);
       rst_n   =1;
       $display("Reset Released");
                   $display("Test case 1:FP8 EM3 test");
                   run_fp8_test(5'd2,3'd1,32'h000000D5,32'h0,36'h000000155,36'h0);
                    $display("Test case 2:FP8 EM2 test");
                    run_fp8_test(5'd2,3'd0,32'h000000FF,32'h0,36'h0000001FE,36'h0);
                    $display("Test case 3:FP4 test(2 cycle output)");
                    run_fp4_task(5'd6,3'd0,32'h12345678,32'h0,36'h090603500,36'h010607040); 

                    $display("Test case 4:FP8 E4M3 test(zero)");
                    run_fp8_test(5'd2,3'd1,32'h00000000,32'h0,36'h000000000,36'h0);
                    $display("Test case 3:FP8 E5M2 test(INF)");
                    run_fp8_test(5'd2,3'd0,32'h000FC7C,32'h0,36'h0001F80F8,36'h0);
                    $display("Test case 6:FP4 test(NaN)");
                    run_fp8_test(5'd6,3'd0,32'h000000F7,32'h0,36'h0004683A,36'h0);               
                   $display("Simulation Finished.");

       $finish;
        end
       //
       task run_fp8_test;
            input [4:0]     in_type;
            input [2:0]     in_sub_type;
            input [31:0]    in_a;
            input [B_I_WIDTH-1:0] in_b;
            input [35:0]    expected_a;
            input [35:0]    expected_b;
        begin
        //1.send data
        type_ab     =in_type;
        type_ab_sub =in_sub_type;
        a_i[31:0]         =in_a;
        b_i[31:0]         =in_b;
        in_valid_i  =1;
        out_ready_i =1;
        wait (in_ready_o ==1);
        @(posedge clk);
        in_valid_i = 0;
        //2.wait result
        wait (out_valid_o == 1);
        $display("Received a_o=%h,b_o=%h",a_o,b_o);
        //3.check result
        if(a_o!=expected_a)begin
        $display("ERROR:TEST CASE FAILED!");
        $display("Input a_i was %h",a_i);
        $display("a_o mismatch!Expected %h,got %h",expected_a,a_o);
        $stop;
        end
        @(posedge clk);
        out_ready_i = 0;
    end
    endtask
    task run_fp4_task;
            input [4:0]     in_type;
            input [2:0]     in_sub_type;
            input [31:0]    in_a;
            input [B_I_WIDTH-1:0] in_b;
            input [35:0]    expected_a_part1;
            input [35:0]    expected_a_part2;
        begin
    //1.send data
        type_ab     =in_type;
        type_ab_sub =in_sub_type;
        a_i[31:0]         =in_a;
        b_i[31:0]         =in_b;
        in_valid_i  =1;
        out_ready_i =1;
        wait (in_ready_o ==1);
        @(posedge clk);
        in_valid_i  =0;
    //2.waut first pai result
        wait (out_valid_o == 1);
        $display("FP4 Received part1:a_o=%h",a_o);
        if(a_o!==expected_a_part1) begin
        $display("Error!FP4 part1 mismatch.Expected %h,got %h",expected_a_part1,a_o);
        $stop;
        end
        wait (out_valid_o == 1);
        $display("FP4 Received part2:a_o=%h",a_o);
    //wait second pai result
        @(posedge clk);
        wait (out_valid_o == 1);
        $display("FP4 Received part2:a_o=%h",a_o);
        if(a_o!==expected_a_part2)begin
        $display("Error!FP4 part2 mismatch.Expected %h,got %h",expected_a_part2,a_o);
        $stop;
        end
        @(posedge clk);
        out_ready_i = 1;
        end
        endtask
        
  
    initial begin
       $dumpfile("tb_to_fp8_con.vcd");
       $dumpvars(0,tb_to_fp8_con);
    end
endmodule


