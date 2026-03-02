//-------------------------
// Testbench for HDC Unit Bundler
//-------------------------

module tb_adder_tree;

  // Working parameters
  localparam int unsigned NumInputs    = 8;
  localparam int unsigned InDataWidth  = 8;
  localparam int unsigned OutDataWidth = InDataWidth + $clog2(NumInputs);

  // Wires and drivers
  logic signed [ InDataWidth-1:0] data_i [NumInputs];
  logic signed [OutDataWidth-1:0] adder_tree_data_o;

  // Instantiate the Adder Tree
  adder_tree #(
    .NumInputs          ( NumInputs          ),
    .InDataWidth        ( InDataWidth        )
  ) dut (
    .data_i             ( data_i             ),
    .adder_tree_data_o  ( adder_tree_data_o  )
  );

  // Variable declaration
  logic signed [OutDataWidth-1:0] expected_sum;

  // Stimuli
  initial begin
    // Test 1: All zeros
    for (int i = 0; i < NumInputs; i++) begin
      data_i[i] = 0; // All inputs are 0
    end
    #10;
    assert(adder_tree_data_o == 0) else $error("Test 1 Failed: Expected 0, got %0d", adder_tree_data_o);

    // Test 2: All ones
    for (int i = 0; i < NumInputs; i++) begin
      data_i[i] = 8'hFF;
    end
    #10;
    assert(adder_tree_data_o == NumInputs * 255) else $error("Test 2 Failed: Expected %0d, got %0d", NumInputs * 255, adder_tree_data_o);

    // Test 3: Incremental values
    for (int i = 0; i < NumInputs; i++) begin
      data_i[i] = i; // Inputs are 0, 1, 2, ..., NumInputs-1
    end
    #10;
    expected_sum = (NumInputs * (NumInputs - 1)) / 2; // Sum of first N-1 integers
    assert(adder_tree_data_o == expected_sum) else $error("Test 3 Failed: Expected %0d, got %0d", expected_sum, adder_tree_data_o);

    // Test 4: Negative values
    for (int i = 0; i < NumInputs; i++) begin
      data_i[i] = -i; // Inputs are 0, -1, -2, ..., -(NumInputs-1)
    end
    #10;
    expected_sum = -1 * (NumInputs * (NumInputs - 1)) / 2; // Negative sum of first N-1 integers
    assert(adder_tree_data_o == expected_sum) else $error("Test 4 Failed: Expected %0d, got %0d", expected_sum, adder_tree_data_o);

    $display("All tests passed!");
    $finish;
  end


endmodule