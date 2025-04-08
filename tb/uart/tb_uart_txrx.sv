//--------------------------
// UART Transmitter Testbench
//
// Author: Danknight <rgantonio@github.com>
//--------------------------

module tb_uart_tx;

  // Parameters
  parameter int unsigned MAX_WIDTH     = 32;
  parameter int unsigned NUM_STOP_BITS = 1;
  parameter int unsigned PARITY_MODE   = "EVEN";
  parameter int unsigned DATA_WIDTH    = 8;
  parameter int unsigned MAX_DATA_WIDTH_COUNT = $clog2(DATA_WIDTH);

  // Inputs
  logic                  clk_i;
  logic                  rst_ni;
  logic [ MAX_WIDTH-1:0] baud_rate_i;
  logic [DATA_WIDTH-1:0] data_i;
  logic                  start_i;

  // Outputs
  logic                  tx_data_o;
  logic                  tx_done_o;
  logic [DATA_WIDTH-1:0] rx_data_o;
  logic                  rx_parity_error_o;
  logic                  rx_done_o;

  // Include some common tasks
  `include "common_tasks.sv"

  // Instantiate the UART transmitter module
  uart_tx #(
    .MAX_WIDTH      ( MAX_WIDTH     ),
    .NUM_STOP_BITS  ( NUM_STOP_BITS ),
    .PARITY_MODE    ( PARITY_MODE   )
  ) i_uart_tx (
    .clk_i          ( clk_i         ),
    .rst_ni         ( rst_ni        ),
    .baud_rate_i    ( baud_rate_i   ),
    .data_i         ( data_i        ),
    .start_i        ( start_i       ),
    .tx_data_o      ( tx_data_o     ),
    .tx_done_o      ( tx_done_o     )
  );

  // Instantiate the UART receiver module
  uart_rx #(
    .MAX_WIDTH         ( MAX_WIDTH         ),
    .NUM_STOP_BITS     ( NUM_STOP_BITS     ),
    .PARITY_MODE       ( PARITY_MODE       )
  ) i_uart_rx (
    .clk_i             ( clk_i             ),
    .rst_ni            ( rst_ni            ),
    .baud_rate_i       ( baud_rate_i       ),
    .data_i            ( tx_data_o         ),
    .rx_data_o         ( rx_data_o         ),
    .rx_parity_error_o ( rx_parity_error_o ),
    .rx_done_o         ( rx_done_o         )
  );

  // Clock at 10 MHz
  initial begin
    clk_i = 0;
    forever #50 clk_i = ~clk_i; // Toggle clock every 50 time units
  end

  // To get a baudrate of 9600 given a clock of 10 MHz
  // Baud rate = Clock frequency / (16 * Baud rate)
  // Baud rate = 10 MHz / (16 * 9600) = 65.1
  // So we need to set the baud rate to 65.1
  // Round up to the nearest integer is 66
  initial begin

    // Initialize inputs
    rst_ni        = 0;
    baud_rate_i   = 66;
    data_i        = $urandom & 8'hFF;
    start_i       = 0;

    // Assert reset
    clk_delay(3);
    #1; rst_ni = 1;

    // Start transmission
    clk_delay(3);
    #1; start_i = 1;
    clk_delay(1);
    #1; start_i = 0;

    // Wait for receiver to finish
    wait(rx_done_o);

    // Check if the received data matches the transmitted data
    // Use assertion to check the received data
    assert(rx_data_o == data_i) else begin
      $error("Data mismatch: expected %0h, got %0h", data_i, rx_data_o);
    end
    $display("Data received successfully: %0h", rx_data_o);

    clk_delay(3);

    // Do another transmission
    data_i = $urandom & 8'hFF;
    clk_delay(3);

    #1; start_i = 1;
    clk_delay(1);
    #1; start_i = 0;

    // Wait for receiver to finish
    wait(rx_done_o);

    assert(rx_data_o == data_i) else begin
      $error("Data mismatch: expected %0h, got %0h", data_i, rx_data_o);
    end
    $display("Data received successfully: %0h", rx_data_o);

    // Just trail the simulation
    clk_delay(25);

    // End the simulation
    $finish;

  end

endmodule