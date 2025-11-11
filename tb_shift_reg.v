`timescale 1ns/1ps

module tb_shift_reg;
    parameter MAX_CODE = 9;

    reg clk, reset;
    reg sValid;
    reg [3:0] in_bits;
    reg [2:0] in_len;  // 0–4 allowed

    wire signed [3:0] decodedData;
    wire tvalid;

    // Internal debug
    wire [MAX_CODE-1:0] shift_buf = uut.shift_buf;
    wire [3:0] bit_count           = uut.bit_count;
    wire shift_en_tb               = uut.u_fsm.shift_en;

    // Instantiate DUT
    shift_reg #(.MAX_CODE(MAX_CODE)) uut (
        .clk(clk),
        .reset(reset),
        .sValid(sValid),
        .in_bits(in_bits),
        .in_len(in_len),
        .decodedData(decodedData),
        .tvalid(tvalid)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Compact display
    initial begin
        $display("Time(ns) | clk↑ | sValid | shift_en | in_bits | in_len | bit_count | shift_buf | tvalid | decodedData");
        forever begin
            @(posedge clk);
            $display("%8t |   ↑   |   %b    |    %b     |  %04b  |   %0d   |    %0d    | %09b |   %b   |   %0d",
                     $time, sValid, shift_en_tb, in_bits, in_len, bit_count, shift_buf, tvalid, decodedData);
        end
    end

    // === Simplified, fixed-timing chunk sender ===
    task send_chunk(input [3:0] bits, input [2:0] len);
    begin
        in_bits = bits;
        in_len  = len;
        @(posedge clk);  // stabilize
        sValid = 1;
        repeat (2) @(posedge clk);  // sValid = 1 for 2 clocks
        sValid = 0;
        repeat (6) @(posedge clk);  // idle 6 clocks
    end
    endtask

    // === Test sequence: Huffman codes -8 … 7 ===
    initial begin
        clk = 0;
        reset = 1;
        sValid = 0;
        in_bits = 0;
        in_len = 0;

        // Reset
        #20 reset = 0;

        // ------------------ Codes ------------------
        // -8 : 111110010 → 4+4+1 bits
        send_chunk(4'b1111, 3'd4);
        send_chunk(4'b1001, 3'd4);
        send_chunk(4'b0,    3'd1);

        // -7 : 11111000 → 4+4
        send_chunk(4'b1111, 3'd4);
        send_chunk(4'b1000, 3'd4);

        // -6 : 1011000 → 4+3
        send_chunk(4'b1011, 3'd4);
        send_chunk(4'b000,  3'd3);

        // -5 : 101101 → 4+2
        send_chunk(4'b1011, 3'd4);
        send_chunk(4'b01,   3'd2);

        // -4 : 10111 → 4+1
        send_chunk(4'b1011, 3'd4);
        send_chunk(4'b1,    3'd1);

        // -3 : 1010 → 4
        send_chunk(4'b1010, 3'd4);

        // -2 : 1101 → 4
        send_chunk(4'b1101, 3'd4);

        // -1 : 1110 → 4
        send_chunk(4'b1110, 3'd4);

        // 0 : 0 → 1
        send_chunk(4'b0,    3'd1);

        // 1 : 100 → 3
        send_chunk(4'b100,  3'd3);

        // 2 : 1100 → 4
        send_chunk(4'b1100, 3'd4);

        // 3 : 11110 → 4+1
        send_chunk(4'b1111, 3'd4);
        send_chunk(4'b0,    3'd1);

        // 4 : 111111 → 4+2
        send_chunk(4'b1111, 3'd4);
        send_chunk(4'b11,   3'd2);

        // 5 : 1111101 → 4+3
        send_chunk(4'b1111, 3'd4);
        send_chunk(4'b101,  3'd3);

        // 6 : 1011001 → 4+3
        send_chunk(4'b1011, 3'd4);
        send_chunk(4'b001,  3'd3);

        // 7 : 111110011 → 4+4+1
        send_chunk(4'b1111, 3'd4);
        send_chunk(4'b1001, 3'd4);
        send_chunk(4'b1,    3'd1);

        // Wait a few cycles to ensure last decoding
        repeat (20) @(posedge clk);

        $display("=== All codewords tested with fixed timing ===");
        $finish;
    end
endmodule
