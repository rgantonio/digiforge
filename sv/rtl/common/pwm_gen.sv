//--------------------------
// A specific WPM generator
//
// Parameterized PWM generator.
//   - Edge-aligned or center-aligned, selected by PHASE_CORRECT
//   - NUM_CH channels sharing one counter
//   - Shadow-registered period and duty (updated at end of period)
//   - pwm_o and period_tick_o are registered, so both lag the
//     internal counter by exactly one cycle
//
// Author: Danknight <rgantonio@github.com>
//--------------------------

module pwm_gen #(
    parameter int unsigned CNT_W         = 8,
    parameter int unsigned NUM_CH        = 1,
    parameter bit          PHASE_CORRECT = 1'b0
)(
    input  logic                          clk_i,
    input  logic                          rst_ni,
    input  logic                          en_i,
    input  logic [CNT_W-1:0]              period_i,
    input  logic [NUM_CH-1:0][CNT_W-1:0]  duty_i,
    output logic [NUM_CH-1:0]             pwm_o,
    output logic                          period_tick_o
);

    // -------------------------------------------------------------
    // State
    // -------------------------------------------------------------
    logic [CNT_W-1:0]             cnt_q,  cnt_d;
    logic                         dir_q,  dir_d;   // 0 = up, 1 = down
    logic [CNT_W-1:0]             period_q;
    logic [NUM_CH-1:0][CNT_W-1:0] duty_q;
    logic [NUM_CH-1:0]            pwm_q,  pwm_d;

    logic end_of_period;
    logic reload;

    // -------------------------------------------------------------
    // 1 - end-of-period detection (R5)
    //
    //   Edge-aligned : cnt_q >= period_q
    //   Center       : (dir_q == down && cnt_q == 1) || period_q == 0
    //   Both         : must be 0 when en_i is low
    //
    //   Use generate/if on PHASE_CORRECT so the unused branch is
    //   removed at elaboration rather than muxed at runtime.
    // -------------------------------------------------------------
    generate
        if (PHASE_CORRECT) begin: gen_center_aligned
            // Center-aligned PWM logic here
            assign end_of_period = ((dir_q == 1'b1 && cnt_q == 1) || period_q == 0) && en_i;
        end else begin: gen_edge_aligned
            // Edge-aligned PWM logic here
            assign end_of_period = (cnt_q >= period_q) && en_i;
        end
    endgenerate

    // Reload for shadow counters
    assign reload = end_of_period | ~en_i;


    // -------------------------------------------------------------
    // 2 - counter and direction next-state (R3, R4)
    //
    //   Edge   : wrap to 0 on end_of_period, otherwise increment
    //   Center : up until cnt_q reaches period_q, then flip;
    //            down until cnt_q reaches 1, then go to 0 and flip
    //   Center degenerate: period_q == 0 holds cnt at 0, dir at up
    // -------------------------------------------------------------
    always_comb begin
        cnt_d = cnt_q;
        dir_d = dir_q;
        if (!en_i) begin
            cnt_d = {CNT_W{1'b0}};
            dir_d = 1'b0;
        end else begin
            if (PHASE_CORRECT) begin
                if (period_q == 0) begin
                    cnt_d = {CNT_W{1'b0}};
                    dir_d = 1'b0;
                end else begin
                    if(dir_q == 1'b0) begin
                        //Case when counting up
                        if (cnt_q == period_q) begin
                            cnt_d = cnt_q - 1;
                            dir_d = 1'b1;
                        end else begin
                            cnt_d = cnt_q + 1;
                            dir_d = 1'b0;
                        end
                    end else begin
                        //Case when counting down
                        if (cnt_q == 1) begin
                            cnt_d = {CNT_W{1'b0}};
                            dir_d = 1'b0;
                        end else begin
                            cnt_d = cnt_q - 1;
                            dir_d = 1'b1;
                        end
                    end
                end
            end else begin
                cnt_d = (end_of_period) ? {CNT_W{1'b0}} : (cnt_q + 1);
                dir_d = 1'b0;
            end
        end
    end

    // -------------------------------------------------------------
    // 3 - comparator array (R7, R8)  <-- the core of the exercise
    //
    //   Edge   : pwm_d[ch] = (cnt_q < duty_q[ch])
    //   Center : dir_q == up   ->  cnt_q <  duty_q[ch]
    //            dir_q == down ->  cnt_q <= duty_q[ch]
    //
    //   Compare against cnt_q and duty_q. Never against duty_i.
    //   Force to 0 when en_i is low.
    // -------------------------------------------------------------
    always_comb begin
        pwm_d = {NUM_CH{1'b0}};
        if (en_i) begin
            for (int ch = 0; ch < NUM_CH; ch++) begin
                if (PHASE_CORRECT) begin
                    if(dir_q == 1'b0) begin
                        pwm_d[ch] = (cnt_q < duty_q[ch]);
                    end else begin
                        pwm_d[ch] = (cnt_q <= duty_q[ch]);
                    end
                end else begin
                    pwm_d[ch] = (cnt_q < duty_q[ch]);
                end
            end
        end
        // No need for else since default is at the top
    end

    // -------------------------------------------------------------
    // Registers
    // -------------------------------------------------------------
    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if(!rst_ni) begin
            cnt_q           <= {CNT_W{1'b0}};
            dir_q           <= 1'b0;
            period_q        <= {CNT_W{1'b0}};
            pwm_q           <= {NUM_CH{1'b0}};
            period_tick_o   <= 1'b0;
            for (int ch = 0; ch < NUM_CH; ch++) begin
                duty_q[ch] <= {CNT_W{1'b0}};
            end
        end else begin
            cnt_q           <= cnt_d;
            dir_q           <= dir_d;
            pwm_q           <= pwm_d;
            period_tick_o   <= end_of_period;
            if(reload) begin
                period_q <= period_i;
                for (int ch = 0; ch < NUM_CH; ch++) begin
                    duty_q[ch] <= duty_i[ch];
                end
            end else begin
                period_q <= period_q;
                for (int ch = 0; ch < NUM_CH; ch++) begin
                    duty_q[ch] <= duty_q[ch];
                end
            end
        end
    end

    // Output of phase width modulation
    assign pwm_o = pwm_q;
endmodule

