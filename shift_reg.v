
//============================================================
// shift_reg.v — Compatible with Optimized Decoder FSM
//============================================================
module shift_reg #(
    parameter MAX_CODE = 9
)(
    input  wire             clk,
    input  wire             reset,

    // Load bits from input source
    input  wire             load_bits,       // FSM pulse to append new bits
    input  wire [3:0]       in_bits,         // up to 4 bits from stream (LSB = newest)
    input  wire [2:0]       in_len,          // number of valid bits in in_bits

    // Remove bits after successful decode
    input  wire             shift_en,        // FSM pulse to drop matched bits
    input  wire [3:0]       shift_len,       // number of bits to remove

    // Outputs
    output reg [MAX_CODE-1:0] shift_buf,     // buffer content for case_decoder
    output reg [3:0]          bit_count      // how many bits are valid
);

 always @(posedge clk or posedge reset) begin
    if (reset) begin
        shift_buf <= {MAX_CODE{1'b0}};
        bit_count <= 4'd0;
    end else begin
        // --- Load new bits into the buffer ---
        if (load_bits && (bit_count + in_len <= MAX_CODE)) begin
            case (in_len)
                3'd1: begin
                    shift_buf <= (shift_buf << 1) | {8'd0, in_bits[0]};
                    bit_count <= bit_count + 3'd1;
                end
                3'd2: begin
                    shift_buf <= (shift_buf << 2) | {7'd0, in_bits[1:0]};
                    bit_count <= bit_count + 3'd2;
                end
                3'd3: begin
                    shift_buf <= (shift_buf << 3) | {6'd0, in_bits[2:0]};
                    bit_count <= bit_count + 3'd3;
                end
                3'd4: begin
                    shift_buf <= (shift_buf << 4) | {5'd0, in_bits[3:0]};
                    bit_count <= bit_count + 3'd4;
                end
                default: begin
                    // in_len = 0, do nothing
                    shift_buf <= shift_buf;
                    bit_count <= bit_count;
                end
            endcase
        end
        // --- Shift out decoded bits ---
        else if (shift_en && (bit_count >= shift_len)) begin
            case (shift_len)
                4'd1: shift_buf <= shift_buf << 1;
                4'd2: shift_buf <= shift_buf << 2;
                4'd3: shift_buf <= shift_buf << 3;
                4'd4: shift_buf <= shift_buf << 4;
                4'd5: shift_buf <= shift_buf << 5;
                4'd6: shift_buf <= shift_buf << 6;
                4'd7: shift_buf <= shift_buf << 7;
                4'd8: shift_buf <= shift_buf << 8;
                4'd9: shift_buf <= shift_buf << 9;
                default: shift_buf <= shift_buf;
            endcase
            bit_count <= bit_count - shift_len;
        end
    end
end
endmodule