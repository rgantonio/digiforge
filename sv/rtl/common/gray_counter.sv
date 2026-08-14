//--------------------------
// Simple gray and binary counter
//
// Author: Danknight <rgantonio@github.com>
//--------------------------

module gray_counter #(
    parameter int CNT_W = 4
)(
    input  logic                    clk_i,
    input  logic                    rst_ni,
    input  logic                    en_i,
    output logic [CNT_W-1:0]        bin_cnt_o,
    output logic [CNT_W-1:0]        gray_cnt_o,
    output logic                    rollover_o
);

    logic [CNT_W-1:0] next_bin;
    logic [CNT_W-1:0] next_gray;
    logic             next_rollover;

    assign next_bin = bin_cnt_o + 1;
    assign next_gray = (next_bin >> 1) ^ next_bin;
    assign next_rollover = en_i && (bin_cnt_o == {CNT_W{1'b1}});

    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bin_cnt_o  <= '0;
            gray_cnt_o <= '0;
            rollover_o <= 1'b0;
        end else begin
            // Indpendent from en_i
            rollover_o <= next_rollover;
            // Update counters only if enabled
            if (en_i) begin
                bin_cnt_o  <= next_bin;
                gray_cnt_o <= next_gray;
            end
        end
    end

endmodule
