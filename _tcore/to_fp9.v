`timescale 1ns/1ns
`include "define.v"
module to_fp9(
        input                                     clk              ,
        input                                     rst_n            ,

        input     [4:0]                         type_ab,
        input     [2:0]                         type_ab_sub,

        input   [`MATRIX_BUS_WIDTH-1:0]           a_i            ,
        input   [`MATRIX_BUS_WIDTH-1:0]           b_i            ,

        output   reg[8:0]           a_o            ,
        output   reg[8:0]           b_o            ,

        input                                     in_valid_i       ,
        input                                     out_ready_i      ,

        output        reg                         in_ready_o       ,
        output        reg                         out_valid_o
    );

localparam IDLE = 2'b00;
localparam PROCESS = 2'b01;
localparam OUTPUT = 2'b10;

	reg[1:0]	state;
	reg[1:0]	next_state;

	reg[`MATRIX_BUS_WIDTH-1:0]	a_reg;
	reg[`MATRIX_BUS_WIDTH-1:0]	b_reg;
	reg[4:0]			type_ab_reg;
	reg[2:0]			type_ab_sub_reg;

	reg		fp4_second_half;
	
	reg		fp16_second_cycle;
	localparam	ELEM_WIDTH = 9;

	wire[8:0]	fp4_to_fp9_result_a;
	wire[8:0]	fp4_to_fp9_result_b;
    	wire	fp4_invalid_a, fp4_underflow_a, fp4_overflow_a;

	wire[8:0]	fp16_to_fp9_result_a;
	wire[8:0]	fp16_to_fp9_result_b;
	wire	fp16_invalid_a, fp16_underflow_a, fp16_overflow_a;
	

	fp4_to_fp9 fp4_converter_a(
		.packed_fp4(a_reg[7:0]),
		.select_high(fp4_second_half),
		.fp9(fp4_to_fp9_result_a),
		.invalid(fp4_invalid_a),
		.underflow(fp4_underflow_a),
		.overflow(fp4_overflow_a)
);

	fp4_to_fp9 fp4_converter_b(
		.packed_fp4(b_reg[7:0]),
		.select_high(fp4_second_half),
		.fp9(fp4_to_fp9_result_b),
		.invalid(),
		.underflow(),
		.overflow()
);

	fp16_to_fp9 fp16_converter_a(
		.fp16(a_reg[15:0]),
		.fp9(fp16_to_fp9_result_a),
		.invalid(fp16_invalid_a),
		.underflow(fp16_underflow_a),
		.overflow(fp16_overflow_a)
);

	fp16_to_fp9 fp16_converter_b(
		.fp16(b_reg[15:0]),
		.fp9(fp16_to_fp9_result_b),
		.invalid(),
		.underflow(),
		.overflow()
);

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		state <= IDLE;
	end else begin
		state <= next_state;
	end
end

always @(*) begin
	next_state = state;
	case (state)
		IDLE:begin
			if(in_valid_i && in_ready_o) begin
			  next_state = PROCESS;
			end
		end
		PROCESS:begin
			next_state = OUTPUT;
		end
		OUTPUT:begin
			if (out_ready_i) begin
			  next_state = IDLE;
			end
		end
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		in_ready_o <= 1'b1;
		out_valid_o <= 1'b0;
		a_reg <= {`MATRIX_BUS_WIDTH{1'b0}};
		b_reg <= {`MATRIX_BUS_WIDTH{1'b0}};
		type_ab_reg <= 5'b0;
		type_ab_sub_reg <= 3'b0;
		fp4_second_half <= 1'b0;
		fp16_second_cycle <= 1'b0;
		a_o <= 9'b0;
		b_o <= 9'b0;
	end else begin
		case(state)
			IDLE:begin
				out_valid_o <= 1'b0;
				fp4_second_half <= 1'b0;
				fp16_second_cycle <= 1'b0;
				if(in_valid_i && in_ready_o) begin
				  a_reg <= a_i;
				  b_reg <= b_i;
				  type_ab_reg <= type_ab;
				  type_ab_sub_reg <= type_ab_sub;
				  in_ready_o <= 1'b0;
				end
			end
			PROCESS:begin
			  case(type_ab_reg)
				`FP4:begin
					if(!fp4_second_half)begin
					  a_o <= fp4_to_fp9_result_a;
					  b_o <= fp4_to_fp9_result_b;
					  fp4_second_half <= 1'b1;
					end else begin
					  a_o <= fp4_to_fp9_result_a;
					  b_o <= fp4_to_fp9_result_b;
					end
				end

				`FP8:begin
					case(type_ab_sub_reg)
					  `FP8E4M3:begin
						 a_o <= {a_reg[7],{1'b0,a_reg[6:3]},a_reg[2:0]};
						 b_o <= {b_reg[7],{1'b0,b_reg[6:3]},b_reg[2:0]};		
					end
					  `FP8E5M2:begin
						a_o <= {a_reg[7],a_reg[6:2],{a_reg[1:0],1'b0}};
						b_o <= {b_reg[7],b_reg[6:2],{b_reg[1:0],1'b0}};
					end
					default:begin
					  a_o <= 9'b0;
					  b_o <= 9'b0;
					end
				endcase
			end
			`FP16:begin
			  if(!fp16_second_cycle) begin
				a_o <= fp16_to_fp9_result_a;
				b_o <= 9'b0;
				fp16_second_cycle <= 1'b1;
			  end else begin
				a_o <= 9'b0;
				b_o <= fp16_to_fp9_result_b;
			  end
		end
			`FP32:begin
				a_o <= fp16_to_fp9_result_a;
				b_o <= 9'b0;
			end
			default:begin
				a_o <= 9'b0;
				b_o <= 9'b0;
			end
		endcase
	end

	OUTPUT:begin
		out_valid_o <= 1'b1;
		if(out_ready_i) begin
			out_valid_o <= 1'b0;
			in_ready_o <= 1'b1;
		end
	end
	endcase
	end
end






















endmodule
