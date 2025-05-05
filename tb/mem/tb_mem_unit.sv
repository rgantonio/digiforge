//--------------------------
// Tesbench for basic memory unit
//
// Author: Danknight <rgantonio@github.com>
//
// Parameter description:
// NUM_WORDS            : Number of words in the memory
// DATA_WIDTH           : Width of each word in the memory
// BYTE_WIDTH           : Width of each byte in the memory
// LATENCY              : Latency of the memory
//
// Don't touch parameters:
// ADDR_WIDTH           : Address width of the memory
// ADDR_WIDTH_BYTE      : Address width of the memory in bytes
//
// Port description:
// clk_i        : Clock input
// rst_ni       : Active low reset
// req_i        : Request signal
// w_en_i       : Write enable input
// addr_i       : Address input
// w_data_i     : Write data input
// b_en_i       : Byte enable input
// r_data_o     : Read data output
//--------------------------

module tb_mem_unit;

  // Parameters
  parameter int unsigned NUM_WORDS       = 64;
  parameter int unsigned DATA_WIDTH      = 32;
  parameter int unsigned BYTE_WIDTH      = 8;
  parameter int unsigned LATENCY         = 1;
  // Don't touch parameters
  parameter int unsigned ADDR_WIDTH      = $clog2(NUM_WORDS);
  parameter int unsigned ADDR_BYTE_WIDTH = $clog2(DATA_WIDTH / BYTE_WIDTH);

  // Inputs
  logic                       clk_i;
  logic                       rst_ni;
  logic                       req_i;
  logic                       w_en_i;
  logic [     ADDR_WIDTH-1:0] addr_i;
  logic [     DATA_WIDTH-1:0] w_data_i;
  logic [ADDR_BYTE_WIDTH-1:0] b_en_i;

  // Outputs
  logic [     DATA_WIDTH-1:0] r_data_o;

  // Internal memory array
  logic [DATA_WIDTH-1:0] gold_mem [NUM_WORDS-1:0];

  // Include some common tasks
  `include "common_tasks.sv"
  `include "mem_tasks.sv"

  // Instantiate the memory unit
  mem_unit #(
    .NUM_WORDS      ( NUM_WORDS     ),
    .DATA_WIDTH     ( DATA_WIDTH    ),
    .BYTE_WIDTH     ( BYTE_WIDTH    ),
    .LATENCY        ( LATENCY       )
  ) i_mem_unit (
    .clk_i          ( clk_i         ),
    .rst_ni         ( rst_ni        ),
    .req_i          ( req_i         ),
    .w_en_i         ( w_en_i        ),
    .addr_i         ( addr_i        ),
    .w_data_i       ( w_data_i      ),
    .b_en_i         ( b_en_i        ),
    .r_data_o       ( r_data_o      )
  );

  // Clock generation
  initial begin
    forever #5 clk_i = ~clk_i; // 10 MHz clock
  end

  // Initialize input array
  initial begin
    for (int i = 0; i < NUM_WORDS; i++) begin
      gold_mem[i] = $urandom_range(0, 2**DATA_WIDTH-1);
    end
  end

  // Test sequence
  initial begin
    // Dump VCD
    $dumpfile("tb_mem_unit.vcd");
    $dumpvars(0, tb_mem_unit);
  
    // Initialize data
    clk_i    = 0;
    rst_ni   = 0;
    req_i    = 0;
    w_en_i   = 0;
    addr_i   = 0;
    w_data_i = 0;
    b_en_i   = {ADDR_BYTE_WIDTH{1'b0}};

    // De-assert reset
    clk_delay(3);
    rst_ni = 1;
    clk_delay(3);

    // Write to memory
    for (int i = 0; i < NUM_WORDS; i++) begin
      mem_unit_write(i, gold_mem[i]);
    end

    // Read from memory and check values
    for (int i = 0; i < NUM_WORDS; i++) begin
      mem_unit_read(LATENCY, i);
      mem_unit_check(i, gold_mem[i]);
    end

    // Finish simulation
    $finish;

  end

endmodule