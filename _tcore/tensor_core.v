// Description:张量计算单元执行部分（输出接入fifo）
`timescale 1ns/1ns
`include "define.v"

module tensor_core #(
        parameter VL         = `NUM_THREAD,
        //parameter SHAPE_M      = `TC_DIM_M,
        //parameter SHAPE_K      = `TC_DIM_N,
        //parameter SHAPE_N      = `TC_DIM_K,
        parameter SHAPE_M      = 8,
        parameter SHAPE_K      = 8,
        parameter SHAPE_N      = 8,
        parameter EXPWIDTH   = 5,
        parameter PRECISION  = 4
    )(
        input                                     clk              ,
        input                                     rst_n            ,

        input   [`MATRIX_BUS_WIDTH-1:0]           s_axis_tdata_a            ,
        input   [`MATRIX_BUS_WIDTH-1:0]           s_axis_tdata_b            ,
        input   [`MATRIX_BUS_WIDTH-1:0]           s_axis_tdata_c            ,
        //input   [`NUM_THREAD-1:0]                 mask_i           ,
        input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_reg_idxw_i  ,
        input   [`DEPTH_WARP-1:0]                 ctrl_wid_i       ,
        input   [2:0]                             rm_i             ,

        // ==================== 控制与状态信号 ====================
        input                                   en,
        output                                  busy,
        output    [7:0]                         irq,
        input     [7:0]                         irq_en,

        // ==================== 参数配置接口 ====================
        input     [3:0]                         layout,
        input                                   transpose_en,
        input     [4:0]                         type_ab,
        input     [2:0]                         type_ab_sub,
        input     [4:0]                         type_cd,

        // ==================== AXI Stream与Tensore Core之间的握手信号 ====================
        input                               s_axis_tvalid_a,
        input                               s_axis_tvalid_b,
        input                               s_axis_tvalid_c,
        input                               s_axis_tlast_a,
        input                               s_axis_tlast_b,
        input                               s_axis_tlast_c,
        input                               m_axis_tready_d,

        output                              s_axis_tready_a,
        output                              s_axis_tready_b,
        output                              s_axis_tready_c,
        output                              m_axis_tvalid_d,
        output                              m_axis_tlast_d,

        //input                                     in_valid_i       ,
        //input                                     out_ready_i      ,

        //output                                    in_ready_o       ,
        //output                                    out_valid_o      ,
        
        // Align the result before writeback
        output  [`MATRIX_BUS_WIDTH*4-1:0]           wb_wvd_rd_o      ,
        output  [`NUM_THREAD-1:0]                 wvd_mask_o       ,
        output                                    wvd_o            ,
        output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] reg_idxw_o       ,
        output  [`DEPTH_WARP-1:0]                 warp_id_o
    );

    // add handshake signal of wire type

    // tensor output
    // depends on specified output data type
    wire    [`MATRIX_BUS_WIDTH-1:0]           tensor_result       ;
    wire    [`NUM_THREAD*5-1:0]               tensor_fflags       ;
    wire    [7:0]                             tensor_ctrl_reg_idxw;
    wire    [`DEPTH_WARP-1:0]                 tensor_ctrl_warpid  ;
    wire                                      tensor_in_ready     ;
    wire                                      tensor_out_valid    ;

    // result输入数据
    // todo: depends on specified output data type
    wire   [`MATRIX_BUS_WIDTH+`NUM_THREAD+1+8+`DEPTH_WARP-1:0] result_v_data_in     ;
    wire   [`MATRIX_BUS_WIDTH+`NUM_THREAD+1+8+`DEPTH_WARP-1:0] result_v_data_out    ;
    wire                                                         result_v_in_valid    ;
    wire                                                         result_v_in_ready    ;
    wire                                                         result_v_out_valid   ;
    wire                                                         result_v_out_ready   ;

    //to_fp8_con output
    wire [`MATRIX_BUS_WIDTH*`XLEN_FP9E5M3/`XLEN_FP8-1:0] fp8_a_o;
    wire [`MATRIX_BUS_WIDTH*`XLEN_FP9E5M3/`XLEN_FP8-1:0] fp8_b_o;

    // to_fp8_con control signal
    wire fp8_out_ready_i;
    wire fp8_in_ready_o;
    wire fp8_out_valid_o;

    // tensor_core input data
    wire [`MATRIX_BUS_WIDTH*`XLEN_FP9E5M3/`XLEN_FP8-1:0] a_i;
    wire [`MATRIX_BUS_WIDTH*`XLEN_FP9E5M3/`XLEN_FP8-1:0] b_i;
    wire [`MATRIX_BUS_WIDTH-1:0] c_i;

    //instantiate to_fp8_con
    to_fp8_con
        U_to_fp8_con(
            .clk 	(clk),
            .rst_n 	(rst_n),

            .type_ab 	(type_ab),
            .type_ab_sub 	(type_ab_sub),

            .a_i 	(s_axis_tvalid_a),
            .b_i 	(s_axis_tvalid_b),

            .a_o 	(fp8_a_o),
            .b_o 	(fp8_b_o),

            .in_valid_i 	(in_valid_i),
            .out_ready_i 	(fp8_out_ready_i),

            .in_ready_o 	(fp8_in_ready_o),
            .out_valid_o 	(fp8_out_valid_o)
        );

    assign a_i=fp8_a_o;
    assign b_i=fp8_b_o;
    assign c_i=in3_i;
    // todo: how to implement handshake signal? reduced-and?
        

    //例化tensor_core
    tensor_core #(
                    .VL       (VL       ),
                    .SHAPE_M    (SHAPE_M    ),
                    .SHAPE_K    (SHAPE_K    ),
                    .SHAPE_N    (SHAPE_N    ),
                    .EXPWIDTH (EXPWIDTH ),
                    .PRECISION(PRECISION)
                )
                U_tensor (
                    .clk            (clk                 ),
                    .rst_n          (rst_n               ),

                    //.op_i           ('d0                 ),
                    // .a_i            (in1_i               ),
                    // .b_i            (in2_i               ),
                    // .c_i            (in3_i               ),
                    .a_i            (a_i               ),
                    .b_i            (b_i               ),
                    .c_i            (c_i               ),
                    .rm_i           ({VL{rm_i}}          ),
                    // .rm_i           (rm_i          ),
                    .ctrl_reg_idxw_i(ctrl_reg_idxw_i     ),
                    .ctrl_warpid_i  (ctrl_wid_i          ),

                    .type_ab(type_ab),
                    .type_ab_sub(type_ab_sub),
                    .type_cd(type_ab),

                    .in_valid_i     (in_valid_i          ),
                    .out_ready_i    (result_v_in_ready   ),

                    .in_ready_o     (tensor_in_ready     ),
                    .out_valid_o    (tensor_out_valid    ),
                    // todo: result data is the output of fp22-accumulator
                    .result_o       (tensor_result       ),
                    .fflags_o       (tensor_fflags       ),
                    .ctrl_reg_idxw_o(tensor_ctrl_reg_idxw),
                    .ctrl_warpid_o  (tensor_ctrl_warpid  )
                );

    //例化fifo
    // May not need it, or substitute it with an singleportSRAM to support interleaved write
    stream_fifo_pipe_true #(.DATA_WIDTH(`MATRIX_BUS_WIDTH+`NUM_THREAD+1+8+`DEPTH_WARP),
                            .FIFO_DEPTH(1)
                           )
                          U_result_v(
                              .clk        (clk               ),
                              .rst_n      (rst_n             ),
                              .w_valid_i  (result_v_in_valid ),
                              .w_data_i   (result_v_data_in  ),
                              .r_ready_i  (result_v_out_ready),

                              .w_ready_o  (result_v_in_ready ),
                              .r_data_o   (result_v_data_out ),
                              .r_valid_o  (result_v_out_valid)
                          );

    //result_v input
    assign result_v_data_in   = {tensor_result,tensor_ctrl_warpid,tensor_ctrl_reg_idxw,tensor_out_valid,{`NUM_THREAD{1'b1}}};
    assign result_v_in_valid  = tensor_out_valid;
    assign result_v_out_ready = out_ready_i;

    assign wb_wvd_rd_o = result_v_data_out[`MATRIX_BUS_WIDTH+`NUM_THREAD+1+8+`DEPTH_WARP-1-:`MATRIX_BUS_WIDTH];
    assign warp_id_o   = result_v_data_out[`NUM_THREAD+8+`DEPTH_WARP-:`DEPTH_WARP];
    assign reg_idxw_o  = result_v_data_out[`NUM_THREAD+8-:8];
    assign wvd_o       = result_v_data_out[`NUM_THREAD];
    assign wvd_mask_o  = result_v_data_out[`NUM_THREAD-1:0];
    assign in_ready_o  = result_v_in_ready;//原为tensor_in_ready
    assign out_valid_o = result_v_out_valid;

endmodule
