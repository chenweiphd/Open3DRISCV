module fp4_to_fp9 (
	input	wire[7:0]	packed_fp4,
	input	wire		select_high,
	output	reg[8:0]	fp9,
	output	reg		invalid,
	output	reg		underflow,
	output	reg		overflow
);
always @(*) begin

        reg	[3:0]	fp4_high;
		reg	[3:0]	fp4_low;

		reg	[3:0]	selected_fp4;

		reg		fp4_sgn;
		reg	[1:0]	fp4_exp;
		reg		fp4_sig;	
	fp9 = 9'h0;
	invalid = 1'b0;
	underflow = 1'b0;
	overflow = 1'b0;

	fp4_high = packed_fp4[7:4];
	fp4_low = packed_fp4[3:0];
	selected_fp4 = select_high ? fp4_high : fp4_low;
	fp4_sgn = selected_fp4[3];
	fp4_exp = selected_fp4[2:1];
	fp4_sig = selected_fp4[0];

//check NaN & Inf
	if(fp4_exp == 2'b11) begin
	  if(fp4_sig == 1'b1) begin
		//NaN
		//fp9 = {fp4_sgn, 4'b1111, 4'b0001};
		fp9 = {fp4_sgn, 5'b11111, 3'b001};
		invalid = 1'b1;
	  end else begin
		//Inf
		fp9 = {fp4_sgn, 5'b11111, 3'b000};
	  end
	end
//check zero
	else if (fp4_exp == 2'b00) begin
	if (fp4_sig == 1'b0) begin
		fp9 = {fp4_sgn, 5'b00000, 3'b000};
	end else begin
	//fp9={fp4_sgn,5'b00001,3'b000};
	fp9={fp4_sgn,5'b00000,{fp4_sig,2'b00}};
	end
	end
	else begin
		case(fp4_exp)
		  2'b00:begin
			fp9[8] = fp4_sgn;
			fp9[7:3] = 5'b00000;
			fp9[2:0] = {fp4_sig,2'b00};
		  end
		  2'b01:begin
			fp9[8] = fp4_sgn;
			fp9[7:3] = 5'b01111; //1+6=7
			fp9[2:0] = {fp4_sig,2'b00};
		  end
		  2'b10:begin
			//fp9[8] = fp4_sgn;
			//fp9[7:3] = 5'b10000; //2+6=8
			//fp9[2:0] = {fp4_sig, 2'b00};
			fp9 = {fp4_sgn,5'b11111,3'b000};
		  end
		  default:begin
			fp9 = {fp4_sgn,5'b11111,3'b000};
			
		  end
		endcase
	end

end
endmodule




		

















