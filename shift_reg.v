//============================================================
// shift_reg.v — Top-level with internal FSM instantiation
//============================================================
`timescale 1ns/1ps
module shift_reg #(
    parameter MAX_CODE = 9,
    parameter MIN_SAFE_BITS = 3
)(
    input  wire             clk,
    input  wire             reset,
    input  wire [3:0]       in_bits,
    input  wire [2:0]       in_len,
    input  wire             sValid,
    // Final decoded outputs
    output reg  signed [3:0] decodedData,
    output wire             tvalid
    //output reg               buffer_ready
);
    //--------------------------------------------------------
    // Internal signals
    //--------------------------------------------------------
    reg  [MAX_CODE-1:0] shift_buf;
    reg  [3:0]          bit_count;
    wire                load_bits;
    wire                shift_en;
    wire [3:0]          shift_len;
    wire                aready;

    // internal handshake and match info
    wire match_flag;
    wire signed [3:0] match_symbol;
    wire [3:0] match_len;
    wire fsm_tvalid; 
    wire fsm_svalid;

    assign fsm_svalid = sValid;

    //--------------------------------------------------------
    // FSM Instantiation
    //--------------------------------------------------------
    decoder_fsm #(
        .MAX_CODE(MAX_CODE)
    ) u_fsm (
        .clk(clk),
        .reset(reset),
        .svalid(fsm_svalid),
        .in_data(in_bits),
        .in_len(in_len),
        .aready(aready),
        .load_bits(load_bits),
        .shift_en(shift_en),
        .shift_len(shift_len),
        .shift_buf(shift_buf),
        .bit_count(bit_count),
        .decodedData(match_symbol),
        .tvalid(fsm_tvalid)
    );

    //--------------------------------------------------------
    // Valid Window (Aligned Bit View)
    //--------------------------------------------------------
    reg [MAX_CODE-1:0] valid_window;

    always @(*) begin
        // Generate the left-aligned valid bits view (no false zeros)
        valid_window = shift_buf << (MAX_CODE - bit_count);
    end

    //--------------------------------------------------------
    // Shift Register Logic
    //--------------------------------------------------------
    integer i;
    assign tvalid = fsm_tvalid;

    // Mask to keep only 'in_len' valid bits
    reg [MAX_CODE-1:0] in_masked;

    // ==========================================================
    // Barrel-shift style bit buffer (Quartus-safe Verilog-2001)
    // ==========================================================
    always @(posedge clk or posedge reset) begin
    if (reset) begin
        shift_buf   <= {MAX_CODE{1'b0}};
        bit_count   <= 0;
        decodedData <= 0;
    end else begin
        // -----------------------------
        // Load new bits into buffer
        // -----------------------------
        if (load_bits && (bit_count + in_len <= MAX_CODE)) begin
            in_masked = in_bits & ((1 << in_len) - 1); // keep only valid input bits

            if (bit_count == 0) begin
                // Buffer empty → load at MSB downward
                shift_buf <= in_masked << (MAX_CODE - in_len);
            end else begin
                // Buffer has bits → append after existing valid bits
                // Existing bits occupy [MAX_CODE-1 : MAX_CODE-bit_count]
                shift_buf <= shift_buf | (in_masked << (MAX_CODE - bit_count - in_len));
            end

            bit_count <= bit_count + in_len;
        end

        // -----------------------------
        // Shift bits out (MSB side)
        // -----------------------------
        else if (shift_en && (bit_count >= shift_len)) begin
            shift_buf <= shift_buf << shift_len;
            bit_count <= bit_count - shift_len;
        end

        // -----------------------------
        // FSM decoded output latch
        // -----------------------------
        if (tvalid)
            decodedData <= match_symbol;
    end
end
endmodule
