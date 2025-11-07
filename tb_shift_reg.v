`timescale 1ns/1ps

module tb_shift_reg;
    parameter MAX_CODE = 9;

    reg clk, reset;
    //reg load_bits, shift_en;
    reg [3:0] in_bits;
    reg [2:0] in_len;
	 reg sValid;
    //reg [3:0] shift_len;
    wire signed [3:0] decodedData;
    //wire [MAX_CODE-1:0] shift_buf;
    //wire [3:0] bit_count;
    //wire need_more_bits, buffer_ready;
   
	 // DUT instantiation
    shift_reg uut (
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

   initial begin
    $display("Time\tclk\treset\tsValid\tin_len\tin_bits\tdecodedData\ttvalid\tbuffer_ready\tshift_buf");
    $monitor("%0t\t%b\t%b\t%b\t%d\t%b\t%d\t%b\t%b",
             $time, clk, reset, sValid, in_len, in_bits,
             decodedData, tvalid, uut.shift_buf);
end

    // Stimulus
initial begin
    clk = 0;
    reset = 1;
    sValid = 0;
    in_bits = 0;
    in_len  = 0;

    // Apply reset
    #10 reset = 0;

    // === Feed input bit streams ===
    // FSM will load when buffer_ready is high internally.

    // 1) Provide 4 bits "1111"
    @(posedge clk);
    sValid = 1; in_bits = 4'b1111; in_len = 3'd4;
    repeat(5)@(posedge clk);
    sValid = 0;

    // 2) Wait and send 3 bits "010"
    repeat(2) @(posedge clk);
    sValid = 1; in_bits = 4'b0010; in_len = 3'd3;
    repeat(5)@(posedge clk);
    sValid = 0;

    // 3) Provide 4 bits "1011"
    //repeat(3) @(posedge clk);
    //sValid = 1; in_bits = 4'b1011; in_len = 3'd4;
    //repeat(5)@(posedge clk);
    //sValid = 0;

    // 4) Provide 4 bits "1100"
    //repeat(3) @(posedge clk);
    //sValid = 1; in_bits = 4'b1100; in_len = 3'd4;
    //repeat(5)@(posedge clk);
    //sValid = 0;

    // Wait for remaining FSM operations
    repeat(200) @(posedge clk);
	 reset =1'b1;
    repeat(2) @(posedge clk);
    $finish;
end

endmodule
