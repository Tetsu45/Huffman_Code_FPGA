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

    // Output side
    output reg  signed [3:0] decodedData,
    output reg         tvalid      // decodedData valid
);

    //--------------------------------------------------------
    // Internal signals for match detection
    //--------------------------------------------------------
    reg        match_flag_reg;
    reg        match_flag_comb;

    reg  signed [3:0] match_symbol_comb;
    reg  [3:0]        match_len_comb;

    reg  signed [3:0] match_symbol_reg;
    reg  [3:0]        match_len_reg;

    //--------------------------------------------------------
    // Combinational match detection (bit-count aware lookup)
    //--------------------------------------------------------
    always @(*) begin
        match_flag_comb   = 1'b0;
        match_symbol_comb = 4'd0;
        match_len_comb    = 4'd0;

        // 1-bit code (need at least 1 bit)
        if (bit_count >= 1 && shift_buf[8] == 1'b0) begin
            match_flag_comb   = 1'b1;
            match_symbol_comb = 4'sd0;
            match_len_comb    = 4'd1;
        end
        
        // 3-bit codes (need at least 3 bits)
        else if (bit_count >= 3 && shift_buf[8:6] == 3'b100) begin
            match_flag_comb   = 1'b1;
            match_symbol_comb = 4'sd1;
            match_len_comb    = 4'd3;
        end
        
        // 4-bit codes (need at least 4 bits)
        else if (bit_count >= 4) begin
            case (shift_buf[8:5])
                4'b1010: begin match_flag_comb=1'b1; match_symbol_comb=-4'sd3; match_len_comb=4'd4; end
                4'b1100: begin match_flag_comb=1'b1; match_symbol_comb= 4'sd2; match_len_comb=4'd4; end
                4'b1101: begin match_flag_comb=1'b1; match_symbol_comb=-4'sd2; match_len_comb=4'd4; end
                4'b1110: begin match_flag_comb=1'b1; match_symbol_comb=-4'sd1; match_len_comb=4'd4; end
                default: match_flag_comb = 1'b0;
            endcase
        end
        
        // 5-bit codes (need at least 5 bits)
        if (!match_flag_comb && bit_count >= 5) begin
            case (shift_buf[8:4])
                5'b10111: begin match_flag_comb=1'b1; match_symbol_comb=-4'sd4; match_len_comb=4'd5; end
                5'b11110: begin match_flag_comb=1'b1; match_symbol_comb= 4'sd3; match_len_comb=4'd5; end
                default: match_flag_comb = 1'b0;
            endcase
        end
        
        // 6-bit codes (need at least 6 bits)
        if (!match_flag_comb && bit_count == 6) begin
            case (shift_buf[8:3])
                6'b101101: begin match_flag_comb=1'b1; match_symbol_comb=-4'sd5; match_len_comb=4'd6; end
                6'b111111: begin match_flag_comb=1'b1; match_symbol_comb= 4'sd4; match_len_comb=4'd6; end
                default: match_flag_comb = 1'b0;
            endcase
        end
        
        // 7-bit codes (need at least 7 bits)
        if (!match_flag_comb && bit_count == 7) begin
            case (shift_buf[8:2])
                7'b1011000: begin match_flag_comb=1'b1; match_symbol_comb=-4'sd6; match_len_comb=4'd7; end
                7'b1011001: begin match_flag_comb=1'b1; match_symbol_comb= 4'sd6; match_len_comb=4'd7; end
                7'b1111101: begin match_flag_comb=1'b1; match_symbol_comb= 4'sd5; match_len_comb=4'd7; end
                default: match_flag_comb = 1'b0;
            endcase
        end
        
        // 8-bit codes (need at least 8 bits)
        if (!match_flag_comb && bit_count == 8) begin
            if (shift_buf[8:1] == 8'b11111000) begin
                match_flag_comb   = 1'b1;
                match_symbol_comb = -4'sd7;
                match_len_comb    = 4'd8;
            end
        end
        
        // 9-bit codes (need exactly 9 bits)
        if (!match_flag_comb && bit_count >= 9) begin
            case (shift_buf[8:0])
                9'b111110010: begin match_flag_comb=1'b1; match_symbol_comb=-4'sd8; match_len_comb=4'd9; end
                9'b111110011: begin match_flag_comb=1'b1; match_symbol_comb= 4'sd7; match_len_comb=4'd9; end
                default: match_flag_comb = 1'b0;
            endcase
        end
    end

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
    // Sequential register for match_flag/symbol/len
    //--------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            match_flag_reg   <= 1'b0;
            match_symbol_reg <= 4'd0;
            match_len_reg    <= 4'd0;
        end
        else if (state == S_OUTPUT) begin
            match_flag_reg <= 1'b0; // clear after output
        end
        else if (state == S_DECODE && match_flag_comb) begin
            match_flag_reg   <= 1'b1;
            match_symbol_reg <= match_symbol_comb;
            match_len_reg    <= match_len_comb;
        end
        else begin 
            match_flag_reg <= 1'b0; 
            match_len_reg  <= match_len_comb; 
        end
    end

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

            S_DECODE: begin
                if (match_flag_reg)
                    next_state = S_SHIFT;
                else if (!match_flag_reg && aready && svalid)
                    next_state = S_LOAD;
                else
                    next_state = S_DECODE;
            end

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
            // Defaults
            aready    <= 1'b0;
            load_bits <= 1'b0;
            shift_en  <= 1'b0;
            shift_len <= 4'd0;
            tvalid    <= 1'b0;

            case (state)
                S_IDLE:   aready <= 1'b1;

                S_LOAD:   load_bits <= 1'b1;

                S_DECODE: begin 
                    aready <= (bit_count < MAX_CODE);
                end

                S_SHIFT: begin
                    shift_en  <= match_flag_reg;
                    shift_len <= match_len_reg;   // use latched length
                end

                S_OUTPUT: begin
                    decodedData <= match_symbol_reg;
                    tvalid      <= 1'b1;
                end
            endcase
        end
    end

endmodule
