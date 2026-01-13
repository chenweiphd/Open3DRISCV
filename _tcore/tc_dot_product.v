/*
 * Copyright (c) 2023-2024 C*Core Technology Co.,Ltd,Suzhou.
 * Ventus-RTL is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
 * EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
 * MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details. */
// Author: Gu, Zihan
// Description:计算单个窗口的卷积结果,SHAPE_K需要定义为2的指数
`timescale 1ns/1ns
`include "define.v"

module tc_dot_product #(
        parameter SHAPE_K     = 8,
        parameter EXPWIDTH  = 5,
        parameter PRECISION = 4
    )(
        input                                       clk                 ,
        input                                       rst_n               ,

        input   [SHAPE_K*`XLEN_FP9E5M3-1:0]    a_i                 ,
        input   [SHAPE_K*`XLEN_FP9E5M3-1:0]    b_i                 ,
    // use max bitwidth and treat all types of c as fp16, padding zeros if actual
    //  bitwidth is smaller than fp16, i.e. fp8, fp4.
        input   [`XLEN_FP16-1:0]            c_i                 ,
        input     [4:0]                         type_ab,
        input     [2:0]                         type_ab_sub,
        input     [4:0]                         type_cd,
        input   [2:0]                               rm_i                ,
        input   [7:0]                               ctrl_reg_idxw_i     ,
        input   [`DEPTH_WARP-1:0]                   ctrl_warpid_i       ,
        // add c handshake
    // we assume that type_c is the same as type_ab.
        input                                       in_valid_i          ,
        input                                       out_ready_i         ,
        
        output                                      in_ready_o          ,
        output                                      out_valid_o         ,

        output  [`XLEN_FP8-1:0]            result_o            ,
        output  [4:0]                               fflags_o            ,
        output  [7:0]                               ctrl_reg_idxw_o     ,
        output  [`DEPTH_WARP-1:0]                   ctrl_warpid_o
    );
    //muls input
    wire    [2:0]                    mctrl_rm      ;
    wire    [`XLEN_FP16-1:0] mctrl_c       ;
    wire    [7:0]                    mctrl_reg_idxw;
    wire    [`DEPTH_WARP-1:0]        mctrl_warpid  ;
    //muls output
    wire                             muls_in_ready      [0:SHAPE_K-1];
    wire                             muls_out_valid     [0:SHAPE_K-1];
    wire                             muls_out_ready     [0:SHAPE_K-1];
    wire    [`XLEN_FP9E5M3-1:0] muls_result        [0:SHAPE_K-1];
    wire    [4:0]                    muls_fflags        [0:SHAPE_K-1];
    wire    [`XLEN_FP16-1:0] muls_ctrl_c        [0:SHAPE_K-1];
    wire    [2:0]                    muls_ctrl_rm       [0:SHAPE_K-1];
    wire    [7:0]                    muls_ctrl_reg_idxw [0:SHAPE_K-1];
    wire    [`DEPTH_WARP-1:0]        muls_ctrl_warpid   [0:SHAPE_K-1];
    //根据等比数列求和可得adds共有SHAPE_K-1个元素,假设SHAPE_K=16,则adds个数为8+4+2+1=15
    wire    [2:0]                    actrls_rm          [0:$clog2(SHAPE_K)-1];
    wire                             adds_in_ready      [0:SHAPE_K-2];
    wire                             adds_out_valid     [0:SHAPE_K-2];
    wire                             adds_out_ready     [0:SHAPE_K-2];
    wire    [`XLEN_FP9E5M3-1:0] adds_result        [0:SHAPE_K-2];
    wire    [4:0]                    adds_fflags        [0:SHAPE_K-2];
    wire    [`XLEN_FP16-1:0] adds_ctrl_c        [0:SHAPE_K-2];
    wire    [2:0]                    adds_ctrl_rm       [0:SHAPE_K-2];
    wire    [7:0]                    adds_ctrl_reg_idxw [0:SHAPE_K-2];
    wire    [`DEPTH_WARP-1:0]        adds_ctrl_warpid   [0:SHAPE_K-2];
    //finaladd输出
    wire                             finaladd_in_ready     ;
    wire                             finaladd_out_valid    ;
    wire    [`XLEN_FP22-1:0] finaladd_result       ;
    wire    [4:0]                    finaladd_fflags       ;
    wire    [`XLEN_FP16-1:0] finaladd_ctrl_c       ;
    wire    [2:0]                    finaladd_ctrl_rm      ;
    wire    [7:0]                    finaladd_ctrl_reg_idxw;
    wire    [`DEPTH_WARP-1:0]        finaladd_ctrl_warpid  ;
    // fp22_to_fp8_con outputs
    wire [`XLEN_FP8-1:0] result_fp8;
    //fifo输入数据
    // use SRAM
    // wire                                                         fifo_in_valid    ;
    // wire                                                         fifo_in_ready    ;
    // wire                                                         fifo_out_valid   ;
    // wire                                                         fifo_out_ready   ;
    // wire    [2*(EXPWIDTH+PRECISION)+16+`DEPTH_WARP-1:0]          fifo_data_in     ;
    // wire    [2*(EXPWIDTH+PRECISION)+16+`DEPTH_WARP-1:0]          fifo_data_out    ;

    wire sram_in_valid;
    wire sram_in_ready;
    wire sram_out_valid;
    wire sram_out_ready;
    wire [`XLEN_FP8+`XLEN_FP16-1:0] sram_in_data;
    // todo: bitwidth of sram_in_addr
    wire [3:0] sram_in_addr;
    wire [`XLEN_FP8+`XLEN_FP16-1:0] sram_out_data;
    wire sram_wr_en;


    assign  actrls_rm[0]   = muls_ctrl_rm[0];
    assign  mctrl_rm       = rm_i;
    assign  mctrl_c        = c_i ;
    assign  mctrl_reg_idxw = ctrl_reg_idxw_i;
    assign  mctrl_warpid   = ctrl_warpid_i  ;

    //例化SHAPE_K个tc_mul_pipe
    genvar i;
    generate
        for(i=0;i<SHAPE_K;i=i+1) begin:muls
            tc_mul_pipe #(
                            .EXPWIDTH (EXPWIDTH ),
                            .PRECISION(PRECISION),
                            .LATENCY  (2        )
                        )
                        U_tc_mul_pipe (
                            .clk            (clk                                                  ),
                            .rst_n          (rst_n                                                ),

                            //.op_i           (                                                     ),
                            .a_i            (a_i[(i+1)*(EXPWIDTH+PRECISION)-1-:EXPWIDTH+PRECISION]),
                            .b_i            (b_i[(i+1)*(EXPWIDTH+PRECISION)-1-:EXPWIDTH+PRECISION]),
                            //.c_i            (                                                     ),
                            .rm_i           (mctrl_rm                                             ),
                            .ctrl_c_i       (mctrl_c                                              ),
                            .ctrl_rm_i      (mctrl_rm                                             ),
                            .ctrl_reg_idxw_i(mctrl_reg_idxw                                       ),
                            .ctrl_warpid_i  (mctrl_warpid                                         ),

                            .in_valid_i     (in_valid_i                                           ),
                            .out_ready_i    (muls_out_ready[i]                                    ),

                            .in_ready_o     (muls_in_ready[i]                                     ),
                            .out_valid_o    (muls_out_valid[i]                                    ),

                            .result_o       (muls_result[i]                                       ),
                            .fflags_o       (muls_fflags[i]                                       ),
                            .ctrl_c_o       (muls_ctrl_c[i]                                       ),
                            .ctrl_rm_o      (muls_ctrl_rm[i]                                      ),
                            .ctrl_reg_idxw_o(muls_ctrl_reg_idxw[i]                                ),
                            .ctrl_warpid_o  (muls_ctrl_warpid[i]                                  )
                        );

        end
    endgenerate

    //将乘法结果的前半部分和后半部分对应相加并且存入add序列中的前SHAPE_K/2个位置
    genvar j;
    generate
        for(j=0;j<SHAPE_K/2;j=j+1) begin:adds
            tc_add_pipe #(
                            .EXPWIDTH (EXPWIDTH ),
                            .PRECISION(PRECISION),
                            .LATENCY  (2        )
                        )
                        U_tc_add_pipe (
                            .clk            (clk                   ),
                            .rst_n          (rst_n                 ),

                            //.op_i           (                      ),
                            .a_i            (muls_result[j]        ),
                            .b_i            (muls_result[j+SHAPE_K/2]),
                            //.c_i            (                      ),
                            .rm_i           (actrls_rm[0]          ),
                            .ctrl_c_i       (muls_ctrl_c[j]        ),
                            .ctrl_rm_i      (muls_ctrl_rm[j]       ),
                            .ctrl_reg_idxw_i(muls_ctrl_reg_idxw[j] ),
                            .ctrl_warpid_i  (muls_ctrl_warpid[j]   ),

                            .in_valid_i     (muls_out_valid[j]     ),
                            .out_ready_i    (adds_out_ready[j]     ),

                            .in_ready_o     (adds_in_ready[j]      ),
                            .out_valid_o    (adds_out_valid[j]     ),

                            .result_o       (adds_result[j]        ),
                            .fflags_o       (adds_fflags[j]        ),
                            .ctrl_c_o       (adds_ctrl_c[j]        ),
                            .ctrl_rm_o      (adds_ctrl_rm[j]       ),
                            .ctrl_reg_idxw_o(adds_ctrl_reg_idxw[j] ),
                            .ctrl_warpid_o  (adds_ctrl_warpid[j]   )
                        );

            assign muls_out_ready[j]         = adds_in_ready[j];
            assign muls_out_ready[j+SHAPE_K/2] = adds_in_ready[j];
        end
    endgenerate

    //循环相加直到剩下一个数
    genvar m,n;
    generate
        for(m=1;m<$clog2(SHAPE_K);m=m+1) begin : B1
            for(n=0;n<SHAPE_K/(1<<(m+1));n=n+1) begin : B2
                tc_add_pipe #(
                                .EXPWIDTH (EXPWIDTH ),
                                .PRECISION(PRECISION),
                                .LATENCY  (2        )
                            )
                            U_tc_add_pipe (
                                .clk            (clk                                                            ),
                                .rst_n          (rst_n                                                          ),

                                //.op_i           (                                                               ),
                                .a_i            (adds_result[((SHAPE_K*((1<<(m-1))-1))>>(m-1))+n]                 ),
                                .b_i            (adds_result[((SHAPE_K*((1<<(m-1))-1))>>(m-1))+n+SHAPE_K/(1<<(m+1))]),
                                //.c_i            (                                                               ),
                                .rm_i           (actrls_rm[m]                                                   ),
                                .ctrl_c_i       (adds_ctrl_c[((SHAPE_K*((1<<(m-1))-1))>>(m-1))+n]                 ),
                                .ctrl_rm_i      (adds_ctrl_rm[((SHAPE_K*((1<<(m-1))-1))>>(m-1))+n]                ),
                                .ctrl_reg_idxw_i(adds_ctrl_reg_idxw[((SHAPE_K*((1<<(m-1))-1))>>(m-1))+n]          ),
                                .ctrl_warpid_i  (adds_ctrl_warpid[((SHAPE_K*((1<<(m-1))-1))>>(m-1))+n]            ),

                                .in_valid_i     (adds_out_valid[((SHAPE_K*((1<<(m-1))-1))>>(m-1))+n]              ),
                                .out_ready_i    (adds_out_ready[((SHAPE_K*((1<<m)-1))>>m)+n]                      ),

                                .in_ready_o     (adds_in_ready[((SHAPE_K*((1<<m)-1))>>m)+n]                       ),
                                .out_valid_o    (adds_out_valid[((SHAPE_K*((1<<m)-1))>>m)+n]                      ),

                                .result_o       (adds_result[((SHAPE_K*((1<<m)-1))>>m)+n]                         ),
                                .fflags_o       (adds_fflags[((SHAPE_K*((1<<m)-1))>>m)+n]                         ),
                                .ctrl_c_o       (adds_ctrl_c[((SHAPE_K*((1<<m)-1))>>m)+n]                         ),
                                .ctrl_rm_o      (adds_ctrl_rm[((SHAPE_K*((1<<m)-1))>>m)+n]                        ),
                                .ctrl_reg_idxw_o(adds_ctrl_reg_idxw[((SHAPE_K*((1<<m)-1))>>m)+n]                  ),
                                .ctrl_warpid_o  (adds_ctrl_warpid[((SHAPE_K*((1<<m)-1))>>m)+n]                    )
                            );
            end
            assign actrls_rm[m] = adds_ctrl_rm[((SHAPE_K*((1<<(m-1))-1))>>(m-1))];
        end
    endgenerate

    //前一部分的out_ready_i是后一部分的in_ready_out,最后一个的out_ready是finaladd的in_ready
    genvar s,t;
    generate
        for(s=0;s<$clog2(SHAPE_K)-1;s=s+1) begin : C1
            for(t=0;t<SHAPE_K/(1<<(s+2));t=t+1) begin : C2
                assign adds_out_ready[((SHAPE_K*((1<<s)-1))>>s)+t]                  = adds_in_ready[((SHAPE_K*((1<<(s+1))-1))>>(s+1))+t];
                assign adds_out_ready[((SHAPE_K*((1<<s)-1))>>s)+t+SHAPE_K/(1<<(s+2))] = adds_in_ready[((SHAPE_K*((1<<(s+1))-1))>>(s+1))+t];
            end
        end
    endgenerate
    // add fp22 conversion logic
    
    
    assign adds_out_ready[SHAPE_K-2] = finaladd_in_ready;
    //与偏置值相加
    // The finaladd inputs are fp22 converter outputs and external c data.
    tc_add_pipe #(
                    .EXPWIDTH (8 ),
                    .PRECISION(14),
                    .LATENCY  (2        )
                )
                U_final_add (
                    .clk            (clk                        ),
                    .rst_n          (rst_n                      ),

                    //.op_i           (                           ),
                    
                    .a_i            (adds_result[SHAPE_K-2]       ),
                    .b_i            (adds_ctrl_c[SHAPE_K-2]       ),
                    //.c_i            (                           ),
                    .rm_i           (adds_ctrl_rm[SHAPE_K-2]      ),
                    .ctrl_c_i       (adds_ctrl_c[SHAPE_K-2]       ),
                    .ctrl_rm_i      (adds_ctrl_rm[SHAPE_K-2]      ),
                    .ctrl_reg_idxw_i(adds_ctrl_reg_idxw[SHAPE_K-2]),
                    .ctrl_warpid_i  (adds_ctrl_warpid[SHAPE_K-2]  ),

                    .in_valid_i     (adds_out_valid[SHAPE_K-2]    ),
                    .out_ready_i    (sram_in_ready              ),
                    //.out_ready_i    (fifo_in_ready              ),

                    .in_ready_o     (finaladd_in_ready          ),
                    .out_valid_o    (finaladd_out_valid         ),

                    .result_o       (finaladd_result            ),
                    .fflags_o       (finaladd_fflags            ),
                    .ctrl_c_o       (finaladd_ctrl_c            ),
                    .ctrl_rm_o      (finaladd_ctrl_rm           ),
                    .ctrl_reg_idxw_o(finaladd_ctrl_reg_idxw     ),
                    .ctrl_warpid_o  (finaladd_ctrl_warpid       )
                );

    //例化fifo(entries=1,pipe=true)
    // USE SRAM INSTEAD
    // stream_fifo_pipe_true #(
    //                          .DATA_WIDTH(2*(EXPWIDTH+PRECISION)+16+`DEPTH_WARP),
    //                          .FIFO_DEPTH(1)
    //                      )
    //                      U_fifo (
    //                          .clk        (clk             ),
    //                          .rst_n      (rst_n           ),
    //                          .w_valid_i  (fifo_in_valid   ),
    //                          .w_data_i   (fifo_data_in    ),
    //                          .r_ready_i  (fifo_out_ready  ),

    //                          .w_ready_o  (fifo_in_ready   ),
    //                          .r_data_o   (fifo_data_out   ),
    //                          .r_valid_o  (fifo_out_valid  )
    //                      );
    fp22_to_fp8_con U_fp22_to_fp8_con 
                (
                    .clk(clk),
                    .rst_n(clk),
                    
                    .out_type_i(type_ab),
                    
                    .data_i(finaladd_result),
                    .data_o(result_fp8),
                    // handshake
                    .in_valid_i(),
                    .out_ready_i(),
                    .in_ready_o(),
                    .out_valid_o()
                );

     // instantiate singleportSRAM
    singleportSRAM #(
                        .D_WIDTH(`XLEN_FP8+`XLEN_FP16+16+`DEPTH_WARP),
                        .A_WIDTH(4)
                    )
                U_sram (
                    .clk(clk),
                    .rst_n(rst_n),
                    .w_en_i(sram_wr_en),
                    
                    .w_valid_i  (sram_in_valid   ),
                    .w_data_i   (sram_data_in    ),
                    .r_ready_i  (sram_out_ready  ),
                                                   
                    .w_ready_o  (sram_in_ready   ),
                    .r_data_o   (sram_data_out   ),
                    .r_valid_o  (sram_out_valid  )
                );

    
    //sram input
    assign sram_data_in   = {result_fp8,finaladd_fflags,finaladd_ctrl_c,finaladd_ctrl_rm,finaladd_ctrl_reg_idxw,finaladd_ctrl_warpid};
    assign sram_in_valid  = finaladd_out_valid;
    assign sram_out_ready = out_ready_i;

    //sram output
    
    // assign result_o       = fifo_data_out[2*(EXPWIDTH+PRECISION)+16+`DEPTH_WARP-1-:EXPWIDTH+PRECISION];
    assign result_o       = sram_data_out[2*(EXPWIDTH+PRECISION)+16+`DEPTH_WARP-1-:EXPWIDTH+PRECISION];
    assign fflags_o       = sram_data_out[EXPWIDTH+PRECISION+16+`DEPTH_WARP-1-:5];
    assign ctrl_reg_idxw_o= sram_data_out[8+`DEPTH_WARP-1-:8];
    assign ctrl_warpid_o  = sram_data_out[`DEPTH_WARP-1:0];
    assign out_valid_o    = sram_out_valid;
    assign in_ready_o     = muls_in_ready[SHAPE_K-1];

endmodule





