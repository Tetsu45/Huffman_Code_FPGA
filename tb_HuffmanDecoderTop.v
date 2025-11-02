`timescale 1ns / 1ps
//------------------------------------------------------------
// Testbench for Huffman Decoder System
// (decoder_fsm + shift_reg + case_decoder)
// Rewritten in same format & signal naming as HuffmanDecoderTop
//------------------------------------------------------------
module tb_HuffmanDecoderTop;

    //--------------------------------------------------------
    // Clock & Reset
    //--------------------------------------------------------
    reg clk, reset;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100 MHz clock (10 ns)
    end

    //--------------------------------------------------------
    // DUT Interface Signals (top-style naming)
    //--------------------------------------------------------
    reg         svalid;               // input valid flag
    reg  [3:0]  in_bits;              // input bit chunk (4 bits)
    reg  [2:0]  in_len;               // number of valid bits
    wire        aready;               // FSM ready for next bits

    wire        load_bits;            // control to shift register
    wire        shift_en;
    wire [3:0]  shift_len;
    wire [8:0]  shift_buf;
    wire [3:0]  bit_count;

    wire        match_flag;
    wire [3:0]  match_symbol;
    wire [3:0]  match_len;

    wire signed [3:0] decoded_symbol;
    wire        tvalid;

    //--------------------------------------------------------
    // Instantiate Shift Register (top-style I/O)
    //--------------------------------------------------------
    shift_reg #(.MAX_CODE(9)) u_shift_reg (
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
    // Instantiate Case Decoder
    //--------------------------------------------------------
    case_decoder #(.MAX_CODE(9)) u_case_decoder (
        .shift_buf(shift_buf),
        .bit_count(bit_count),
        .match_flag(match_flag),
        .match_symbol(match_symbol),
        .match_len(match_len)
    );

    //--------------------------------------------------------
    // Instantiate FSM Controller
    //--------------------------------------------------------
    decoder_fsm #(.MAX_CODE(9)) u_fsm (
        .clk(clk),
        .reset(reset),
        .svalid(svalid),
        .in_data(in_bits),
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

    //--------------------------------------------------------
    // Example Encoded Stream (-8, -7, 0, 3)
    //--------------------------------------------------------
    // Codes:
    // -8 -> 111110010
    // -7 -> 11111000
    //  0 -> 0
    //  3 -> 11110
    // Stream = 11111001011111000011110
    // Split: [1111][1001][0111][1100][0011][110x]
    //--------------------------------------------------------
    reg [3:0] bitstream [0:5];
    integer i;

    initial begin
        bitstream[0] = 4'b1111;
        bitstream[1] = 4'b1001;
        bitstream[2] = 4'b0111;
        bitstream[3] = 4'b1100;
        bitstream[4] = 4'b0011;
        bitstream[5] = 4'b1100; // padding bits

        //----------------------------------------------------
        // Initialization (deterministic start)
        //----------------------------------------------------
        reset   = 1;
        svalid  = 0;
        in_bits = 0;
        in_len  = 0;

        #20; reset = 0; #10;
        $display("=== Huffman Decoder Simulation Start ===");

        //----------------------------------------------------
        // Feed chunks sequentially (4 bits each)
        //----------------------------------------------------
        for (i = 0; i < 6; i = i + 1) begin
            @(posedge clk);
            if (aready) begin
                svalid  <= 1'b1;
                in_bits <= bitstream[i];
                in_len  <= 3'd4;
                $display("[%0t] Sending packet %0d: %b", $time, i, bitstream[i]);
            end
            @(posedge clk);
            svalid <= 1'b0;
            #10;
        end

        //----------------------------------------------------
        // Wait for final decoding and outputs
        //----------------------------------------------------
        repeat (40) @(posedge clk);
        $display("=== Simulation Complete ===");
        $stop;
    end

    //--------------------------------------------------------
    // Output Monitor
    //--------------------------------------------------------
    always @(posedge clk) begin
        if (tvalid)
            $display("[%0t] Decoded Symbol: %0d (match_len=%0d)", 
                     $time, $signed(decoded_symbol), match_len);
    end

endmodule
