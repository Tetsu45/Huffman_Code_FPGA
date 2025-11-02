//============================================================
// Optimized Huffman Decoder FSM Controller
//============================================================
// Compatible with: shift_reg.v (variable shift) and case_decoder.v
//============================================================

`timescale 1ns/1ps
module decoder_fsm #(
    parameter MAX_CODE = 9  // maximum Huffman code length
)(
    input  wire        clk,
    input  wire        reset,

    // Handshake with input
    input  wire        svalid,    // input data valid
    input  wire [3:0]  in_data,   // input bits (LSB = newest)
    input  wire [2:0]  in_len,    // number of valid bits in in_data (1–4)
    output reg         aready,    // request more input bits

    // Interface to shift register
    output reg         load_bits, // tell shifter to append bits
    output reg         shift_en,  // shift out matched bits
    output reg  [3:0]  shift_len, // number of bits to shift after match
    input  wire [MAX_CODE-1:0] shift_buf,
    input  wire [3:0]  bit_count, // how many bits valid in buffer 

    // Interface from decoder table (case_decoder)
    input  wire        match_flag,
    input  wire [3:0]  match_symbol,
    input  wire [3:0]  match_len,

    // Output side
    output reg  [3:0]  decodedData,
    output reg         tvalid     // decodedData valid
);

    //--------------------------------------------------------
    // State Declaration
    //--------------------------------------------------------
    localparam [1:0]
        S_IDLE   = 2'd0,
        S_DECODE = 2'd1,
        S_OUTPUT = 2'd2;

    reg [1:0] state, next_state;

    //--------------------------------------------------------
    // Sequential State Update
    //--------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    //--------------------------------------------------------
    // Next-State Logic
    //--------------------------------------------------------
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:   if (svalid) next_state = S_DECODE;

            S_DECODE: if (match_flag) next_state = S_OUTPUT;
                       else           next_state = S_DECODE; // wait for match

            S_OUTPUT: next_state = S_DECODE; // continue decoding stream
        endcase
    end

    //--------------------------------------------------------
    // Output / Control Logic
    //--------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            aready      <= 1'b0;
            load_bits   <= 1'b0;
            shift_en    <= 1'b0;
            shift_len   <= 4'd0;
            decodedData <= 4'd0;
            tvalid      <= 1'b0;
        end else begin
            // Default signals (deassert every cycle)
            aready    <= 1'b0;
            load_bits <= 1'b0;
            shift_en  <= 1'b0;
            tvalid    <= 1'b0;
            shift_len <= 4'd0;

            case (state)

                //------------------------------------------------
                // S_IDLE: request first data chunk
                //------------------------------------------------
                S_IDLE: begin
                    aready <= 1'b1;  // ask for bits
                    if (svalid) begin
                        load_bits <= 1'b1;
                    end
                end

                //------------------------------------------------
                // S_DECODE: actively check buffer for matches
                //------------------------------------------------
                S_DECODE: begin
                    // Request more bits if buffer too low
                    aready <= (bit_count < 4);

                    if (svalid && aready)
                        load_bits <= 1'b1;  // accept new bits

                    // If a valid Huffman code found, trigger OUTPUT
                    if (match_flag) begin
                        shift_en  <= 1'b1;
                        shift_len <= match_len;
                        decodedData <= match_symbol; // deliver decoded symbol
                        tvalid    <= 1'b1;
                    end
                end

                //------------------------------------------------
                // S_OUTPUT: symbol emitted, update buffer
                //------------------------------------------------
                S_OUTPUT: begin
                    // After output, prepare for next match
                    shift_en  <= 1'b1;
                    shift_len <= match_len;
                    aready    <= (bit_count < 4); // refill if low
                    tvalid    <= 1'b0; // only 1-cycle pulse
                end
            endcase
        end
    end

endmodule
