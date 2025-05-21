
# Sequential Logic

## Basic Register (No Reset)

- Declaring registers is easy, you only need `Reg` element

```scala
class RegisterModule extends Module {
  val io = IO(new Bundle {
    val in  = Input(UInt(12.W))
    val out = Output(UInt(12.W))
  })
  
  val register = Reg(UInt(12.W))
  register := io.in + 1.U
  io.out := register
}

```

- An alternative declaration would be:
  - Observe that the output is inferred

```scala
class RegNextModule extends Module {
  val io = IO(new Bundle {
    val in  = Input(UInt(12.W))
    val out = Output(UInt(12.W))
  })
  
  // register bitwidth is inferred from io.out
  io.out := RegNext(io.in + 1.U)
}
```

- The generated Verilog:
  - :warning: It has a fancy memory initialization
  - :wrning: The reset is not connected yet

```verilog
module RegisterModule(
  input         clock,
  input         reset,
  input  [11:0] io_in,
  output [11:0] io_out
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
`endif // RANDOMIZE_REG_INIT
  reg [11:0] register; // @[cmd3.sc 7:21]
  assign io_out = register; // @[cmd3.sc 9:10]
  always @(posedge clock) begin
    register <= io_in + 12'h1; // @[cmd3.sc 8:21]
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
   `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  register = _RAND_0[11:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
```

- When simulating the register, the testbench looks like:
  - To make 1 clock step, there is a `c.clock.step(1)` stimulus
  - We can use `.step(n)` to tick the signal multiple times

```scala
test(new RegisterModule) { c =>
  for (i <- 0 until 100) {
    c.io.in.poke(i.U)
    c.clock.step(1)
    c.io.out.expect((i + 1).U)
  }
}
println("SUCCESS!!")
```

## Basic Register with Synchronous Reset

- Below is a declaration of a register but with a reset signal
  - You use `RegInit (<initial value>(<bit-width>))` for this
  - :warning: Also take note, this is a **synchronous reset**

```scala
class RegInitModule extends Module {
  val io = IO(new Bundle {
    val in  = Input(UInt(12.W))
    val out = Output(UInt(12.W))
  })
  
  val register = RegInit(0.U(12.W))
  register := io.in + 1.U
  io.out := register
}
```

- Generated Verilog code:

```verilog
module RegInitModule(
  input         clock,
  input         reset,
  input  [11:0] io_in,
  output [11:0] io_out
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
`endif // RANDOMIZE_REG_INIT
  reg [11:0] register; // @[cmd6.sc 7:25]
  wire [11:0] _T_1 = io_in + 12'h1; // @[cmd6.sc 8:21]
  assign io_out = register; // @[cmd6.sc 9:10]
  always @(posedge clock) begin
    if (reset) begin // @[cmd6.sc 7:25]
      register <= 12'h0; // @[cmd6.sc 7:25]
    end else begin
      register <= _T_1; // @[cmd6.sc 8:12]
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
T_RANDOMNI
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  register = _RAND_0[11:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
```

## Example: Shift Register (LFSR)

- Below is the example with the corresponding testbench
  - Note that, just like in Verilog, it is better to describe the next state combinationally
  - Then it's just a matter of updating the register

```scala
class MyShiftRegister(val init: Int = 1) extends Module {
  val io = IO(new Bundle {
    val in  = Input(Bool())
    val out = Output(UInt(4.W))
  })

  val state = RegInit(UInt(4.W), init.U)
  val nextState = (state << 1) | io.in

  state := nextState
  io.out := state
}

test(new MyShiftRegister()) { c =>
  var state = c.init
  for (i <- 0 until 10) {
    // poke in LSB of i (i % 2)
    c.io.in.poke(((i % 2) != 0).B)
    // update expected state
    state = ((state * 2) + (i % 2)) & 0xf
    c.clock.step(1)
    c.io.out.expect(state.U)
  }
}
```

- Generated Verilog is:
  - The initialization was omitted for clarity

```verilog
module MyShiftRegister(
  input        clock,
  input        reset,
  input        io_in,
  output [3:0] io_out
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
`endif // RANDOMIZE_REG_INIT
  reg [3:0] state; // @[cmd9.sc 7:22]
  wire [4:0] _T = {state, 1'h0}; // @[cmd9.sc 8:26]
  wire [4:0] _GEN_0 = {{4'd0}, io_in}; // @[cmd9.sc 8:32]
  wire [4:0] nextState = _T | _GEN_0; // @[cmd9.sc 8:32]
  assign io_out = state; // @[cmd9.sc 11:10]
  always @(posedge clock) begin
    if (reset) begin // @[cmd9.sc 7:22]
      state <= 4'h1; // @[cmd9.sc 7:22]
    end else begin
      state <= nextState[3:0]; // @[cmd9.sc 10:9]
    end
  end
endmodule
```

## Explicit Clock and Rest
- Previously we have the clock and reset by default, but sometimes we don't want that
- Chisel provides constructs:
  - `withClock (){}`
  - `withReset (){}`
  - `withClockAndReset (){}`
- :warning: Chisel testers do not have complete support for multi-clock designs.

```scala
class ClockExamples extends Module {
  val io = IO(new Bundle {
    val in = Input(UInt(10.W))
    val alternateReset    = Input(Bool())
    val alternateClock    = Input(Clock())
    val outImplicit       = Output(UInt())
    val outAlternateReset = Output(UInt())
    val outAlternateClock = Output(UInt())
    val outAlternateBoth  = Output(UInt())
  })

  val imp = RegInit(0.U(10.W))
  imp := io.in
  io.outImplicit := imp

  withReset(io.alternateReset) {
    // everything in this scope with have alternateReset as the reset
    val altRst = RegInit(0.U(10.W))
    altRst := io.in
    io.outAlternateReset := altRst
  }

  withClock(io.alternateClock) {
    val altClk = RegInit(0.U(10.W))
    altClk := io.in
    io.outAlternateClock := altClk
  }

  withClockAndReset(io.alternateClock, io.alternateReset) {
    val alt = RegInit(0.U(10.W))
    alt := io.in
    io.outAlternateBoth := alt
  }
}
```

- The generated Verilog is:
  - Observe that the alternate reset just replaces the default reset but uses the main `clock`
  - The alternate clock and reset are replaced by both

```verilog
module ClockExamples(
  input        clock,
  input        reset,
  input  [9:0] io_in,
  input        io_alternateReset,
  input        io_alternateClock,
  output [9:0] io_outImplicit,
  output [9:0] io_outAlternateReset,
  output [9:0] io_outAlternateClock,
  output [9:0] io_outAlternateBoth
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
`endif // RANDOMIZE_REG_INIT
  reg [9:0] imp; // @[cmd12.sc 14:20]
  reg [9:0] REG; // @[cmd12.sc 20:25]
  reg [9:0] REG_1; // @[cmd12.sc 26:25]
  reg [9:0] REG_2; // @[cmd12.sc 32:22]
  assign io_outImplicit = imp; // @[cmd12.sc 16:18]
  assign io_outAlternateReset = REG; // @[cmd12.sc 22:26]
  assign io_outAlternateClock = REG_1; // @[cmd12.sc 28:26]
  assign io_outAlternateBoth = REG_2; // @[cmd12.sc 34:25]
  always @(posedge clock) begin
    if (reset) begin // @[cmd12.sc 14:20]
      imp <= 10'h0; // @[cmd12.sc 14:20]
    end else begin
      imp <= io_in; // @[cmd12.sc 15:7]
    end
  end
  always @(posedge clock) begin
    if (io_outAlternateReset) begin // @[cmd12.sc 20:25]
      REG <= 10'h0; // @[cmd12.sc 20:25]
    end else begin
      REG <= io_in; // @[cmd12.sc 21:12]
    end
  end
  always @(posedge io_alternateClock) begin
    if (reset) begin // @[cmd12.sc 26:25]
      REG_1 <= 10'h0; // @[cmd12.sc 26:25]
    end else begin
      REG_1 <= io_in; // @[cmd12.sc 27:12]
    end
    if (io_alternateReset) begin // @[cmd12.sc 32:22]
      REG_2 <= 10'h0; // @[cmd12.sc 32:22]
    end else begin
      REG_2 <= io_in; // @[cmd12.sc 33:9]
    end
  end
```

## Dealing with Asynchronous Resets

- To deal with asynchronous resets, you need to explicitly state it in the scala code

```scala
class AsyncResetModule extends RawModule {
  val clk   = IO(Input(Clock()))
  val rst_n = IO(Input(Bool()))
  val io    = IO(new Bundle {
    val D = Input(UInt(1.W))
    val Q = Output(UInt(1.W))
  })

  val asyncReset = (!rst_n).asAsyncReset
  val x = withClockAndReset(clk, asyncReset) {
    RegInit(0.U(1.W))
  }

  x := io.D
  io.Q := x
}
```

- Generated verilog code is:

```verilog
always @(posedge clk or posedge reset) begin
  if (reset) begin
    x <= 1'h0;
  end else begin
    x <= io_D;
  end
end
```

- Alternatively, you can have the entire module with the asynchronous reset trait, such that:

```scala
class MyAsyncModule extends Module with RequireAsyncReset {
  val io = IO(new Bundle {
    val D = Input(UInt(1.W))
    val Q = Output(UInt(1.W))
  })

  val x = RegInit(0.U(1.W))
  x := io.D
  io.Q := x
}
```