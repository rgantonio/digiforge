//--------------------------
// Simple counter module testbench
//
// Author: Danknight <rgantonio@github.com>
//--------------------------

module tb_counter;
  
  // Parameters
  parameter COUNTER_WIDTH = 8;
  parameter RESET_VAL     = 0;

  int random_delay;

  // Inputs
  logic clk_i;
  logic rst_ni;
  logic clr_i;
  logic en_i;

  // Outputs
  logic [COUNTER_WIDTH-1:0] count_o;

  // Instantiate the counter module
  counter #(
    .COUNTER_WIDTH(COUNTER_WIDTH),
    .RESET_VAL(RESET_VAL)
  ) i_counter (
    .clk_i    (clk_i    ),
    .rst_ni   (rst_ni   ),
    .clr_i    (clr_i    ),
    .en_i     (en_i     ),
    .count_o  (count_o  )
  );

  // Clock generation
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i; // Toggle clock every 5 time units
  end

  // Test sequence
  initial begin
    // Initialize inputs
    rst_ni = 0;
    clr_i = 0;
    en_i = 0;

    @(posedge clk_i);
    @(posedge clk_i);
    @(posedge clk_i);

    // Reset the counter
    #1; rst_ni = 1; // Assert reset

    @(posedge clk_i);
    @(posedge clk_i);
    @(posedge clk_i);

    // Enable the counter and start counting
    #1; en_i = 1;

    // Wait for a few clock cycles
    random_delay = $urandom_range(100); // Random number between 0 and 100

    for(int i=0; i <  random_delay; i=i+1) begin
      @(posedge clk_i);
    end

    // Display the value of the counter
    $display("Counter value: %0d", count_o);

    // Clear the counter
    #1; clr_i = 1; // Assert clear
    @(posedge clk_i);
    #1; clr_i = 0; // Deassert clear
    @(posedge clk_i);

    // Display the value of the counter
    $display("Counter value: %0d", count_o);

    // Random number between 0 and 100
    random_delay = $urandom_range(100); 

    for(int i=0; i <  random_delay; i=i+1) begin
      @(posedge clk_i);
    end

    // Display the value of the counter
    $display("Counter value: %0d", count_o);

    // Finish simulation after some time
    for(int i=0; i < 5; i++) begin
      @(posedge clk_i);
    end

    $finish;
  end

endmodule