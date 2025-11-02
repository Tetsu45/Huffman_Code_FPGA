//============================================================
// HuffmanDecoderTop.v — Integrated Huffman Decoder System
//============================================================
// Combines FSM, Shift Register, and Case Decoder
// Outputs decoded symbols from incoming Huffman bitstream
//============================================================

`timescale 1ns/1ps
module HuffmanDecoderTop #(
    parameter MAX_CODE = 9
)(
    input  wire        clk,
    input  wire        reset,

    // Input bit stream interface
    input  wire        svalid,       // input valid
    input  wire [3:0]  in_bits,      // up to 4 bits input (LSB newest)
    input  wire [2:0]  in_len,       // number of valid bits
    output wire        aready,       // request more bits

    // Output decoded symbol interface
    output wire        tvalid,       // output valid
    output wire signed [3:0] decoded_symbol
);

    //--------------------------------------------------------
    // Internal connections
    //--------------------------------------------------------
    wire              load_bits;
    wire              shift_en;
    wire [3:0]        shift_len;
    wire [MAX_CODE-1:0] shift_buf;
    wire [3:0]        bit_count;
    wire              match_flag;
	 
    wire [3:0]        match_symbol;
    wire [3:0]        match_len;

    //--------------------------------------------------------
    // Instantiate Shift Register
    //--------------------------------------------------------
    shift_reg #(
        .MAX_CODE(MAX_CODE)
    ) u_shift_reg (
        .clk(clk),
        .reset(reset),
        .load_bits(load_bits),
        .in_bits(in_bits),
        .in_len(in_len),
        .shift_en(shift_en),
        .shift_len(shift_len),
        .shift_buf(shift_buf),
        .bit_count(bit_count)
    );

    //--------------------------------------------------------
    // Instantiate Case Decoder (codebook)
    //--------------------------------------------------------
    case_decoder #(
        .MAX_CODE(MAX_CODE)
    ) u_case_decoder (
        .shift_buf(shift_buf),
        .bit_count(bit_count),
        .match_flag(match_flag),
        .match_symbol(match_symbol),
        .match_len(match_len)
    );

    //--------------------------------------------------------
    // Instantiate FSM Controller
    //--------------------------------------------------------
    decoder_fsm #(
        .MAX_CODE(MAX_CODE)
    ) u_fsm (
        .clk(clk),
        .reset(reset),
        .svalid(svalid),
        .in_data(in_bits),       // reuse same bits
        .in_len(in_len),
        .aready(aready),
        .load_bits(load_bits),
        .shift_en(shift_en),
        .shift_len(shift_len),
        .shift_buf(shift_buf),
        .bit_count(bit_count),
        .match_flag(match_flag),
        .match_symbol(match_symbol),
        .match_len(match_len),
        .decodedData(decoded_symbol),
        .tvalid(tvalid)
    );

endmodule
