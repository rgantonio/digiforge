//--------------------------
// Stream Out Testbench
//
// Author: Danknight <rgantonio@github.com>
//--------------------------

module tb_stream_out;

  // Parameters
  parameter int unsigned DATA_WIDTH = 16;
  parameter int unsigned RESET_VAL  = 0;
  parameter int unsigned TOTAL_ELEM = 10;
  // Don't touch these parameters
  parameter int unsigned IDX_WIDTH  = $clog2(TOTAL_ELEM);

  // Inputs
  logic clk_i;
  logic rst_ni;
  logic [TOTAL_ELEM-1:0][DATA_WIDTH-1:0] bus_data_i;
  logic start_stream_i, stream_clr_i;
  
  // Outputs
  logic [DATA_WIDTH-1:0] stream_data_o;
  logic stream_valid_o;

  // Include some common tasks
  `include "common_tasks.sv"

  // Instantiate the MAC PE module
  stream_out #(
    .DATA_WIDTH      ( DATA_WIDTH     ),
    .RESET_VAL       ( RESET_VAL      ),
    .TOTAL_ELEM      ( TOTAL_ELEM     )
  ) i_stream_out (
    .clk_i           ( clk_i          ),
    .rst_ni          ( rst_ni         ),
    .bus_data_i      ( bus_data_i     ),
    .start_stream_i  ( start_stream_i ),
    .stream_clr_i    ( stream_clr_i   ),
    .stream_data_o   ( stream_data_o  ),
    .stream_valid_o  ( stream_valid_o )
  );

  // Clock generation
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i; // Toggle clock every 5 time units
  end

  // Test sequence
  initial begin
    $dumpfile("tb_stream_out.vcd");
    $dumpvars(0, tb_stream_out);

    // Initialize inputs
    clk_i          = 0;
    rst_ni         = 0;
    bus_data_i     = {DATA_WIDTH{1'b0}};
    start_stream_i = 0;
    stream_clr_i   = 0;

    clk_delay(3);

    // Release reset
    rst_ni = 1;
    clk_delay(1);

    for (int i = 0; i < TOTAL_ELEM; i++) begin
      bus_data_i[i] = $urandom_range(2**DATA_WIDTH-1); // Random data for the bus
    end

    // Pulse the input stream
    #1; start_stream_i = 1;
    clk_delay(1);
    #1; start_stream_i = 0;

    // Cycle through the stream
    for (int i = 0; i < TOTAL_ELEM; i++) begin
      clk_delay(1);
      if (stream_data_o != bus_data_i[i]) begin
        $display("Data mismatch at index %0d, Golden Data: %d, Stream Data: %d, Valid: %b",
                i, bus_data_i[i], stream_data_o, stream_valid_o);
        $fatal();
      end else begin
        $display("Data match at index %0d, Golden Data: %d, Stream Data: %d, Valid: %b",
                i, bus_data_i[i], stream_data_o, stream_valid_o);
      end
    end

    // Finish simulation after some time
    clk_delay(5);

    $finish;
  end

endmodule