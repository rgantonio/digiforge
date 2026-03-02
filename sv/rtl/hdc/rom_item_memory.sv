//-------------------------
// Item Memory Module
// Author: Danknight
//-------------------------

module rom_item_memory #(
  parameter int unsigned DimensionSize = 128,
  parameter int unsigned NumItems      = 1024,
  parameter int unsigned AddrWidth     = $clog2(NumItems)
)(
  input  logic clk_i,
  input  logic rst_ni,
  input  logic wr_en_i,
  input  logic [DimensionSize-1:0] data_i,
  input  logic [    AddrWidth-1:0] addr_i,
  output logic [DimensionSize-1:0] item_o
);

  // ROM declaration
  logic [DimensionSize-1:0] rom [0:NumItems-1];

  // Write logic (for initialization)
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      // Reset all values to 0
      for (int i = 0; i < NumItems; i++) begin
        rom[i] <= {DimensionSize{1'b0}};
      end
    end else if (wr_en_i) begin
      rom[addr_i] <= data_i;
    end
  end

  // Read logic
  assign item_o = rom[addr_i];

endmodule