`timescale 1ns/1ps

module tb_HuffmanDecoderTop;

    //--------------------------------------------------------
    // Parameters
    //--------------------------------------------------------
    parameter CLK_PERIOD = 10;  // 100 MHz
    parameter MAX_CODE = 9;

    //--------------------------------------------------------
    // DUT Signals
    //--------------------------------------------------------
    reg               clk;
    reg               reset;
    reg               svalid;
    reg [3:0]         in_bits;
    reg [2:0]         in_len;
    wire              aready;
    wire              tvalid;
    wire signed [3:0] decoded_symbol;

    //--------------------------------------------------------
    // Testbench Variables
    //--------------------------------------------------------
    integer i, j;
    integer error_count;
    integer success_count;
    integer test_num;

    // Expected symbol queue
    reg signed [3:0] expected_queue [0:255];
    integer exp_wr_ptr;
    integer exp_rd_ptr;

    //--------------------------------------------------------
    // Clock Generation
    //--------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    //--------------------------------------------------------
    // DUT Instantiation
    //--------------------------------------------------------
    HuffmanDecoderTop #(
        .MAX_CODE(MAX_CODE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .svalid(svalid),
        .in_bits(in_bits),
        .in_len(in_len),
        .aready(aready),
        .tvalid(tvalid),
        .decoded_symbol(decoded_symbol)
    );

    //--------------------------------------------------------
    // Monitor Output
    //--------------------------------------------------------
    always @(posedge clk) begin
        if (tvalid) begin
            if (exp_rd_ptr < exp_wr_ptr) begin
                if (decoded_symbol == expected_queue[exp_rd_ptr]) begin
                    $display("[%0t] ✓ PASS: Decoded symbol = %0d (expected %0d)", 
                             $time, decoded_symbol, expected_queue[exp_rd_ptr]);
                    success_count = success_count + 1;
                end else begin
                    $display("[%0t] ✗ FAIL: Decoded symbol = %0d (expected %0d)", 
                             $time, decoded_symbol, expected_queue[exp_rd_ptr]);
                    error_count = error_count + 1;
                end
                exp_rd_ptr = exp_rd_ptr + 1;
            end else begin
                $display("[%0t] ✗ ERROR: Unexpected symbol = %0d", $time, decoded_symbol);
                error_count = error_count + 1;
            end
        end
    end

    //--------------------------------------------------------
    // Reset Task
    //--------------------------------------------------------
    task reset_dut;
    begin
        reset = 1;
        svalid = 0;
        in_bits = 0;
        in_len = 0;
        exp_wr_ptr = 0;
        exp_rd_ptr = 0;
        error_count = 0;
        success_count = 0;
        repeat(3) @(posedge clk);
        reset = 0;
        @(posedge clk);
    end
    endtask

    //--------------------------------------------------------
    // Send Huffman Code Task
    //--------------------------------------------------------
    task send_huffman_code;
        input [8:0] code;            // max 9-bit code
        input [3:0] code_len;        // length
        input signed [3:0] symbol;
        reg [3:0] chunk_len;
        reg [8:0] remaining_bits;
        reg [3:0] remaining_len;
        integer bit_idx;
        integer k;
        reg [3:0] chunk;
    begin
        $display("[%0t] Sending symbol %0d: code=%b (len=%0d)", 
                 $time, symbol, code & ((1 << code_len)-1), code_len);

        // Add to expected queue
        expected_queue[exp_wr_ptr] = symbol;
        exp_wr_ptr = exp_wr_ptr + 1;

        remaining_bits = code;
        remaining_len = code_len;
        bit_idx = 0;

        // Send code in 1–4 bit chunks (LSB-first per chunk)
        while (remaining_len > 0) begin
            while (!aready) @(posedge clk);

            chunk_len = (remaining_len > 4) ? 4 : remaining_len;

            // Extract LSB-first bits for this chunk
            chunk = remaining_bits & ((1 << chunk_len)-1);

            in_bits = chunk;
            in_len  = chunk_len;
            svalid = 1;
            @(posedge clk);
            svalid = 0;

            remaining_bits = remaining_bits >> chunk_len;
            remaining_len = remaining_len - chunk_len;
            bit_idx = bit_idx + chunk_len;
        end
    end
    endtask

    //--------------------------------------------------------
    // Send Symbol Task
    //--------------------------------------------------------
    task send_symbol;
        input signed [3:0] sym;
    begin
        case (sym)
            -8: send_huffman_code(9'b111110010, 9, -8);
            -7: send_huffman_code(8'b11111000, 8, -7);
            -6: send_huffman_code(7'b1011000, 7, -6);
            -5: send_huffman_code(6'b101101, 6, -5);
            -4: send_huffman_code(5'b10111, 5, -4);
            -3: send_huffman_code(4'b1010, 4, -3);
            -2: send_huffman_code(4'b1101, 4, -2);
            -1: send_huffman_code(4'b1110, 4, -1);
             0: send_huffman_code(1'b0, 1, 0);
             1: send_huffman_code(3'b100, 3, 1);
             2: send_huffman_code(4'b1100, 4, 2);
             3: send_huffman_code(5'b11110, 5, 3);
             4: send_huffman_code(6'b111111, 6, 4);
             5: send_huffman_code(7'b1111101, 7, 5);
             6: send_huffman_code(7'b1011001, 7, 6);
             7: send_huffman_code(9'b111110011, 9, 7);
        endcase
    end
    endtask

    //--------------------------------------------------------
    // Main Test Sequence
    //--------------------------------------------------------
    initial begin
        $display("=== Huffman Decoder Test Start ===");
        reset_dut();

        // Send each symbol once
        for (i = -8; i <= 7; i = i + 1) begin
            send_symbol(i);
        end

        // Wait for all outputs
        repeat (100) @(posedge clk);

        $display("=== Huffman Decoder Test End ===");
        $display("PASS: %0d, FAIL: %0d", success_count, error_count);

        $finish;
    end

endmodule
