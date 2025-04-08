# :books: The RTL Guide

In my years of experience for designing and planning, a good RTL designer needs to be clear, clean, and efficient designs. Although efficiency is very application or design specific that needs to be well understood. The RTL codes in this repository are built such that we try to get all three characteristics. Below are some guidelines to make a good RTL code.

## :star: Clear Techniques

:star: **ALWAYS** completely specify conditional statements like `if-else` and `case` statements. This avoids unwanted latches in the designs. Latches are difficult to deal with because the timing is not *edge-triggered* but rather *level-triggered*. This becomes a headache after synthesis and PnR later on. Therefore, avoid these as much as possible. Note that it's not wrong to have latches unless it is definitely desired to have.

Completely specifying an `if-else` condition just means you always need to specify the `else` statement and including all the signals within:

```verilog
logic A, B, C;

always_comb begin
  if (A) begin
    B = <insert some logic>;
    C = <insert some logic>;
  end else begin
    B = <insert some default logic>;
    C = <insert some default logic>;
  end
end
```

The same goes for `case` statements:

```verilog
logic [1:0] A;
logic B, C;

always_comb begin
  case (A)
    2'b00: begin
      C = <insert some logic>; // <--- Having no value for the others is okay, as long as there's a default
    end
    2'b01: begin
      B = <insert some logic>;
    end
    2'b10: begin
      B = <insert some logic>;
      C = <insert some logic>;
    end
    default: begin // <--- Always have the default statement
      B = <insert some logic>;
      C = <insert some logic>;
    end
  endcase
end
```

## :sparkles: Clean Techniques

:sparkles: **ALWAYS** complete conditions or procedures with the `begin-end` blocks. For example in procedures.

```verilog
always_ff @ (posedge clk_i or negedge rst_ni) begin
end
```

Another example for `if-else` statements:

```verilog
always_comb begin
  if (condition) begin // <--- Always make sure the begin end are there even with single lines after it

  end else if (condition_2) begin

  end else begin

  end
end
```

:sparkles: Always append a suffix with `_i` or `_o` at every port of a module to indicate whether it is an input or output. This makes it easier for users to know if the direction of the signal. Moreover, even though it may be redundant at times, make sure to make the port names descriptive. It also makes it easier for visualization. Then, always group the ports that go together. For example, signals related for input data need to be together, regardless if they are of type `input` or `output`. Lastly, align the signals for cleanliness. For example:

```verilog
// Observe how the spaces are aligned for readability
module some_module (
  // Clocks and reset
  input        clk_i,
  input        rst_ni,
  // Input data
  input  [7:0] in_data_i,    // <--- All input related signals go together
  input        in_valid_i,
  output       in_ready_o,
  // Output data
  output [7:0] out_data_o,   // <--- All output related signals go together
  output       out_valid_o,
  input        out_ready_i
);

  // Insert whatever your module does here
endmodule
```

## :wrench: Efficient Techniques

:wrench: When making RTL code, always do it in a mindset that you are making *register-transfer-level*. That's what RTL stands for in the first place. That means when we *describe* our hardware, we also have to think in `register -> logic -> register` structures.