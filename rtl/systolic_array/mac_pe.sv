//--------------------------
// Simple MAC processing element
//
// Author: Danknight <rgantonio@github.com>
// Description:
// Contains input registers A and B, accepting inputs on a valid signal.
// Output is accumulates every cycle whenever A and B change.
// There is a clear signal to clear the output accumulation.
// There is a seperate clear signal for each input.
//--------------------------

module mac_pe #(
  parameter int unsigned DATA_WIDTH = 16,
  parameter int unsigned RESET_VAL  = 0
)(
  // Clock and reset
  input  logic                     clk_i,
  input  logic                     rst_ni,
  // Input operands
  input  logic [DATA_WIDTH-1:0]    a_i,
  input  logic [DATA_WIDTH-1:0]    b_i,
  // Valid signals for inputs
  input  logic                     a_valid_i,
  input  logic                     b_valid_i,
  // Clear signals for inputs
  input  logic                     a_clr_i,
  input  logic                     b_clr_i,
  // Input passed on to output registers
  output logic [DATA_WIDTH-1:0]    a_reg_o,
  output logic [DATA_WIDTH-1:0]    b_reg_o,
  // Clear signal for output
  input  logic                     acc_clr_i,
  // Output accumulation
  output logic [DATA_WIDTH-1:0]    acc_o
);

  // Logic for accumulation update
  logic acc_valid;
  assign acc_valid = a_valid_i || b_valid_i;

  // Input control
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      a_reg_o <= '0;
      b_reg_o <= '0;
    end else begin
      // For input a
      if (a_clr_i) begin
        a_reg_o <= '0;
      end else if (a_valid_i) begin
        a_reg_o <= a_i;
      end else begin
        a_reg_o <= a_reg_o;
      end

      // For input b
      if (b_clr_i) begin
        b_reg_o <= '0;
      end else if (b_valid_i) begin
        b_reg_o <= b_i;
      end else begin
        b_reg_o <= b_reg_o;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      acc_o <= RESET_VAL;
    end else if (acc_clr_i) begin
      acc_o <= RESET_VAL;
    end else if (acc_valid) begin
      acc_o <= acc_o + (a_i * b_i);
    end else begin
      acc_o <= acc_o;
    end
  end


endmodule