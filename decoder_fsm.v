//============================================================
// Optimized Huffman Decoder FSM Controller (Self-contained)
//============================================================
// Integrates: shift_reg.v + internal case_decoder.v
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
    input  wire [2:0]  in_len,    // number of valid bits (1–4)
    output reg         aready,    // request more input bits

    // Interface to shift register
    output reg         load_bits, // tell shifter to append bits
    output reg         shift_en,  // shift out matched bits
    output reg  [3:0]  shift_len, // number of bits to shift
    input  wire [MAX_CODE-1:0] shift_buf,
    input  wire [3:0]  bit_count, // valid bits in buffer
	 //input wire buffer_ready,

    // Output side
    output reg  signed [3:0] decodedData,
    output reg         tvalid      // decodedData valid
);

    //--------------------------------------------------------
    // Internal signals for match detection
    //--------------------------------------------------------
    reg        match_flag;
    reg signed [3:0] match_symbol;
    reg  [3:0] match_len;
    //wire       need_more_bits;

    //--------------------------------------------------------
    // Decode current shift_buf bits
    //--------------------------------------------------------
    always @(*) begin
        match_flag   = 1'b0;
        match_symbol = 4'd0;
        match_len    = 4'd0;

        if (bit_count > 0) begin
            casez (shift_buf[MAX_CODE-1:MAX_CODE-9])
                9'b0????????:     begin match_flag=1; match_symbol=4'sd0;  match_len=4'd1; end
                9'b100??????:     begin match_flag=1; match_symbol=4'sd1;  match_len=4'd3; end
                9'b1010?????:     begin match_flag=1; match_symbol=-4'sd3; match_len=4'd4; end
                9'b10111????:     begin match_flag=1; match_symbol=-4'sd4; match_len=4'd5; end
                9'b101101???:     begin match_flag=1; match_symbol=-4'sd5; match_len=4'd6; end
                9'b1011000??:     begin match_flag=1; match_symbol=-4'sd6; match_len=4'd7; end
                9'b1011001??:     begin match_flag=1; match_symbol=4'sd6;  match_len=4'd7; end
                9'b1100?????:     begin match_flag=1; match_symbol=4'sd2;  match_len=4'd4; end
                9'b1101?????:     begin match_flag=1; match_symbol=-4'sd2; match_len=4'd4; end
                9'b1110?????:     begin match_flag=1; match_symbol=-4'sd1; match_len=4'd4; end
                9'b11110????:     begin match_flag=1; match_symbol=4'sd3;  match_len=4'd5; end
                9'b1111101??:     begin match_flag=1; match_symbol=4'sd5;  match_len=4'd7; end
                9'b111111???:     begin match_flag=1; match_symbol=4'sd4;  match_len=4'd6; end
                9'b11111000?:     begin match_flag=1; match_symbol=-4'sd7; match_len=4'd8; end
                9'b111110010:     begin match_flag=1; match_symbol=-4'sd8; match_len=4'd9; end
                9'b111110011:     begin match_flag=1; match_symbol=4'sd7;  match_len=4'd9; end
                default:          match_flag=0;
            endcase
        end
    end

    //--------------------------------------------------------
    // Need more bits logic
    //--------------------------------------------------------
    assign need_more_bits = (bit_count < MAX_CODE) && !match_flag;

    //--------------------------------------------------------
    // State Declaration
    //--------------------------------------------------------
    localparam [2:0]
        S_IDLE   = 3'd0,
        S_LOAD   = 3'd1,
        S_DECODE = 3'd2,
        S_SHIFT  = 3'd3,
        S_OUTPUT = 3'd4;

    reg [2:0] state, next_state;

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
            S_LOAD:   next_state = S_DECODE;
            S_DECODE: if (match_flag)
                          next_state = S_SHIFT;
                      else if (aready)
                          next_state = S_LOAD;
                      else
                          next_state = S_DECODE;
            S_SHIFT:  next_state = S_OUTPUT;
            S_OUTPUT: next_state = S_DECODE;
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
            // Default
            aready    <= 1'b0;
            load_bits <= 1'b0;
            shift_en  <= 1'b0;
            shift_len <= 4'd0;
            tvalid    <= 1'b0;

            case (state)
                //------------------------------------------------
                // IDLE: wait for start
                //------------------------------------------------
                S_IDLE: begin
                    aready <= 1'b1;
						  //svalid <= 1'b1;
                end

                //------------------------------------------------
                // LOAD: append bits from input
                //------------------------------------------------
                S_LOAD: begin
                    aready    <= 1'b0;
                    load_bits <= 1'b1;
                end

                //------------------------------------------------
                // DECODE: check for matches or need more bits
                //------------------------------------------------
                S_DECODE: begin
					     //svalid <= 1'b0;
                    aready <= (bit_count < 4);
                end

                //------------------------------------------------
                // SHIFT: consume matched bits
                //------------------------------------------------
                S_SHIFT: begin
                    shift_en  <= 1'b1;
                    shift_len <= match_len;
                end

                //------------------------------------------------
                // OUTPUT: produce decoded symbol
                //------------------------------------------------
                S_OUTPUT: begin
                    decodedData <= match_symbol;
                    tvalid      <= 1'b1;
                end
            endcase
        end
    end

endmodule
