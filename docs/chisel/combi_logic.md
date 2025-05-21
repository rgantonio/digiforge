
# Combinational Logics

## Common Arithmetics

- You always have the same operators like normal Verilog
- Take extra are with the data type casting

```scala
class MyOperators extends Module {
  val io = IO(new Bundle {
    val in      = Input(UInt(4.W))
    val out_add = Output(UInt(4.W))
    val out_sub = Output(UInt(4.W))
    val out_mul = Output(UInt(4.W))
  })

  io.out_add := 1.U + 4.U
  io.out_sub := 2.U - 1.U
  io.out_mul := 4.U * 2.U
}
```

- The code above generates the Verilog code:
  - :warning: The clock and reset signals are always present in the module

```verilog
module MyOperators(
  input        clock,
  input        reset,
  input  [3:0] io_in,
  output [3:0] io_out_add,
  output [3:0] io_out_sub,
  output [3:0] io_out_mul
);
  wire [1:0] _T_3 = 2'h2 - 2'h1; // @[cmd4.sc 10:21]
  wire [4:0] _T_4 = 3'h4 * 2'h2; // @[cmd4.sc 11:21]
  assign io_out_add = 4'h5; // @[cmd4.sc 9:21]
  assign io_out_sub = {{2'd0}, _T_3}; // @[cmd4.sc 10:21]
  assign io_out_mul = _T_4[3:0]; // @[cmd4.sc 11:14]
endmodule
```

## MUXes and Concatenations

- Use `Mux(select, A, B)` for MUX-ing
- Use `Cat(A,B)` for concatenating
  - Note that you need to nest concatenations if you want multiple concatentations

```scala
class MyOperatorsTwo extends Module {
  val io = IO(new Bundle {
    val in      = Input(UInt(4.W))
    val out_mux = Output(UInt(4.W))
    val out_cat = Output(UInt(4.W))
  })

  val s = true.B
  io.out_mux := Mux(s, 3.U, 0.U) // should return 3.U, since s is true
  io.out_cat := Cat(2.U, 1.U)    // concatenates 2 (b10) with 1 (b1) to give 5 (101)
}
```

- This generates the Verilog:

```verilog
module MyOperatorsTwo(
  input        clock,
  input        reset,
  input  [3:0] io_in,
  output [3:0] io_out_mux,
  output [3:0] io_out_cat
);
  assign io_out_mux = 4'h3; // @[cmd6.sc 9:20]
  assign io_out_cat = 4'h5; // @[Cat.scala 30:58]
endmodule
```

## A Simple MAC
- A simple MAC design

```scala
class MAC extends Module {
  val io = IO(new Bundle {
    val in_a = Input(UInt(4.W))
    val in_b = Input(UInt(4.W))
    val in_c = Input(UInt(4.W))
    val out  = Output(UInt(8.W))
  })

  io.out := ((io.in_a * io.in_b) + io.in_c)
}
```

- Generates the Verilog:
  - Take note that the multiplication becomes a `*`
  - In modern synthesis tools, this is synthesizable

```verilog
module MAC(
  input        clock,
  input        reset,
  input  [3:0] io_in_a,
  input  [3:0] io_in_b,
  input  [3:0] io_in_c,
  output [7:0] io_out
);
  wire [7:0] _T = io_in_a * io_in_b; // @[cmd12.sc 9:23]
  wire [7:0] _GEN_0 = {{4'd0}, io_in_c}; // @[cmd12.sc 9:34]
  assign io_out = _T + _GEN_0; // @[cmd12.sc 9:34]
endmodule
```

## A Simple Arbitration
- Just a display of simple boolean logic and pass-through wiring

```scala
class Arbiter extends Module {
  val io = IO(new Bundle {
    // FIFO
    val fifo_valid = Input(Bool())
    val fifo_ready = Output(Bool())
    val fifo_data  = Input(UInt(16.W))
    
    // PE0
    val pe0_valid  = Output(Bool())
    val pe0_ready  = Input(Bool())
    val pe0_data   = Output(UInt(16.W))
    
    // PE1
    val pe1_valid  = Output(Bool())
    val pe1_ready  = Input(Bool())
    val pe1_data   = Output(UInt(16.W))
  })

  io.fifo_ready := io.pe0_ready || io.pe1_ready
  io.pe0_valid := io.fifo_valid && io.pe0_ready
  io.pe1_valid := io.fifo_valid && io.pe1_ready && !io.pe0_ready
  io.pe0_data := io.fifo_data
  io.pe1_data := io.fifo_data
}
```

- Generated Verilog:

```verilog
module Arbiter(
  input         clock,
  input         reset,
  input         io_fifo_valid,
  output        io_fifo_ready,
  input  [15:0] io_fifo_data,
  output        io_pe0_valid,
  input         io_pe0_ready,
  output [15:0] io_pe0_data,
  output        io_pe1_valid,
  input         io_pe1_ready,
  output [15:0] io_pe1_data
);
  assign io_fifo_ready = io_pe0_ready | io_pe1_ready; // @[cmd13.sc 19:33]
  assign io_pe0_valid = io_fifo_valid & io_pe0_ready; // @[cmd13.sc 20:33]
  assign io_pe0_data = io_fifo_data; // @[cmd13.sc 22:15]
  assign io_pe1_valid = io_fifo_valid & io_pe1_ready & ~io_pe0_ready; // @[cmd13.sc 21:49]
  assign io_pe1_data = io_fifo_data; // @[cmd13.sc 23:15]
endmodule
```
