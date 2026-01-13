module hnf_bump `HNF_PARAM
    (
        //global inputs
        clk,
        rst,
        clk_bypass, //reserved clock interface

        //input
        data_in,

        //output 
        data_out
    );

    //global inputs
    input wire                                clk;
    input wire                                rst;
    input wire                                clk_bypass;
    input wire [`CACHE_LINE_WIDTH-1:0]        data_in;
    output reg [`CACHE_LINE_WIDTH-1:0]        data_out;

    wire [`CACHE_LINE_WIDTH-1:0] buffered_data;

    assign buffered_data = ~data_in;
    assign data_out = ~buffered_data;

endmodule