//-------------------------
// Testbench for HDC Bundler
//-------------------------

module tb_hdc_bundler;

  // Working parameters
  localparam int unsigned DimensionSize = 4;
  localparam int unsigned DataWidth = 8;

  // Test parameters
  localparam int unsigned NumTests = 5;

  // Wires and drivers
  logic                            clk_i;
  logic                            rst_ni;
  logic                            clr_i;
  logic                            data_valid_i;
  logic        [DimensionSize-1:0] data_i;
  logic signed [    DataWidth-1:0] bundler_data_o [DimensionSize];
  logic        [DimensionSize-1:0] bundler_data_bin_o;

  // Include some common tasks
  `include "common_tasks.sv"

  // Instantiate the Unit Bundler
  bundler #(
    .DimensionSize      ( DimensionSize      ),
    .DataWidth          ( DataWidth          )
  ) dut (
    .clk_i              ( clk_i              ),
    .rst_ni             ( rst_ni             ),
    .clr_i              ( clr_i              ),
    .data_valid_i       ( data_valid_i       ),
    .data_i             ( data_i             ),
    .bundler_data_o     ( bundler_data_o     ),
    .bundler_data_bin_o ( bundler_data_bin_o )
  );

  // Clock
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i; // Toggle clock every 5 time units
  end

  // Some variables
  int target_value;
  int current_value [DimensionSize];
  int bin_value [DimensionSize];
  int test_passed = 1;

  // Drivers
  initial begin
    // Initial values
    rst_ni = 0;
    clr_i = 0;
    data_valid_i = 0;
    data_i = 0;

    clk_delay(3);

    // Reset the counter
    #1; rst_ni = 1; // Assert reset

    clk_delay(3);

    
    // Iterating test
    for (int i = 0; i < NumTests; i++) begin
      // Some working variables
      target_value = $urandom_range(0, 255);

      for (int d = 0; d < DimensionSize; d++) begin
        current_value[d] = 0;
        bin_value[d] = 0;
      end      
      
      for (int j = 0; j < target_value; j++) begin

        // Valid for the entire vector
        data_valid_i = 1;

        // Place values on each dimension
        for (int d = 0; d < DimensionSize; d++) begin
          bin_value[d] = $urandom_range(0, 1);
          data_i[d] = bin_value[d];
          
          // Update each dimension too
          if (bin_value[d] == 1)
            current_value[d] = current_value[d] + 1;
          else
            current_value[d] = current_value[d] - 1;
        end
        
        // Clock update
        clk_delay(1);
      end

      for (int d = 0; d < DimensionSize; d++) begin
        assert (bundler_data_o[d] == current_value[d])
        else begin 
          $error("Iter i: %0d, Dimension %0d Bundler out: %0d, expected: %0d", i, d, bundler_data_o[d], current_value[d]);
          test_passed = 0;
        end

        assert (bundler_data_bin_o[d] == (current_value[d] >= 0)) 
        else begin 
          $error("Iter i: %0d, Dimension %0d Bundler bin out: %0d, expected: %0d", i, d, bundler_data_bin_o[d], (current_value[d] >= 0));
          test_passed = 0;
        end
      end
      

      // Clear the counter for the next test
      clr_i = 1;
      clk_delay(1);
      clr_i = 0;

    end

    if (test_passed)
      $display("Test pass!");
    else
      $display("Test failed!");
    $finish;
  end

endmodule