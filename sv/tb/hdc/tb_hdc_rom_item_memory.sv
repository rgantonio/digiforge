//-------------------------
// Testbench for ROM item memory
//-------------------------

module tb_hdc_rom_item_memory;

  // Working parameters
  localparam int unsigned DimensionSize = 128;
  localparam int unsigned NumItems      = 1024;
  localparam int unsigned AddrWidth     = $clog2(NumItems);

  // Wires and drivers
  logic                     clk_i;
  logic                     rst_ni;
  logic                     wr_en_i;
  logic [DimensionSize-1:0] data_i;
  logic [    AddrWidth-1:0] addr_i;
  logic [DimensionSize-1:0] item_o;

  // Include some common tasks
  `include "common_tasks.sv"

  // Instantiate the Unit ROM item memory
  rom_item_memory #(
    .DimensionSize ( DimensionSize ),
    .NumItems      ( NumItems      ),
    .AddrWidth     ( AddrWidth     )
  ) dut (
    .clk_i         ( clk_i         ),
    .rst_ni        ( rst_ni        ),
    .wr_en_i       ( wr_en_i       ),
    .data_i        ( data_i        ),
    .addr_i        ( addr_i        ),
    .item_o        ( item_o        )
  );

  // Clock
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i; // Toggle clock every 5 time units
  end
  
  // Drivers
  int test_passed = 1;
  initial begin
    // Initial values
    rst_ni = 0;
    wr_en_i = 0;
    data_i = 0;
    addr_i = 0;

    clk_delay(3);

    // Reset the ROM
    rst_ni = 1;
    clk_delay(3);

    // Write some values to the ROM
    for (int i = 0; i < NumItems; i++) begin
      wr_en_i = 1;
      data_i = i; // Just writing the index as data for testing
      addr_i = i;
      clk_delay(1);
    end

    // Read back and verify values
    for (int i = 0; i < NumItems; i++) begin
      wr_en_i = 0; // Disable write for reading
      addr_i = i;
      clk_delay(1);
      assert (item_o === i) else begin
        $display("Test failed at address %0d: expected %0d, got %0d", i, i, item_o);
        test_passed = 0;
      end
    end

    if (test_passed) begin
      $display("All tests passed!");
    end

    $finish;
  end

endmodule