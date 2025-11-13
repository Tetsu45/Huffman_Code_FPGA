`timescale 1ns/1ps

module tb_shift_reg;
    parameter MAX_CODE = 9;

    reg clk, reset;
    reg sValid;
    reg [3:0] in_bits;
    reg [2:0] in_len;

    wire signed [3:0] decodedData;
    wire tvalid;
	 // 256-bit encoded string
    reg [255:0] encoded_bits;

    // Internal debug
    wire [MAX_CODE-1:0] shift_buf = uut.shift_buf;
    wire [3:0] bit_count           = uut.bit_count;
    wire shift_en_tb               = uut.u_fsm.shift_en;
    // Counter for decoded codewords
    integer codeword_count;
	 integer i;
    reg [3:0] chunk;
    reg [2:0] chunk_len;
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

    // Display
    initial begin
        $display("Time(ns) | clk↑ | sValid | shift_en | in_bits | in_len | bit_count | shift_buf | tvalid | decodedData");
        forever begin
            @(posedge clk);
            $display("%8t |   ↑   |   %b    |    %b     |  %04b  |   %0d   |    %0d    | %09b |   %b   |   %0d",
                     $time, sValid, shift_en_tb, in_bits, in_len, bit_count, shift_buf, tvalid, decodedData);
        end
    end

    // Task to send a chunk
    task send_chunk(input [3:0] bits, input [2:0] len);
    begin
        in_bits = bits;
        in_len  = len;
        @(posedge clk);
        sValid = 1;
        repeat(2)@(posedge clk);
        sValid = 0;
        repeat (16) @(posedge clk);  // idle a few cycles
    end
    endtask

    initial codeword_count = 0;

    // Increment counter on tvalid
    always @(posedge clk) begin
        if (tvalid)
            codeword_count = codeword_count + 1;
    end

    // === Send 256-bit encoded string as 4-bit chunks ===
    initial begin
	      // VCD dump
        $dumpfile("tb_shift_reg.vcd");
        $dumpvars(0, tb_shift_reg);
        clk = 0;
        reset = 1;
        sValid = 0;
        in_bits = 0;
        in_len = 0;
        codeword_count = 0;
          
        #20 reset = 0;

        
        encoded_bits = 256'b0001100101101001110001100110000100001101110000011110011101110100100100100011100110100000110000110100000001000011101110110111100110111001011100000111001100001010110100000011100110111100010011100100100000000101011011001101111011110111011001101111011010110000;

       

        i = 255; // start from MSB
        while (i >= 0) begin
            if (i >= 3) chunk_len = 3'd4;
            else         chunk_len = i + 1;

            case (chunk_len)
                3'd4: chunk = encoded_bits[i -: 4];
                3'd3: chunk = encoded_bits[i -: 3];
                3'd2: chunk = encoded_bits[i -: 2];
                3'd1: chunk = encoded_bits[i -: 1];
                default: chunk = 0;
            endcase

            send_chunk(chunk, chunk_len);
            i = i - chunk_len;
        end

        // Wait a few cycles to finish decoding
        repeat (50) @(posedge clk);

        $display("=== 256-bit encoded string simulation done ===");
        $display("Total codewords decoded: %0d", codeword_count);

        $finish;
    end
endmodule



// 2nd test bench I used for simulation 
`timescale 1ns/1ps

module tb_shift_reg;
    parameter MAX_CODE = 9;

    reg clk, reset;
    reg sValid;
    reg [3:0] in_bits;
    reg [2:0] in_len;

    wire signed [3:0] decodedData;
    wire tvalid;

    // 256-bit encoded string
    reg [255:0] encoded_bits;

    // Internal debug
    wire [MAX_CODE-1:0] shift_buf = uut.shift_buf;
    wire [3:0] bit_count           = uut.bit_count;
    wire shift_en_tb               = uut.u_fsm.shift_en;

    // Counter for decoded codewords
    integer codeword_count;
    integer i;
    reg [3:0] chunk;
    reg [2:0] chunk_len;

    // === Added for Power/Timing Analysis ===
    // These help record performance metrics (cycles, timing, etc.)
    integer first_cycle;
    integer last_cycle;
    reg seen_first_input;
    reg [63:0] sim_cycle_counter;
    integer sim_stats_fh;
	  integer cycles_used;
    // =======================================

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

    // Display
    initial begin
        $display("Time(ns) | clk↑ | sValid | shift_en | in_bits | in_len | bit_count | shift_buf | tvalid | decodedData");
        forever begin
            @(posedge clk);
            $display("%8t |   ↑   |   %b    |    %b     |  %04b  |   %0d   |    %0d    | %09b |   %b   |   %0d",
                     $time, sValid, shift_en_tb, in_bits, in_len, bit_count, shift_buf, tvalid, decodedData);
        end
    end

    // Task to send a chunk
    task send_chunk(input [3:0] bits, input [2:0] len);
    begin
        in_bits = bits;
        in_len  = len;
        @(posedge clk);
        sValid = 1;
        repeat(2)@(posedge clk);
        sValid = 0;
        repeat (16) @(posedge clk);  // idle a few cycles
    end
    endtask

    initial codeword_count = 0;

    // Increment counter on tvalid
    always @(posedge clk) begin
        if (tvalid)
            codeword_count = codeword_count + 1;
    end

    // === Added for Power/Timing Analysis ===
    // Counts simulation cycles and records when first input and last output occur
    always @(posedge clk) begin
        sim_cycle_counter <= sim_cycle_counter + 1;

        // First sValid pulse = first input
        if (sValid && !seen_first_input) begin
            seen_first_input = 1;
            first_cycle = sim_cycle_counter;
            $display("FIRST_INPUT_CYCLE %0d", first_cycle);
            if (sim_stats_fh != 0) $fdisplay(sim_stats_fh, "FIRST_INPUT_CYCLE %0d", first_cycle);
        end

        // Last tvalid pulse = last output
        if (tvalid) begin
            last_cycle = sim_cycle_counter;
            $display("LAST_OUTPUT_CYCLE %0d (intermediate)", last_cycle);
            if (sim_stats_fh != 0) $fdisplay(sim_stats_fh, "LAST_OUTPUT_CYCLE %0d", last_cycle);
        end
    end
    // =======================================

    // === Main simulation ===
    initial begin
        // === Added for Power/Timing Analysis ===
        // VCD dump for power analyzer (used in Quartus Power Analyzer)
        $dumpfile("tb_shift_reg.vcd");
        $dumpvars(0, tb_shift_reg);

        // Open result file (auto-created when simulation starts)
        sim_stats_fh = $fopen("sim_stats.txt", "w");
        if (sim_stats_fh == 0) $display("ERROR: Could not open sim_stats.txt");
        first_cycle = -1;
        last_cycle = -1;
        seen_first_input = 0;
        sim_cycle_counter = 0;
        // =======================================

        clk = 0;
        reset = 1;
        sValid = 0;
        in_bits = 0;
        in_len = 0;
        codeword_count = 0;

        #20 reset = 0;

        encoded_bits = 256'b0001100101101001110001100110000100001101110000011110011101110100100100100011100110100000110000110100000001000011101110110111100110111001011100000111001100001010110100000011100110111100010011100100100000000101011011001101111011110111011001101111011010110000;

        i = 255;
        while (i >= 0) begin
            if (i >= 3) chunk_len = 3'd4;
            else         chunk_len = i + 1;

            case (chunk_len)
                3'd4: chunk = encoded_bits[i -: 4];
                3'd3: chunk = encoded_bits[i -: 3];
                3'd2: chunk = encoded_bits[i -: 2];
                3'd1: chunk = encoded_bits[i -: 1];
                default: chunk = 0;
            endcase

            send_chunk(chunk, chunk_len);
            i = i - chunk_len;
        end

        // Wait a few cycles to finish decoding
        repeat (50) @(posedge clk);

        // === Added for Power/Timing Analysis ===
        // Compute total cycles and record summary at the end
       
        if (first_cycle != -1 && last_cycle != -1) begin
            cycles_used = last_cycle - first_cycle + 1;
            $display("SIM_SUMMARY: FIRST=%0d LAST=%0d CYCLES_USED=%0d", first_cycle, last_cycle, cycles_used);
            if (sim_stats_fh != 0) $fdisplay(sim_stats_fh, "SIM_SUMMARY: FIRST=%0d LAST=%0d CYCLES_USED=%0d", first_cycle, last_cycle, cycles_used);
        end else begin
            $display("WARNING: Missing first or last cycle record");
        end

        $display("Total codewords decoded: %0d", codeword_count);
        if (sim_stats_fh != 0) $fdisplay(sim_stats_fh, "Total codewords decoded: %0d", codeword_count);

        if (sim_stats_fh != 0) $fclose(sim_stats_fh);
        // =======================================

        $display("=== 256-bit encoded string simulation done ===");
        $finish;
    end
endmodule
