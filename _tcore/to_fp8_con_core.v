`timescale 1ns/1ns
`include "define.v"

module to_fp8_con_core (
        input     [4:0]  type_ab,
        input     [2:0]  type_ab_sub,

        input     [`MATRIX_BUS_WIDTH-1:0]     in,
        output     [`MATRIX_BUS_WIDTH*`FP9E5M3/`FP8-1:0] out       ,


        input                                     in_valid_i       ,
        input                                     out_ready_i      ,

        output                                    in_ready_o       ,
        output                                    out_valid_o
    );
    // 添加状态机，fp4-fp8一次转换两拍输出，
    // fp8-fp8转换输出都是一拍，
    // fp16-fp8两拍缓存一拍转换和输出

    localparam NUM_ELEM_IF_FP16 = 2;
    localparam NUM_ELEM_IF_FP8  = 4;
    localparam NUM_ELEM_IF_FP4  = 8;

    reg [`XLEN*9/4-1:0] out_temp;
    reg                 out_sign_temp;
    reg [4:0]           out_exp_temp;
    reg [2:0]           out_sig_temp;

    always @(*) begin
        out_temp       = {(`XLEN*9/4){1'b0}};
        out_sign_temp  = 1'b0;
        out_exp_temp   = 5'd0;
        out_sig_temp   = 3'd0;

        // ===== FP4 转换为 9bit 扩展格式 =====
        if (type_ab == `FP4) begin
            for (integer i = 0; i < NUM_ELEM_IF_FP4; i = i + 1) begin
                out_sign_temp = in[4*(i+1)-1];
                //out_exp_temp  = {3'd0, in[4*(i+1)-2 : 4*(i+1)-3]};   // 2-bit → zero-extend to 5-bit
                out_exp_temp  = {3'd0, in[(4*(i+1)-3)+:2]}; 
                out_sig_temp  = {in[4*i], 2'b00};                    // 1-bit → left-align, pad 2 zeros
                //out_temp[9*(i+1)-1 : 9*i] = {out_sign_temp, out_exp_temp, out_sig_temp[2:1]};
                out_temp[(9*i)+: 9] = {out_sign_temp, out_exp_temp, out_sig_temp[2:1]};
            end
        end

        // ===== FP8 E4M3 → 9bit 扩展格式 =====
        else if (type_ab == `FP8 && type_ab_sub == `FP8E4M3) begin
            for (integer i = 0; i < NUM_ELEM_IF_FP8; i = i + 1) begin
                out_sign_temp = in[8*(i+1)-1];
                out_exp_temp  = {1'b0, in[(8*(i+1)-5)+:4]};          // 4-bit exponent → zero-extend to 5-bit
                out_sig_temp  = in[8*(i+1)-6 -: 3];                  // 3-bit mantissa
                out_temp[(9*i)+: 9] = {out_sign_temp, out_exp_temp, out_sig_temp[2:1]};
            end
        end

        // ===== FP8 E5M2 → 9bit 扩展格式 =====
        else if (type_ab == `FP8 && type_ab_sub == `FP8E5M2) begin
            for (integer i = 0; i < NUM_ELEM_IF_FP8; i = i + 1) begin
                out_sign_temp = in[8*(i+1)-1];
                out_exp_temp  = in[8*(i+1)-2 -: 5];                  // 5-bit exponent

                out_sig_temp  = {in[8*(i+1)-7 -: 2], 1'b0};          // 2-bit mantissa → pad 1 LSB
                out_temp[(9*i)+: 9] = {out_sign_temp, out_exp_temp, out_sig_temp[2:1]};
            end
        end
end
endmodule






        // ===== FP16 → 截断转换为 FP8 扩展格式 =====
        //else if (type_ab == `FP16) begin
          //  for (integer i = 0; i < NUM_ELEM_IF_FP16; i = i + 1) begin
            //    out_sign_temp = in[16*(i+1)-1];
             //   out_exp_temp  = in[16*(i+1)-2 -: 5];                 // 5-bit exponent (取低位)
             //   out_sig_temp  = in[16*(i+1)-7 -: 3];                 // 3-bit mantissa（截断）
             //   out_temp[9*(i+1)-1 : 9*i] = {out_sign_temp, out_exp_temp, out_sig_temp[2:1]};
          //  end
        //end
   // end

   // assign out = out_temp;

//endmodule
