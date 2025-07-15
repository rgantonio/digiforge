//--------------------------
// Simple Bus to Serial Streamout
// Author: Danknight <rgantonio@github.com>
// 
// Description:
// Streams out chunks from a bus to a serial output.
//--------------------------


module stream_out #(
  parameter int unsigned DATA_WIDTH = 16,
  parameter int unsigned RESET_VAL  = 0,
  parameter int unsigned TOTAL_ELEM = 10,
  // Don't touch these parameters
  parameter int unsigned IDX_WIDTH  = $clog2(TOTAL_ELEM)
)(
  // Clock and reset
  input  logic                                  clk_i,
  input  logic                                  rst_ni,
  // Input bus
  input  logic [TOTAL_ELEM-1:0][DATA_WIDTH-1:0] bus_data_i,
  // Start signal for streaming
  input  logic                                  start_stream_i,
  // Clear signal for streaming
  input  logic                                  stream_clr_i,
  // Output signals
  output logic                 [DATA_WIDTH-1:0] stream_data_o,
  output logic                                  stream_valid_o
);

  // Internal state
  logic [IDX_WIDTH-1:0] index_reg;
  logic streaming_active;
  logic counter_done;

  // Other logics
  assign counter_done = (index_reg == TOTAL_ELEM-1);

  // Internal stream active state
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      streaming_active <= 1'b0;
    end else if (counter_done || stream_clr_i) begin
      streaming_active <= 1'b0;
    end else if (start_stream_i) begin
      streaming_active <= 1'b1;
    end else begin
      streaming_active <= streaming_active;
    end
  end

  // Counter for the index
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      index_reg <= {IDX_WIDTH{1'b0}};
    end else if (counter_done || stream_clr_i) begin
      index_reg <= {IDX_WIDTH{1'b0}};
    end else if (start_stream_i || streaming_active) begin
      index_reg <= index_reg + 1;
    end else begin
      index_reg <= index_reg;
    end
  end

  // Output control
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      stream_data_o  <= {DATA_WIDTH{1'b0}};
      stream_valid_o <= 1'b0;
    end else if (stream_clr_i) begin
      stream_data_o  <= {DATA_WIDTH{1'b0}};
      stream_valid_o <= 1'b0;
    end else if (start_stream_i || streaming_active) begin
      stream_data_o  <= bus_data_i[index_reg];
      stream_valid_o <= 1;
    end else begin
      stream_data_o  <= stream_data_o;
      stream_valid_o <= 0; // No valid data when not streaming
    end
  end

endmodule