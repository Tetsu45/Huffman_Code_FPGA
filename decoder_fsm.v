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
    wire [MAX_CODE-1:0] valid_window;
    //assign valid_window = shift_buf << (MAX_CODE - bit_count);
	 //assign shift_buf = shift_buf << (MAX_CODE - bit_count);
    //--------------------------------------------------------
    // Combinational match detection (lookup table)
    //--------------------------------------------------------
    always @(*) begin
        match_flag_comb   = 1'b0;
        match_symbol_comb = 4'd0;
        match_len_comb    = 4'd0;

        if (bit_count > 0 ) begin
            casez (shift_buf)
                9'b0????????:     begin match_flag_comb=1; match_symbol_comb=4'sd0;  match_len_comb=4'd1; end
                9'b100??????:     begin match_flag_comb=1; match_symbol_comb=4'sd1;  match_len_comb=4'd3; end
                9'b1010?????:     begin match_flag_comb=1; match_symbol_comb=-4'sd3; match_len_comb=4'd4; end
                9'b10111????:     begin match_flag_comb=1; match_symbol_comb=-4'sd4; match_len_comb=4'd5; end
                9'b101101???:     begin match_flag_comb=1; match_symbol_comb=-4'sd5; match_len_comb=4'd6; end
                9'b1011000??:     begin match_flag_comb=1; match_symbol_comb=-4'sd6; match_len_comb=4'd7; end
                9'b1011001??:     begin match_flag_comb=1; match_symbol_comb= 4'sd6; match_len_comb=4'd7; end
                9'b1100?????:     begin match_flag_comb=1; match_symbol_comb= 4'sd2; match_len_comb=4'd4; end
                9'b1101?????:     begin match_flag_comb=1; match_symbol_comb=-4'sd2; match_len_comb=4'd4; end
                9'b1110?????:     begin match_flag_comb=1; match_symbol_comb=-4'sd1; match_len_comb=4'd4; end
                9'b11110????:     begin match_flag_comb=1; match_symbol_comb= 4'sd3; match_len_comb=4'd5; end
                9'b1111101??:     begin match_flag_comb=1; match_symbol_comb= 4'sd5; match_len_comb=4'd7; end
                9'b111111???:     begin match_flag_comb=1; match_symbol_comb= 4'sd4; match_len_comb=4'd6; end
                9'b11111000?:     begin match_flag_comb=1; match_symbol_comb=-4'sd7; match_len_comb=4'd8; end
                9'b111110010:     begin match_flag_comb=1; match_symbol_comb=-4'sd8; match_len_comb=4'd9; end
                9'b111110011:     begin match_flag_comb=1; match_symbol_comb= 4'sd7; match_len_comb=4'd9; end
                default:          begin match_flag_comb=0; match_symbol_comb=0; match_len_comb=0; end
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
                else if (!match_flag_reg && aready)
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

                S_DECODE: begin aready <= (bit_count < MAX_CODE - 4);
					                 //shift_buf <= shift_buf << (MAX_CODE - bit_count);
					 end

                S_SHIFT: begin
					   
                    shift_en  <= 1'b1;
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
