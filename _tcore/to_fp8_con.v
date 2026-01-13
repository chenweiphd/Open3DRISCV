`timescale 1ns/1ns
`include "define.v"
module to_fp8_con(
        input                                     clk              ,
        input                                     rst_n            ,

        input     [4:0]                         type_ab,
        input     [2:0]                         type_ab_sub,

        //input   [`MATRIX_BUS_WIDTH-1:0]           a_i            ,
        //input   [`MATRIX_BUS_WIDTH-1:0]           b_i            ,
        input   [31:0]           a_i            ,
        input   [31:0]           b_i            ,
        //output   [`MATRIX_BUS_WIDTH*`FP9E5M3/`FP8-1:0]           a_o            ,
        //output   [`MATRIX_BUS_WIDTH*`FP9E5M3/`FP8-1:0]           b_o            ,
        output [35:0]                     a_o ,
        output [35:0]                     b_o,

        input                                     in_valid_i       ,
        input                                     out_ready_i      ,

        output                                    in_ready_o       ,
        output                                    out_valid_o
    );

    to_fp8_con_core a_fp8(
                        .type_ab(type_ab),
                        .type_ab_sub(type_ab_sub),
                        .in(a_i),
                        .out(a_o),
                        .in_ready_o(in_ready_o),
                        .in_valid_i(in_valid_i),
                        .out_ready_i(out_ready_i),
                        .out_valid_o(out_valid_o)

                    );
    to_fp8_con_core b_fp8(
                        .type_ab(type_ab),
                        .type_ab_sub(type_ab_sub),
                        .in(b_i),
                        .out(b_o),
                        .in_ready_o(in_ready_o),
                        .in_valid_i(in_valid_i),
                        .out_ready_i(out_ready_i),
                        .out_valid_o(out_valid_o)
                    );


endmodule
