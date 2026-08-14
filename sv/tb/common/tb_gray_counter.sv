// -------------------------------------------------------------------------
// File: Testbench for a Binary-Gray Counter
// Author: Danknight
// -------------------------------------------------------------------------

module tb_gray_counter #(
    parameter int CNT_W = 4
);

    // -------------------------------------------------------------------------
    // Other signals
    // -------------------------------------------------------------------------
    logic                   clk_i;
    logic                   rst_ni;
    logic                   en_i;
    logic [CNT_W-1:0]       bin_cnt_o;
    logic [CNT_W-1:0]       gray_cnt_o;
    logic                   rollover_o;

    // Output saves
    logic [CNT_W-1:0]       bin_cnt_save;
    logic [CNT_W-1:0]       gray_cnt_save;

    // -------------------------------------------------------------------------
    // Some useful tasks
    // -------------------------------------------------------------------------

    // -------------------------------------------------------------------------
    // Module instantiation
    // -------------------------------------------------------------------------
    gray_counter #(
        .CNT_W      (CNT_W      )
    ) i_gray_counter (
        .clk_i      (clk_i      ),
        .rst_ni     (rst_ni     ),
        .en_i       (en_i       ),
        .bin_cnt_o  (bin_cnt_o  ),
        .gray_cnt_o (gray_cnt_o ),
        .rollover_o (rollover_o )
    );

    // -------------------------------------------------------------------------
    // Always block for clock generation
    // -------------------------------------------------------------------------
    initial begin
        clk_i = 0;
        forever #5 clk_i = ~clk_i; // 100 MHz clock
    end

    // -------------------------------------------------------------------------
    // Test and Stimuli
    // -------------------------------------------------------------------------
    initial begin
        // Initialize all signals
        rst_ni = 1'b0;
        en_i   = 1'b0;

        // Release reset after 2 clk periods
        repeat(2) @(posedge clk_i);

        rst_ni = 1'b1;

        // TC-01: Reset behavior — assert rst_ni low for one cycle;
        // verify bin_cnt_o, gray_cnt_o, and rollover_o all read 0 on the following edge.
        @(posedge clk_i);
        assert(bin_cnt_o  ==   '0) else $fatal("TC-01 failed: bin_cnt_o != 0");
        assert(gray_cnt_o ==   '0) else $fatal("TC-01 failed: gray_cnt_o != 0");
        assert(rollover_o == 1'b0) else $fatal("TC-01 failed: rollover_o != 0");

        // TC-02: Enable gating — hold en_i low for several cycles;
        // verify both counters remain constant and do not advance.
        @(posedge clk_i);
        en_i = 1'b1;
        repeat ($urandom_range(1, 2**(CNT_W-1))) @(posedge clk_i);
        en_i = 1'b0;
        @(posedge clk_i);
        bin_cnt_save = bin_cnt_o;
        gray_cnt_save = gray_cnt_o;
        repeat ($urandom_range(1, 2**(CNT_W-1))) @(posedge clk_i);
        assert(bin_cnt_o == bin_cnt_save) else
        $fatal("TC-02 failed: bin_cnt_o (%0d) != bin_cnt_save (%0d)", bin_cnt_o, bin_cnt_save);
        assert(gray_cnt_o == gray_cnt_save) else
        $fatal("TC-02 failed: gray_cnt_o (%0d) != gray_cnt_save (%0d)", gray_cnt_o, gray_cnt_save);

        // TC-03: Verify binary and gray counting with complete wrap-around

        // Reset back to 0
        rst_ni = 1'b0;
        @(posedge clk_i);
        rst_ni = 1'b1;
        en_i = 1'b1;
        @(posedge clk_i);

        // Count normally
        for (int i = 0; i < 2**CNT_W; i++) begin
            $display("TC-03: i=%0d, bin_cnt_o=%0d, gray_cnt_o=%0d", i, bin_cnt_o, gray_cnt_o);
            assert(bin_cnt_o == i) else
            $fatal("TC-03 failed: bin_cnt_o (%0d) != expected (%0d)", bin_cnt_o, i);
            assert(gray_cnt_o == ((i >> 1) ^ i)) else
            $fatal("TC-03 failed: gray_cnt_o (%0d) != expected (%0d)", gray_cnt_o, ((i >> 1) ^ i));
            @(posedge clk_i);
        end

        // TC-04: Verify rollover_o is asserted for one cycle when the counter wraps around
        assert(rollover_o == 1'b1) else $fatal("TC-04 failed: rollover_o != 1 at wrap-around");
        @(posedge clk_i);
        assert(rollover_o == 1'b0) else $fatal("TC-04 failed: rollover_o != 0 after wrap-around");

        // Trailing cycles
        repeat (5) @ (posedge clk_i);
        $finish;
    end

endmodule