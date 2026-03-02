//--------------------------
// Simple synchronizer flip flop testbench
//
// Author: Danknight <rgantonio@github.com>
//--------------------------

module tb_sync_ff;

  // Parameters
  parameter int unsigned SYNC_WIDTH = 2;
  parameter int unsigned RESET_VAL  = 0;
  parameter int unsigned DATA_WIDTH = 16;

  // Inputs
  logic clk_i;
  logic rst_ni;
  logic data_i;

  // Outputs
  logic data_o;

  // Testbenches signals
  logic clk_src;
  logic enable;
  logic [DATA_WIDTH-1:0] sample_data_counter;
  logic [DATA_WIDTH-1:0] sample_data;

  // Include some common tasks
  `include "common_tasks.sv"

  // Instantiate the synchronizer flip-flop module
  sync_ff #(
    .SYNC_WIDTH ( SYNC_WIDTH ),
    .RESET_VAL  ( RESET_VAL  )
  ) i_sync_ff (
    .clk_i      ( clk_i      ),
    .rst_ni     ( rst_ni     ),
    .data_i     ( data_i     ),
    .data_o     ( data_o     )
  );

  // Clock generation
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i; // Toggle clock every 5 time units
  end

  // Clock generation
  initial begin
    clk_src = 0;
    forever #43 clk_src = ~clk_src; // Toggle clock every 5 time units
  end

  // Synthetic data source
  always_ff @(posedge clk_src or negedge rst_ni) begin
    if (!rst_ni) begin
      sample_data_counter <= 0;
    end else begin
      if(sample_data_counter == DATA_WIDTH - 1) begin
        sample_data_counter <= 0;
      end else if (enable) begin
        sample_data_counter <= sample_data_counter + 1;
      end else begin
        sample_data_counter <= sample_data_counter;
      end
    end
  end

  assign data_i = (enable) ? sample_data[sample_data_counter] : 1'b0;

  // Test sequence
  initial begin
    // Initialize inputs
    rst_ni = 0;
    enable = 0;
    sample_data = $urandom_range(0, 2**DATA_WIDTH - 1);

    clk_delay(3);

    // Reset the synchronizer
    #1; rst_ni = 1;

    clk_delay(3);

    // Enable the synchronizer and start sending data
    #1; enable = 1;

    clk_delay(2000);

    // Deassert the data input

    // Finish simulation
    #1; $finish;
  end

endmodule