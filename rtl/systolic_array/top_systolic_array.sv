//--------------------------
// Top-level Systolic Array
//
// Author: Danknight <rgantonio@github.com>
// Description:
// Contains the main MAC array in a systolic architecture.
// Then a stream-out module for outputting the results.
//--------------------------

module top_systolic_array #(
  parameter int unsigned DATA_WIDTH = 16,
  parameter int unsigned RESET_VAL  = 0,
  parameter int unsigned M_ROWS     = 4,
  parameter int unsigned N_COLS     = 4,
  // Don't touch these parameters
  parameter int unsigned TOTAL_ELEM = M_ROWS * N_COLS
)(
  // Clock and reset
  input  logic clk_i,
  input  logic rst_ni,
  // Input operands
  input  logic [M_ROWS-1:0][DATA_WIDTH-1:0] array_a_i,
  input  logic [N_COLS-1:0][DATA_WIDTH-1:0] array_b_i,
  // Valid signals for inputs
  input  logic feed_a_valid_i,
  input  logic feed_b_valid_i,
  // Clear signals for inputs
  input  logic a_clr_i,
  input  logic b_clr_i,
  // Clear signal for output
  input  logic acc_clr_i,
  // Stream control signals
  input  logic start_stream_i,
  input  logic stream_clr_i,
  // Output accumulation
  output logic stream_valid_o,
  output logic [DATA_WIDTH-1:0] stream_data_o
);

  // Wires
  logic [TOTAL_ELEM-1:0][DATA_WIDTH-1:0] bus_data;

  // Main MAC array
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
    .array_out_o     ( bus_data       )
  );

  // Stream Out Controller
  stream_out #(
    .DATA_WIDTH      ( DATA_WIDTH     ),
    .RESET_VAL       ( RESET_VAL      ),
    .TOTAL_ELEM      ( TOTAL_ELEM     )
  ) i_stream_out (
    .clk_i           ( clk_i          ),
    .rst_ni          ( rst_ni         ),
    .bus_data_i      ( bus_data       ),
    .start_stream_i  ( start_stream_i ),
    .stream_clr_i    ( stream_clr_i   ),
    .stream_data_o   ( stream_data_o  ),
    .stream_valid_o  ( stream_valid_o )
  );

endmodule