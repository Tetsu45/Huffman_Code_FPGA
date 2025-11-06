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
    output            tvalid
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
    // Shift Register Logic
    //--------------------------------------------------------
    integer i;
    assign tvalid = (fsm_tvalid) ? 1'b1 : 1'b0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            shift_buf    <= {MAX_CODE{1'b0}};
            bit_count    <= 4'd0;
            //buffer_ready <= 1'b0;
            decodedData  <= 4'd0;
        end else begin
            // Load bits when FSM requests
            if (load_bits && (bit_count + in_len <= MAX_CODE)) begin
                for (i = 0; i < in_len; i = i + 1)
                    shift_buf[bit_count + i] <= in_bits[in_len - 1 - i];
                bit_count <= bit_count + in_len;
            end
            // Shift bits when FSM indicates
            else if (shift_en && (bit_count >= shift_len)) begin
                for (i = 0; i < MAX_CODE; i = i + 1)
                    if (i + shift_len < MAX_CODE)
                        shift_buf[i] <= shift_buf[i + shift_len];
                    else
                        shift_buf[i] <= 1'b0;
                bit_count <= bit_count - shift_len;
            end

            // FSM decoded output latch
            if (tvalid)
                decodedData <= match_symbol;

            // Buffer readiness flag
            //buffer_ready <= (bit_count >= MIN_SAFE_BITS);
        end
    end
endmodule
