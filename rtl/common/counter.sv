//--------------------------
// Simple counter module
//
// Author: Danknight <rgantonio@github.com>
//--------------------------

module counter #(
  parameter COUNTER_WIDTH = 8,
  parameter RESET_VAL     = 0
)(
  input  logic                     clk_i,
  input  logic                     rst_ni,
  input  logic                     clr_i,
  input  logic                     en_i,
  output logic [COUNTER_WIDTH-1:0] count_o
);

  logic [COUNTER_WIDTH-1:0] count;
  

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      count <= RESET_VAL;
    end else if (en_i) begin
      if (clr_i) begin
        count <= '0;
      end else begin
        count <= count + 1;
      end
    end
  end

  assign count_o = count;

endmodule