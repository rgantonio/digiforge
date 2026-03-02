//--------------------------
// A simple fully-combinational one-hot encoder
//
// Author: Danknight <rgantonio@github.com>
//--------------------------

module one_hot_encoder #(
  parameter int unsigned OUTPUT_WIDTH = 16,
  // Don't touch
  parameter int unsigned INPUT_WIDTH  = $clog2(OUTPUT_WIDTH)
)(
  input  logic [ INPUT_WIDTH-1:0] value_i,
  input  logic                    en_out_i,
  output logic [OUTPUT_WIDTH-1:0] code_o
);

  always_comb begin
    for (int i = 0; i <  OUTPUT_WIDTH; i++) begin
      code_o[i] = (value_i == i) ? 1'b1 & en_out_i : 1'b0;
    end
  end

endmodule