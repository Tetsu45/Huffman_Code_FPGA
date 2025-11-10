`timescale 1ns/1ps

module tb_shift_reg;
    parameter MAX_CODE = 9;

    reg clk, reset;
    reg sValid;
    reg [3:0] in_bits;
    reg [2:0] in_len;

    wire signed [3:0] decodedData;
    wire tvalid;

    // Access internal signals for debug
    wire [MAX_CODE-1:0] shift_buf       = uut.shift_buf;
    wire [3:0]          bit_count       = uut.bit_count;
    wire [MAX_CODE-1:0] valid_window_tb = uut.valid_window;
    wire                shift_en_tb     = uut.u_fsm.shift_en;  // << added this line!

    // Instantiate DUT (your integrated module)
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

    // Display format
    initial begin
        $display(" Time | clk | sValid | shift_en | in_bits | in_len | bit_count | shift_buf     | valid_window  | tvalid | decodedData");
        $monitor("%4t |  %b  |   %b    |    %b     |  %b  |   %0d   |     %0d     | %b | %b |   %b   |    %0d",
                 $time, clk, sValid, shift_en_tb, in_bits, in_len,
                 bit_count, shift_buf, valid_window_tb, tvalid, decodedData);
    end

    // Stimulus
    initial begin
        clk = 0;
        reset = 1;
        sValid = 0;
        in_bits = 4'b0000;
        in_len = 3'd0;

        // Hold reset
        #20 reset = 0;

        // === Input sequence ===
        // 1) Feed "1111"
        @(posedge clk);
        sValid = 1; in_bits = 4'b1111; in_len = 3'd4;

        @(posedge clk);
        sValid = 0;
        repeat (4) @(posedge clk);

        // 2) Feed "0010"
        @(posedge clk);
        sValid = 1; in_bits = 4'b0010; in_len = 3'd3;

        @(posedge clk);
        sValid = 0;
        repeat (5) @(posedge clk);
        in_bits = 4'b0111; in_len = 3'd4;
        // 3) Feed "0000"
        @(posedge clk);
        sValid = 1;

        @(posedge clk);
        sValid = 0;
		repeat (5) @(posedge clk);
        in_bits = 4'b1100; in_len = 3'd4;
		  @(posedge clk);
		  sValid = 1;
        // Let FSM continue processing
		  
		  @(posedge clk);
        sValid = 0;
		repeat (5) @(posedge clk);
        in_bits = 4'b1000; in_len = 3'd4;
		  @(posedge clk);
		  sValid = 1;
        repeat (5) @(posedge clk);
			sValid = 0;
			repeat (10) @(posedge clk);
        $display("Simulation complete.");
        $finish;
    end
endmodule
