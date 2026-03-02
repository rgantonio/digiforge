//--------------------------
// Basic memory unit
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


module mem_unit #(
  parameter int unsigned NUM_WORDS            = 256,
  parameter int unsigned DATA_WIDTH           = 32,
  parameter int unsigned BYTE_WIDTH           = 8,
  parameter int unsigned LATENCY              = 1,
  // Don't touch parameters
  parameter int unsigned ADDR_WIDTH           = $clog2(NUM_WORDS),
  parameter int unsigned ADDR_BYTE_WIDTH      = $clog2(DATA_WIDTH / BYTE_WIDTH)
)(
  // Clock and reset
  input  logic                       clk_i,
  input  logic                       rst_ni,
  // Input signals
  input  logic                       req_i,
  input  logic                       w_en_i,
  input  logic [     ADDR_WIDTH-1:0] addr_i,
  input  logic [     DATA_WIDTH-1:0] w_data_i,
  input  logic [ADDR_BYTE_WIDTH-1:0] b_en_i,
  // Output signals
  output logic [     DATA_WIDTH-1:0] r_data_o
);


  // Registers and wires

  // Main memory array
  logic [DATA_WIDTH-1:0] mem [NUM_WORDS-1:0];

  // Writing to memory logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      // Reset memory
      for (int i = 0; i < NUM_WORDS; i++) begin
        mem[i] <= {DATA_WIDTH{1'b0}};
      end
    end else if (req_i) begin
      if (w_en_i) begin
        // Write operation but with byte masking
        for (int i = 0; i < BYTE_WIDTH; i++) begin
          if (b_en_i[i]) begin
            mem[addr_i][(i*8)+:8] <= w_data_i[(i*8)+:8];
          end
        end
      end
    end
  end

  // Reading from memory logic
  if(LATENCY > 0) begin
    // Latency logic
    logic [DATA_WIDTH-1:0] r_data_reg;
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
        r_data_reg <= {DATA_WIDTH{1'b0}};
      end else if (req_i) begin
        r_data_reg <= mem[addr_i];
      end
    end
    assign r_data_o = r_data_reg;
  end else begin
    // No latency logic
    assign r_data_o = mem[addr_i];
  end 

endmodule
  