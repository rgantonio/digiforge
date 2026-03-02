//-------------------------
// Testbench for HDC Unit Bundler
//-------------------------

module tb_hdc_unit_bundler;

  // Working parameters
  localparam int unsigned DataWidth = 8;

  // Test parameters
  localparam int unsigned NumTests = 5;

  // Wires and drivers
  logic                        clk_i;
  logic                        rst_ni;
  logic                        clr_i;
  logic                        data_valid_i;
  logic                        data_i;
  logic signed [DataWidth-1:0] bundler_data_o;
  logic                        bundler_data_bin_o;

  // Include some common tasks
  `include "common_tasks.sv"

  // Instantiate the Unit Bundler
  unit_bundler #(
    .DataWidth(DataWidth)
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
      int target_value = $urandom_range(0, 255);
      int current_value = 0;
      int bin_value = 0;
      
      for (int j = 0; j < target_value; j++) begin
        bin_value = $urandom_range(0, 1);

        data_i = bin_value;
        data_valid_i = 1;
        clk_delay(1);

        if (bin_value == 1)
          current_value = current_value + 1;
        else
          current_value = current_value - 1;
      end

      assert (bundler_data_o == current_value)
      else $error("Bundler out: %0d, expected: %0d", bundler_data_o, current_value);

      assert (bundler_data_bin_o == (current_value >= 0)) 
      else $error("Bundler bin out: %0d, expected: %0d", bundler_data_bin_o, (current_value >= 0));

    end

    $display("Test pass!");
    $finish;
  end

endmodule