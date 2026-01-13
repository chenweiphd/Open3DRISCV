//////////////////////////////////////////////////////////////////////////////////
// by Sparks-Richard    this is just a  start 
// my life will be full of challenges and opportunities
// I will embrace them all
// YanHao_Zhao  2025_09_09_16:13 
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
`include "define.v"

module config_registers (
    // ==================== SPEC 3.2.1 全局信号 ====================
    input  wire        clock,          // SPEC 3.2.1: 系统时钟信号
    input  wire        reset_n,        // SPEC 3.2.1: 异步复位信号（低有效）
    
    // ==================== SPEC 3.2.2 状态信号 ====================
    input  wire        busy,           // SPEC 3.2.2: 忙状态指示信号
    
    // ==================== SPEC 3.2.3 配置参数接口 ====================
    input  wire [3:0]  layout,         // SPEC 3.2.3: 矩阵布局配置 (bit0:A, bit1:B, bit2:C, bit3:D)
    input  wire        transpose_en,   // SPEC 3.2.3: 转置使能信号
    input  wire [4:0]  type_ab,        // SPEC 3.2.3: A/B矩阵数据类型
    input  wire [2:0]  type_ab_sub,    // SPEC 3.2.3: FP8子类型 (0:E5M2, 1:E4M3)
    input  wire [4:0]  type_cd,        // SPEC 3.2.3: C/D矩阵数据类型
    input  wire [3:0]  shape_m,        // SPEC 3.2.3: M维度配置 (0:4,1:8,2:16,3:32,4:64,5:128,6:256,7:512)
    input  wire [3:0]  shape_n,        // SPEC 3.2.3: N维度配置
    input  wire [3:0]  shape_k,        // SPEC 3.2.3: K维度配置
    
    // ==================== 寄存后的配置输出 ====================
    output reg  [3:0]  layout_reg,     // 寄存后的矩阵布局配置
    output reg         transpose_en_reg, // 寄存后的转置使能
    output reg  [4:0]  type_ab_reg,    // 寄存后的A/B矩阵数据类型
    output reg  [2:0]  type_ab_sub_reg, // 寄存后的FP8子类型
    output reg  [4:0]  type_cd_reg,    // 寄存后的C/D矩阵数据类型
    output reg  [3:0]  shape_m_reg,    // 寄存后的M维度配置
    output reg  [3:0]  shape_n_reg,    // 寄存后的N维度配置
    output reg  [3:0]  shape_k_reg,    // 寄存后的K维度配置
    
    // ==================== SPEC 3.2.2 状态信号 ====================
    output reg         config_valid,   // SPEC 3.2.2: 配置有效信号
    output reg         config_error    // SPEC 3.2.2: 配置错误信号
);

// ==================== 配置参数合法性检查 (SPEC 3.2.3) ====================
// 检查所有配置参数是否在支持范围内
wire config_params_valid = 
    // 检查type_ab是否支持FP4/FP8/FP16 (SPEC 1.2)
    (type_ab == `FP4 || type_ab == `FP8 || type_ab == `FP16) &&  
    // 检查type_cd是否支持FP16/FP32 (SPEC 1.2)
    (type_cd == `FP16 || type_cd == `FP32) &&                   
    // 检查所有维度配置是否在0-7范围内 (SPEC 1.3)
    (shape_m <= 4'h7) && (shape_n <= 4'h7) && (shape_k <= 4'h7); 

// ==================== 配置寄存器更新逻辑 (SPEC 3.3) ====================
always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        // ========== 复位默认值 (SPEC 3.1.1) ==========
        // 默认值选择依据架构图常见配置
        layout_reg        <= 4'b0000;      // 默认所有矩阵行优先 (架构图)
        transpose_en_reg  <= 1'b0;         // 默认禁用转置 (架构图)
        type_ab_reg       <= `FP8;        // 默认FP8 (架构图使用fp9e5m3)
        type_ab_sub_reg   <= `FP8E5M2;    // 默认E5M2 (架构图)
        type_cd_reg       <= `FP32;       // 默认FP32 (架构图)
        shape_m_reg       <= 4'h2;        // 默认M=16 (架构图)
        shape_n_reg       <= 4'h2;        // 默认N=16 (架构图)
        shape_k_reg       <= 4'h2;        // 默认K=16 (架构图)
        config_valid      <= 1'b0;        // 复位时配置无效
        config_error      <= 1'b0;        // 复位时无错误
    end 
    // SPEC 3.3: 配置只能在busy=0时更新
    else if (!busy) begin
        if (config_params_valid) begin
            // ========== 合法配置更新 ==========
            layout_reg        <= layout;
            transpose_en_reg  <= transpose_en;
            type_ab_reg       <= type_ab;
            type_ab_sub_reg   <= type_ab_sub;
            type_cd_reg       <= type_cd;
            shape_m_reg       <= shape_m;
            shape_n_reg       <= shape_n;
            shape_k_reg       <= shape_k;
            config_valid      <= 1'b1;    // SPEC 3.2.2: 配置更新成功
            config_error      <= 1'b0;    // 清除错误信号
        end else begin
            // ========== 非法配置处理 ==========
            config_error <= 1'b1;         // SPEC 3.2.2: 配置错误
            config_valid <= 1'b0;         // 配置无效
            // 注意：非法配置时不更新寄存器，保持原值 (SPEC 3.3)
        end
    end else begin
        // ========== busy=1时处理 ==========
        // SPEC 3.3: 忙时保持配置不变
        config_valid <= 1'b0;             // 忙时配置无效
        config_error <= 1'b0;             // 忙时不检查错误
    end
end

// ==================== 实时配置检查 (调试辅助) ====================
// 此部分不是SPEC要求，但有助于调试
always @(*) begin
    if (busy) begin
        // 检查在busy期间配置是否变化 (违反SPEC 3.3)
        if (layout != layout_reg || transpose_en != transpose_en_reg || 
            type_ab != type_ab_reg || type_ab_sub != type_ab_sub_reg ||
            type_cd != type_cd_reg || shape_m != shape_m_reg ||
            shape_n != shape_n_reg || shape_k != shape_k_reg) begin
            // 在仿真中可以添加警告
            // $display("Warning: Configuration changed during busy period at time %t", $time);
        end
    end
end

endmodule
