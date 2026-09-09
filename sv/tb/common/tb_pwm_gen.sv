// -------------------------------------------------------------------------
// File: Testbench for a PWM Generator
// Author: Danknight
// -------------------------------------------------------------------------

module tb_pwm_gen #(
    parameter int unsigned CNT_W         = 8,
    parameter int unsigned NUM_CH        = 1,
    parameter bit          PHASE_CORRECT = 1'b0
);

    // -------------------------------------------------------------------------
    // Other signals
    // -------------------------------------------------------------------------
    logic                           clk_i;
    logic                           rst_ni;
    logic                           en_i;
    logic [CNT_W-1:0]               period_i;
    logic [NUM_CH-1:0][CNT_W-1:0]   duty_i;
    logic [NUM_CH-1:0]              pwm_o;
    logic                           period_tick_o;


    // -------------------------------------------------------------------------
    // Module instantiation
    // -------------------------------------------------------------------------
    pwm_gen #(
        .CNT_W          (         CNT_W ),
        .NUM_CH         (        NUM_CH ),
        .PHASE_CORRECT  ( PHASE_CORRECT )
    ) i_pwm_gen (
        .clk_i          ( clk_i         ),
        .rst_ni         ( rst_ni        ),
        .en_i           ( en_i          ),
        .period_i       ( period_i      ),
        .duty_i         ( duty_i        ),
        .pwm_o          ( pwm_o         ),
        .period_tick_o  ( period_tick_o )
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
    // Note that the test is for 1 channel only
    // -------------------------------------------------------------------------
    initial begin
        // Initialize all signals
        rst_ni   = 1'b0;
        en_i     = 1'b0;
        period_i = '0;
        for (int ch = 0; ch < NUM_CH; ch++) begin
            duty_i[ch] = '0;
        end

        // Release reset after 3 clk periods
        repeat(3) @(posedge clk_i);
        assert(pwm_o  == {NUM_CH{1'b0}}) else $fatal("TC-01 failed: pwm_o != 0");
        assert(period_tick_o == 1'b0)    else $fatal("TC-01 failed: period_tick_o != 0");
        $display("TC-01: PASS - values after reset");

        // Release reset but in this case keep en_i = 0
        rst_ni    = 1'b1;
        period_i  = 7;
        duty_i[0] = 4;
        repeat(20) @(posedge clk_i);
        assert(pwm_o  == {NUM_CH{1'b0}}) else $fatal("TC-02 failed: pwm_o != 0");
        assert(period_tick_o == 1'b0)    else $fatal("TC-02 failed: period_tick_o != 0");
        $display("TC-02: PASS - values with en_i = 0");

        // Test when duty_i = 0
        en_i     = 1'b1;
        duty_i[0] = 0;
        repeat(3) @(posedge clk_i);
        assert(pwm_o  == {NUM_CH{1'b0}}) else $fatal("TC-03 failed: pwm_o != 0");
        $display("TC-03: PASS - values with duty_i = 0");

        // Intermediate reset first
        en_i = 1'b0;
        rst_ni = 1'b0;
        repeat(3) @(posedge clk_i);

        // Test when duty_i = 8
        en_i = 1'b1;
        rst_ni = 1'b1;
        duty_i[0] = 8;
        // Wait for one clock cycle after setting duty_i[0] = 8
        @(posedge clk_i);
        for (int i = 0; i < 10; i++) begin
            @(posedge clk_i);
            assert(pwm_o == {NUM_CH{1'b1}}) else $fatal("TC-04 failed: pwm_o != 1");
        end
        $display("TC-04: PASS - values with duty_i = 8");

        // Intermediate reset first
        en_i = 1'b0;
        rst_ni = 1'b0;
        repeat(3) @(posedge clk_i);

        // Test when duty_i = 4
        en_i = 1'b1;
        rst_ni = 1'b1;
        duty_i[0] = 4;
        // Wait for one clock cycle after setting duty_i[0] = 4
        @(posedge clk_i);
        // Experiment on 3 periods
        for (int i = 0; i < 3; i++) begin
            // 4 high outputs
            for (int j = 0; j < 4; j++) begin
                @(posedge clk_i);
                assert(pwm_o == {NUM_CH{1'b1}}) else $fatal("TC-05 failed: pwm_o != 1");
            end
            // 4 low outputs
            for (int j = 0; j < 4; j++) begin
                @(posedge clk_i);
                assert(pwm_o == {NUM_CH{1'b0}}) else $fatal("TC-05 failed: pwm_o != 0");
            end
        end
        $display("TC-05: PASS - values with duty_i = 4");
        
        // Disclaimer
        $display("Disclaimer: Other tests will be done in the future");
        $display("For center-aligned mode, we need a separate testbench");
        $finish;
    end
endmodule