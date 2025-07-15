//--------------------------
// Simple MAC processing array
//
// Author: Danknight <rgantonio@github.com>
// Description:
// We have M - A inputs and N - B inputs.
// We can feed A from the left and feed B from the top.
//--------------------------

module mac_array #(
  parameter int unsigned DATA_WIDTH = 16,
  parameter int unsigned RESET_VAL  = 0,
  parameter int unsigned M_ROWS     = 4,
  parameter int unsigned N_COLS     = 4,
  // Don't touch these parameters
  parameter int unsigned PE_COUNT   = M_ROWS * N_COLS
)(
  // Clock and reset
  input  logic                                clk_i,
  input  logic                                rst_ni,
  // Input operands
  input  logic [  M_ROWS-1:0][DATA_WIDTH-1:0] array_a_i,
  input  logic [  N_COLS-1:0][DATA_WIDTH-1:0] array_b_i,
  // Valid signals for inputs
  input  logic                                feed_a_valid_i,
  input  logic                                feed_b_valid_i,
  // Clear signals for inputs
  input  logic                                a_clr_i,
  input  logic                                b_clr_i,
  // Clear signal for output
  input  logic                                acc_clr_i,
  // Output accumulation
  output logic [PE_COUNT-1:0][DATA_WIDTH-1:0] array_out_o
);

  // Internal signals for processing elements
  logic [M_ROWS-1:0][N_COLS-1:0][DATA_WIDTH-1:0] acc_out;
  logic [M_ROWS-1:0][N_COLS-1:0][DATA_WIDTH-1:0] a_reg;
  logic [M_ROWS-1:0][N_COLS-1:0][DATA_WIDTH-1:0] b_reg;

  // Instantiate processing elements
  genvar i, j;
  generate
    for (i = 0; i < M_ROWS; i++) begin : array_row
      for (j = 0; j < N_COLS; j++) begin : array_col
        // For the first row and column
        if (i == 0 && j == 0) begin: first_pe
          mac_pe #(
            .DATA_WIDTH ( DATA_WIDTH     ),
            .RESET_VAL  ( RESET_VAL      )
          ) i_mac_pe (
            .clk_i      ( clk_i          ),
            .rst_ni     ( rst_ni         ),
            .a_i        ( array_a_i[i]   ),
            .b_i        ( array_b_i[j]   ),
            .a_valid_i  ( feed_a_valid_i ),
            .b_valid_i  ( feed_b_valid_i ),
            .a_clr_i    ( a_clr_i        ),
            .b_clr_i    ( b_clr_i        ),
            .acc_clr_i  ( acc_clr_i      ),
            .a_reg_o    ( a_reg  [i][j]  ),
            .b_reg_o    ( b_reg  [i][j]  ),
            .acc_o      ( acc_out[i][j]  )
          );
        end else if (i==0) begin: first_row
          // For the first row, but not the first column
          mac_pe #(
            .DATA_WIDTH ( DATA_WIDTH     ),
            .RESET_VAL  ( RESET_VAL      )
          ) i_mac_pe (
            .clk_i      ( clk_i          ),
            .rst_ni     ( rst_ni         ),
            .a_i        ( a_reg[i][j-1]  ),
            .b_i        ( array_b_i[j]   ),
            .a_valid_i  ( feed_a_valid_i ),
            .b_valid_i  ( feed_b_valid_i ),
            .a_clr_i    ( a_clr_i        ),
            .b_clr_i    ( b_clr_i        ),
            .acc_clr_i  ( acc_clr_i      ),
            .a_reg_o    ( a_reg  [i][j]  ),
            .b_reg_o    ( b_reg  [i][j]  ),
            .acc_o      ( acc_out[i][j]  )
          );
        end else if (j==0) begin: first_col
          // For the first column, but not the first row
          mac_pe #(
            .DATA_WIDTH ( DATA_WIDTH     ),
            .RESET_VAL  ( RESET_VAL      )
          ) i_mac_pe (
            .clk_i      ( clk_i          ),
            .rst_ni     ( rst_ni         ),
            .a_i        ( array_a_i[i]   ),
            .b_i        ( b_reg[i-1][j]  ),
            .a_valid_i  ( feed_a_valid_i ),
            .b_valid_i  ( feed_b_valid_i ),
            .a_clr_i    ( a_clr_i        ),
            .b_clr_i    ( b_clr_i        ),
            .acc_clr_i  ( acc_clr_i      ),
            .a_reg_o    ( a_reg  [i][j]  ),
            .b_reg_o    ( b_reg  [i][j]  ),
            .acc_o      ( acc_out[i][j]  )
          );
        end else begin: inner_array
          mac_pe #(
            .DATA_WIDTH ( DATA_WIDTH     ),
            .RESET_VAL  ( RESET_VAL      )
          ) i_mac_pe (
            .clk_i      ( clk_i          ),
            .rst_ni     ( rst_ni         ),
            .a_i        ( a_reg[i][j-1]  ),
            .b_i        ( b_reg[i-1][j]  ),
            .a_valid_i  ( feed_a_valid_i ),
            .b_valid_i  ( feed_b_valid_i ),
            .a_clr_i    ( a_clr_i        ),
            .b_clr_i    ( b_clr_i        ),
            .acc_clr_i  ( acc_clr_i      ),
            .a_reg_o    ( a_reg  [i][j]  ),
            .b_reg_o    ( b_reg  [i][j]  ),
            .acc_o      ( acc_out[i][j]  )
          );
        end
      end
    end
  endgenerate

  // Output stream assignment
  always_comb begin
    for (int i = 0; i < M_ROWS; i++) begin
      for (int j = 0; j < N_COLS; j++) begin
        array_out_o[i * N_COLS + j] = acc_out[i][j];
      end
    end
  end

endmodule