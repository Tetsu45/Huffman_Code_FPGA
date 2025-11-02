`timescale 1ns/1ps

module tb_shift_reg;

    // Parameters
    parameter MAX_CODE = 9;

    // Signals
    reg clk;
    reg reset;
    reg load;
    reg in_bit;
    wire [MAX_CODE-1:0] bits;
    wire [3:0] count;

    // Instantiate the module
    shift_reg #(MAX_CODE) uut (
        .clk(clk),
        .reset(reset),
        .load(load),
        .in_bit(in_bit),
        .bits(bits),
        .count(count)
    );

    // Clock generation
    always #5 clk = ~clk; // 10ns period

    // Task to send a Huffman code
    task send_code;
        input [MAX_CODE*8-1:0] code_str; // up to 9 bits as string (ASCII)
        input integer length;
        integer i;
        begin
            $display("\n--- Sending code: %s (length=%0d) ---", code_str, length);
            for (i = length-1; i >= 0; i = i - 1) begin
                in_bit = (code_str[i*8 +: 8] == "1") ? 1'b1 : 1'b0;
                load   = 1;
                @(posedge clk);
                $display("Bit %0d: in_bit=%b | bits=%b | count=%0d", length-i, in_bit, bits, count);
            end
            load = 0;
            @(posedge clk);
        end
    endtask

    // Initial stimulus
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        load = 0;
        in_bit = 0;

        // Wait and release reset
        #10 reset = 0;

        // Send all Huffman codes
        send_code("111110010", 9); // -8
        reset_sequence();

        send_code("11111000", 8); // -7
        reset_sequence();

        send_code("1011000", 7); // -6
        reset_sequence();

        send_code("101101", 6); // -5
        reset_sequence();

        send_code("10111", 5); // -4
        reset_sequence();

        send_code("1010", 4); // -3
        reset_sequence();

        send_code("1101", 4); // -2
        reset_sequence();

        send_code("1110", 4); // -1
        reset_sequence();

        send_code("0", 1); // 0
        reset_sequence();

        send_code("100", 3); // 1
        reset_sequence();

        send_code("1100", 4); // 2
        reset_sequence();

        send_code("11110", 5); // 3
        reset_sequence();

        send_code("111111", 6); // 4
        reset_sequence();

        send_code("1111101", 7); // 5
        reset_sequence();

        send_code("1011001", 7); // 6
        reset_sequence();

        send_code("111110011", 9); // 7
        reset_sequence();

        $display("\nAll test sequences completed.");
        $stop;
    end

    // Task to reset between codes
    task reset_sequence;
        begin
            @(posedge clk);
            reset = 1;
            @(posedge clk);
            reset = 0;
        end
    endtask

endmodule
