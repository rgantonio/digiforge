//--------------------------
// Simple flip-flop synchronizer
// This is mainly used for clock domain crossings
// Whether it is fast or slow, the direction is always
// given by the source and destination
//
// Author: Danknight <rgantonio@github.com>
//--------------------------

module sync_ff #(
  parameter int unsigned SYNC_WIDTH = 1,
  parameter int unsigned RESET_VAL  = 0
)(
  input  logic clk_i,
  input  logic rst_ni,
  input  logic data_i,
  output logic data_o
);

  // Registers and wires
  logic [SYNC_WIDTH-1:0] sync_reg;
  
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_reg <= RESET_VAL;
    end else begin
      sync_reg <= {sync_reg[SYNC_WIDTH-2:0], data_i};
    end
  end

  // Assign output
  assign data_o = sync_reg[SYNC_WIDTH-1];

endmodule