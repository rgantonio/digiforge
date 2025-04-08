//--------------------------
// UART Receiver
//
// Author: Danknight <rgantonio@github.com>
//
// Parameter description:
// MAX_WIDTH            : Maximum width for baud rate (default: 32)
// STOP_BITS            : Number of stop bits (default: 1)
// PARITY_MODE          : Parity mode (default: "NONE")
// DATA_WIDTH           : Data width (default: 8)
// MAX_DATA_WIDTH_COUNT : Maximum data width count (default: $clog2(9)). This is a don't touch parameter.
//
// Port description:
// clk_i        : Clock input
// rst_ni       : Active low reset
// baud_rate_i  : Baud rate input
// data_i       : Data input. Assumption is that this data is registered.
// start_i      : Start signal to initiate transmission
// tx_data_o    : Transmitted data output
// tx_done_o    : Transmission done signal
//--------------------------

module uart_rx #(
  parameter int unsigned MAX_WIDTH            = 32,
  parameter int unsigned NUM_STOP_BITS        = 1,
  parameter int unsigned PARITY_MODE          = "NONE",
  // Don't touch parameters
  parameter int unsigned DATA_WIDTH           = 8,
  parameter int unsigned MAX_DATA_WIDTH_COUNT = $clog2(DATA_WIDTH)
)(
  // Clock and reset
  input  logic                  clk_i,
  input  logic                  rst_ni,
  // Configurable inputs
  input  logic [ MAX_WIDTH-1:0] baud_rate_i,
  input  logic  data_i,
  // Output data
  output logic [DATA_WIDTH-1:0] rx_data_o,
  output logic                  rx_parity_error_o,
  output logic                  rx_done_o
);

  // Registers and wires
  logic [MAX_WIDTH-1:0] baud_counter_max;
  logic [MAX_WIDTH-1:0] baud_counter_reg;
  logic                 baud_counter_tick;

  logic [MAX_DATA_WIDTH_COUNT-1:0] data_counter_max;
  logic [MAX_DATA_WIDTH_COUNT-1:0] data_counter_reg;
  logic                            data_counter_tick;

  logic start_bit;

  logic [DATA_WIDTH-1:0] rx_data_reg;
  logic                  rx_parity_error_reg;

  // State machine states
  typedef enum logic [2:0] {
    IDLE,
    START_BIT,
    SEND_DATA_BITS,
    PARITY_BITS,
    STOP_BITS2,
    STOP_BITS1
  } state_t;

  state_t current_state, next_state;

  // Pre-logic
  assign baud_counter_max  = baud_rate_i - 1;
  assign baud_counter_tick = (baud_counter_reg == (baud_counter_max));

  assign data_counter_max  = DATA_WIDTH - 1;
  assign data_counter_tick = (data_counter_reg == data_counter_max);

  assign start_bit = (current_state == IDLE) && (data_i == 1'b0);

  assign rx_data_o         = rx_data_reg;
  assign rx_parity_error_o = rx_parity_error_reg;
  assign rx_done_o         = (current_state == STOP_BITS1) && baud_counter_tick;


  // Main state machine
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end
  end

  // State machine next state logic
  always_comb begin
    next_state = current_state;
    case (current_state)
      IDLE: begin
        if (start_bit) begin
          next_state = START_BIT;
        end else begin
          next_state = current_state;
        end
      end
      START_BIT: begin
        if (baud_counter_tick) begin
          next_state = SEND_DATA_BITS;
        end else begin
          next_state = current_state;
        end
      end
      SEND_DATA_BITS: begin
        if (data_counter_tick & baud_counter_tick) begin
          if (PARITY_MODE != "NONE") begin
            next_state = PARITY_BITS;
          end else begin
            if (NUM_STOP_BITS == 2) begin
              next_state = STOP_BITS2;
            end else if (NUM_STOP_BITS == 1) begin
              next_state = STOP_BITS1;
            end else begin
              next_state = IDLE;
            end
          end
        end else begin
          next_state = current_state;
        end
      end
      PARITY_BITS: begin
        if (baud_counter_tick) begin
          if (NUM_STOP_BITS == 2) begin
            next_state = STOP_BITS2;
          end else if (NUM_STOP_BITS == 1) begin
            next_state = STOP_BITS1;
          end else begin
            next_state = IDLE;
          end
        end else begin
          next_state = current_state;
        end
      end
      STOP_BITS2: begin
        if (baud_counter_tick) begin
          next_state = STOP_BITS1;
        end else begin
          next_state = current_state;
        end
      end
      STOP_BITS1: begin
        if (baud_counter_tick) begin
          next_state = IDLE;
        end else begin
          next_state = current_state;
        end
      end
      default: begin
        next_state = IDLE;
      end
    endcase
  end

  // Data counter
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      data_counter_reg <= '0;
    end else if (current_state == SEND_DATA_BITS) begin
      if (baud_counter_tick) begin
        data_counter_reg <= data_counter_reg + 1;
      end else begin
        data_counter_reg <= data_counter_reg;
      end
    end else begin
      data_counter_reg <= '0;
    end
  end

  // Baudrate counter
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      baud_counter_reg <= '0;
    end else if (baud_counter_tick) begin
      baud_counter_reg <= '0;
    end else begin
      baud_counter_reg <= baud_counter_reg + 1;
    end
  end

  // Receiving data
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rx_data_reg <= '0;
    end else begin
      if (current_state == START_BIT) begin
        rx_data_reg <= '0;
      end else if (current_state == SEND_DATA_BITS) begin
        if (baud_counter_tick) begin
          rx_data_reg[data_counter_reg] <= data_i;
        end else begin
          rx_data_reg <= rx_data_reg;
        end
      end else begin
        rx_data_reg <= rx_data_reg;
      end
    end
  end

  // Receiving parity error
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rx_parity_error_reg <= 1'b0;
    end else begin
      if (current_state == START_BIT) begin
        rx_parity_error_reg <= 1'b0;
      end else if (current_state == PARITY_BITS) begin
        if (baud_counter_tick) begin
          rx_parity_error_reg <= ^{data_i, rx_data_reg};
        end else begin
          rx_parity_error_reg <= rx_parity_error_reg;
        end
      end else begin
        rx_parity_error_reg <= rx_parity_error_reg;
      end
    end
  end

endmodule