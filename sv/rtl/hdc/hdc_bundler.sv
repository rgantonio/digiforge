//-------------------------
// HDC Bundler Modules
//-------------------------
`include "registers.svh"

module unit_bundler #(
  parameter int unsigned DataWidth = 8
)(
  input  logic                        clk_i,
  input  logic                        rst_ni,
  input  logic                        clr_i,
  input  logic                        data_valid_i,
  input  logic                        data_i,
  output logic signed [DataWidth-1:0] bundler_data_o,
  output logic                        bundler_data_bin_o
);

  // Wire declaration
  logic signed [DataWidth-1:0] bundler_q, bundler_d;

  // Register declarations
  `RegAsyncNrst(bundler_q, bundler_d, {DataWidth{1'b0}});

  // Next state logic
  always_comb begin
    if (clr_i) begin
      // Clear the register
      bundler_d = {DataWidth{1'b0}};
    end else if (data_valid_i) begin
      if(data_i) begin
        // Count up
        bundler_d = bundler_q + 1;
      end else begin
        // Count down
        bundler_d = bundler_q - 1;
      end
    end else begin
      // Retain state
      bundler_d = bundler_q;
    end
  end

  // Output assignments
  assign bundler_data_o = bundler_q;
  assign bundler_data_bin_o = (bundler_q >= 0);

endmodule