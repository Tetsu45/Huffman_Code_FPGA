//============================================================
// shift_reg_tb.v — Testbench for shift_reg module
//============================================================
`timescale 1ns/1ps

module tb_shift_reg;

    // Parameters
    parameter MAX_CODE = 9;
    parameter CLK_PERIOD = 10;

    // DUT signals
    reg              clk;
    reg              reset;
    reg              load_bits;
    reg  [3:0]       in_bits;
    reg  [2:0]       in_len;
    reg              shift_en;
    reg  [3:0]       shift_len;
    wire [MAX_CODE-1:0] shift_buf;
    wire [3:0]       bit_count;

    // Instantiate DUT
    shift_reg #(
        .MAX_CODE(MAX_CODE)
    ) dut (
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

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize
        reset = 1;
        load_bits = 0;
        in_bits = 0;
        in_len = 0;
        shift_en = 0;
        shift_len = 0;

        // Dump waveforms
        $dumpfile("tb_shift_reg.vcd");
        $dumpvars(0, tb_shift_reg);

        // Release reset
        #(CLK_PERIOD*2);
        reset = 0;
        #(CLK_PERIOD);

        $display("\n=== Shift Register Test ===\n");
        $display("Time\tOperation\t\tin_bits\tin_len\tshift_len\tBuffer\t\t\tbit_count");
        $display("----\t---------\t\t-------\t------\t---------\t------\t\t\t---------");

        // Test sequence: Load a Huffman code stream
        // Stream: 0, -1, 2, -3, 4 -> "0" + "1110" + "1100" + "1010" + "111111"
        // Bitstream: 0 1110 1100 1010 111111

        // Load "0111" (4 bits: 0, then start of -1)
        @(posedge clk);
        load_bits = 1;
        in_bits = 4'b0111;  // LSB first: 0, 1, 1, 1
        in_len = 3'd4;
        @(posedge clk);
        load_bits = 0;
        #1;
        $display("%0t\tLoad 4 bits\t\t%b\t%0d\t-\t\t%b\t%0d", 
                 $time, in_bits, in_len, shift_buf, bit_count);

        // Decode "0" (1 bit)
        @(posedge clk);
        shift_en = 1;
        shift_len = 4'd1;
        @(posedge clk);
        shift_en = 0;
        #1;
        $display("%0t\tShift 1 bit (0)\t\t-\t-\t%0d\t\t%b\t%0d", 
                 $time, shift_len, shift_buf, bit_count);

        // Load "0110" (4 bits: rest of -1 code + start of 2)
        @(posedge clk);
        load_bits = 1;
        in_bits = 4'b0110;
        in_len = 3'd4;
        @(posedge clk);
        load_bits = 0;
        #1;
        $display("%0t\tLoad 4 bits\t\t%b\t%0d\t-\t\t%b\t%0d", 
                 $time, in_bits, in_len, shift_buf, bit_count);

        // Decode "1110" (4 bits, value = -1)
        @(posedge clk);
        shift_en = 1;
        shift_len = 4'd4;
        @(posedge clk);
        shift_en = 0;
        #1;
        $display("%0t\tShift 4 bits (-1)\t-\t-\t%0d\t\t%b\t%0d", 
                 $time, shift_len, shift_buf, bit_count);

        // Load "0010" (4 bits: rest of 2 + start of -3)
        @(posedge clk);
        load_bits = 1;
        in_bits = 4'b0010;
        in_len = 3'd4;
        @(posedge clk);
        load_bits = 0;
        #1;
        $display("%0t\tLoad 4 bits\t\t%b\t%0d\t-\t\t%b\t%0d", 
                 $time, in_bits, in_len, shift_buf, bit_count);

        // Decode "1100" (4 bits, value = 2)
        @(posedge clk);
        shift_en = 1;
        shift_len = 4'd4;
        @(posedge clk);
        shift_en = 0;
        #1;
        $display("%0t\tShift 4 bits (2)\t-\t-\t%0d\t\t%b\t%0d", 
                 $time, shift_len, shift_buf, bit_count);

        // Load "1111" (4 bits: rest of -3 + start of 4)
        @(posedge clk);
        load_bits = 1;
        in_bits = 4'b1111;
        in_len = 3'd4;
        @(posedge clk);
        load_bits = 0;
        #1;
        $display("%0t\tLoad 4 bits\t\t%b\t%0d\t-\t\t%b\t%0d", 
                 $time, in_bits, in_len, shift_buf, bit_count);

        // Decode "1010" (4 bits, value = -3)
        @(posedge clk);
        shift_en = 1;
        shift_len = 4'd4;
        @(posedge clk);
        shift_en = 0;
        #1;
        $display("%0t\tShift 4 bits (-3)\t-\t-\t%0d\t\t%b\t%0d", 
                 $time, shift_len, shift_buf, bit_count);

        // Load "11" (2 bits: rest of 4)
        @(posedge clk);
        load_bits = 1;
        in_bits = 4'b0011;
        in_len = 3'd2;
        @(posedge clk);
        load_bits = 0;
        #1;
        $display("%0t\tLoad 2 bits\t\t%b\t%0d\t-\t\t%b\t%0d", 
                 $time, in_bits, in_len, shift_buf, bit_count);

        // Decode "111111" (6 bits, value = 4)
        @(posedge clk);
        shift_en = 1;
        shift_len = 4'd6;
        @(posedge clk);
        shift_en = 0;
        #1;
        $display("%0t\tShift 6 bits (4)\t-\t-\t%0d\t\t%b\t%0d", 
                 $time, shift_len, shift_buf, bit_count);

        $display("\n=== Test: Edge Cases ===\n");

        // Test: Load maximum bits (9 bits total)
        @(posedge clk);
        load_bits = 1;
        in_bits = 4'b1111;
        in_len = 3'd4;
        @(posedge clk);
        load_bits = 0;
        #1;
        $display("%0t\tLoad 4 bits\t\t%b\t%0d\t-\t\t%b\t%0d", 
                 $time, in_bits, in_len, shift_buf, bit_count);

        @(posedge clk);
        load_bits = 1;
        in_bits = 4'b0101;
        in_len = 3'd4;
        @(posedge clk);
        load_bits = 0;
        #1;
        $display("%0t\tLoad 4 bits\t\t%b\t%0d\t-\t\t%b\t%0d", 
                 $time, in_bits, in_len, shift_buf, bit_count);

        @(posedge clk);
        load_bits = 1;
        in_bits = 4'b0001;
        in_len = 3'd1;
        @(posedge clk);
        load_bits = 0;
        #1;
        $display("%0t\tLoad 1 bit (9 total)\t%b\t%0d\t-\t\t%b\t%0d", 
                 $time, in_bits, in_len, shift_buf, bit_count);

        // Test: Try to overflow (should be ignored)
        @(posedge clk);
        load_bits = 1;
        in_bits = 4'b1010;
        in_len = 3'd4;
        @(posedge clk);
        load_bits = 0;
        #1;
        $display("%0t\tLoad 4 bits (overflow)\t%b\t%0d\t-\t\t%b\t%0d", 
                 $time, in_bits, in_len, shift_buf, bit_count);

        // Test: Longest codes (-8 = 111110010, 7 = 111110011)
        @(posedge clk);
        shift_en = 1;
        shift_len = 4'd9;
        @(posedge clk);
        shift_en = 0;
        #1;
        $display("%0t\tShift 9 bits\t\t-\t-\t%0d\t\t%b\t%0d", 
                 $time, shift_len, shift_buf, bit_count);

        // Load code for -8: 111110010
        @(posedge clk);
        load_bits = 1;
        in_bits = 4'b0100;  // 0, 1, 0, 0 (reversed for LSB first)
        in_len = 3'd4;
        @(posedge clk);
        load_bits = 0;
        #1;
        $display("%0t\tLoad 4 bits\t\t%b\t%0d\t-\t\t%b\t%0d", 
                 $time, in_bits, in_len, shift_buf, bit_count);

        @(posedge clk);
        load_bits = 1;
        in_bits = 4'b1111;  // 1, 1, 1, 1
        in_len = 3'd4;
        @(posedge clk);
        load_bits = 0;
        #1;
        $display("%0t\tLoad 4 bits\t\t%b\t%0d\t-\t\t%b\t%0d", 
                 $time, in_bits, in_len, shift_buf, bit_count);

        @(posedge clk);
        load_bits = 1;
        in_bits = 4'b0001;  // 1 (last bit)
        in_len = 3'd1;
        @(posedge clk);
        load_bits = 0;
        #1;
        $display("%0t\tLoad 1 bit (-8 code)\t%b\t%0d\t-\t\t%b\t%0d", 
                 $time, in_bits, in_len, shift_buf, bit_count);
        $display("\t\t(Expected: 111110010 = 9'b111110010)");

        // Decode -8 (9 bits)
        @(posedge clk);
        shift_en = 1;
        shift_len = 4'd9;
        @(posedge clk);
        shift_en = 0;
        #1;
        $display("%0t\tShift 9 bits (-8)\t-\t-\t%0d\t\t%b\t%0d", 
                 $time, shift_len, shift_buf, bit_count);

        $display("\n=== Test Complete ===\n");

        #(CLK_PERIOD*5);
        $finish;
    end

    // Monitor for debugging
    initial begin
        $monitor("Time=%0t reset=%b load=%b in_bits=%b in_len=%0d shift_en=%b shift_len=%0d | buf=%b count=%0d", 
                 $time, reset, load_bits, in_bits, in_len, shift_en, shift_len, shift_buf, bit_count);
    end

endmodule