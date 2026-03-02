//--------------------------
// MAC Array Testbench
//
// Author: Danknight <rgantonio@github.com>
//--------------------------

module tb_mac_array;

  // Parameters
  parameter int unsigned DATA_WIDTH = 16;
  parameter int unsigned RESET_VAL  = 0;
  parameter int unsigned M_ROWS     = 5;
  parameter int unsigned N_COLS     = M_ROWS;
  // Don't touch these parameters
  parameter int unsigned PE_COUNT   = M_ROWS * N_COLS;

  // Inputs
  logic clk_i;
  logic rst_ni;
  logic [M_ROWS-1:0][DATA_WIDTH-1:0] array_a_i;
  logic [N_COLS-1:0][DATA_WIDTH-1:0] array_b_i;
  logic feed_a_valid_i, feed_b_valid_i;
  logic a_clr_i, b_clr_i, acc_clr_i;
  
  // Outputs
  logic [PE_COUNT-1:0][DATA_WIDTH-1:0] array_out_o;

  // Internal signals for checking purposes
  logic [M_ROWS-1:0][N_COLS-1:0][DATA_WIDTH-1:0] track_acc_out;
  logic [M_ROWS-1:0][N_COLS-1:0][DATA_WIDTH-1:0] track_a_reg;
  logic [M_ROWS-1:0][N_COLS-1:0][DATA_WIDTH-1:0] track_b_reg;

  // Include some common tasks
  `include "common_tasks.sv"
  `include "systolic_array_tasks.sv"
  
  // Instantiate the MAC PE module
  mac_array #(
    .DATA_WIDTH      ( DATA_WIDTH     ),
    .RESET_VAL       ( RESET_VAL      ),
    .M_ROWS          ( M_ROWS         ),
    .N_COLS          ( N_COLS         )
  ) i_mac_array (
    .clk_i           ( clk_i          ),
    .rst_ni          ( rst_ni         ),
    .array_a_i       ( array_a_i      ),
    .array_b_i       ( array_b_i      ),
    .feed_a_valid_i  ( feed_a_valid_i ),
    .feed_b_valid_i  ( feed_b_valid_i ),
    .a_clr_i         ( a_clr_i        ),
    .b_clr_i         ( b_clr_i        ),
    .acc_clr_i       ( acc_clr_i      ),
    .array_out_o     ( array_out_o    )
  );

  // Clock generation
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i; // Toggle clock every 5 time units
  end

  // Test sequence
  initial begin
    $dumpfile("tb_mac_array.vcd");
    $dumpvars(0, tb_mac_array);

    // Initialize inputs
    clk_i     = 0;
    rst_ni    = 0;
    array_a_i = '{default: '0};
    array_b_i = '{default: '0};
    feed_a_valid_i = 0;
    feed_b_valid_i = 0;
    a_clr_i   = 0;
    b_clr_i   = 0;
    acc_clr_i = 0;

    init_zero_arrays();

    clk_delay(3);

    // Release reset
    #1; rst_ni = 1;

    clk_delay(3);

    for (int i = 0; i < M_ROWS; i++) begin
      rand_gen_array_a();
      rand_gen_array_b();
      feed_tracker_a();
      feed_tracker_b();
      update_acc_tracker();
      feed_a_valid_i = 1;
      feed_b_valid_i = 1;
      clk_delay(1);
    end

    // Disable feeding
    feed_a_valid_i = 0;
    feed_b_valid_i = 0;
    // Finish simulation after some time
    clk_delay(5);

    // Checking of results
    for (int i = 0; i < M_ROWS; i++) begin
      for (int j = 0; j < N_COLS; j++) begin
        if (array_out_o[i * N_COLS + j] !== track_acc_out[i][j]) begin
          $error("Mismatch at [%0d][%0d]: DUT = %0d, Expected = %0d",
                 i, j, array_out_o[i * N_COLS + j], track_acc_out[i][j]);
        end else begin
          $display("Match at [%0d][%0d]: %0d", i, j, array_out_o[i * N_COLS + j]);
        end
      end
    end

    $finish;
  end

endmodule