//============================================================
// case_decoder.v — Huffman Code Comparator for -8..+7
//============================================================
`timescale 1ns/1ps
module case_decoder #(
    parameter MAX_CODE = 9
)(
    input  wire [MAX_CODE-1:0] shift_buf,
    input  wire [3:0]          bit_count,
    output reg                 match_flag,
    output reg [3:0]           match_symbol,
    output reg [3:0]           match_len
);
    always @(*) begin
        match_flag   = 1'b0;
        match_symbol = 4'd0;
        match_len    = 4'd0;

        if (bit_count > 0) begin
            casez (shift_buf[MAX_CODE-1:MAX_CODE-9])
                9'b0????????:     begin match_flag=1; match_symbol=4'sd0;  match_len=4'd1; end
                9'b100??????:     begin match_flag=1; match_symbol=4'sd1;  match_len=4'd3; end
                9'b1010?????:     begin match_flag=1; match_symbol=-4'sd3; match_len=4'd4; end
                9'b10111????:     begin match_flag=1; match_symbol=-4'sd4; match_len=4'd5; end
                9'b101101???:     begin match_flag=1; match_symbol=-4'sd5; match_len=4'd6; end
                9'b1011000??:     begin match_flag=1; match_symbol=-4'sd6; match_len=4'd7; end
                9'b1011001??:     begin match_flag=1; match_symbol=4'sd6;  match_len=4'd7; end
                9'b1100?????:     begin match_flag=1; match_symbol=4'sd2;  match_len=4'd4; end
                9'b1101?????:     begin match_flag=1; match_symbol=-4'sd2; match_len=4'd4; end
                9'b1110?????:     begin match_flag=1; match_symbol=-4'sd1; match_len=4'd4; end
                9'b11110????:     begin match_flag=1; match_symbol=4'sd3;  match_len=4'd5; end
                9'b1111101??:     begin match_flag=1; match_symbol=4'sd5;  match_len=4'd7; end
                9'b111111???:     begin match_flag=1; match_symbol=4'sd4;  match_len=4'd6; end
                9'b11111000?:     begin match_flag=1; match_symbol=-4'sd7; match_len=4'd8; end
                9'b111110010:     begin match_flag=1; match_symbol=-4'sd8; match_len=4'd9; end
                9'b111110011:     begin match_flag=1; match_symbol=4'sd7;  match_len=4'd9; end
                default:          match_flag=0;
            endcase
        end
    end
endmodule
