# Components
- Think of this part as combining modules together
- A component has input and output wires (duh) then we connect to other components or wire them like these

## Components in Chisel are Modules
- Each module extends class `Module`
- It contains a field `io` for the interface
- Interface is defined by a `Bundle`
- Direction is given by wrapping a field with either `Input()` or `Output()`
- Consider the simple Add example:

```scala
class Adder extends Module{
    val io = IO( new Bundle {
        val a = Input(UInt(8.W))
        val b = Input(UInt(8.W))
        val y = Output(UInt(8.W))
    })

    io.y = io.a + io.b
}
```

- Consider a different example as a register:

```scala
class Register extends Module{
    val io = IO( new Bundle {
        val d = Input(UInt(8.W))
        val q = Output(UInt(8.W))
    })
    val reg = RegInit(0.U)
    reg := io.d
    io.q := reg
}
```

- Then here, we combine all components to make a counter:

```scala
class Counter extends Module{
    val io = IO( new Bundle {
        val dout = Output(UInt(8.W))
    })

    // Declaration of modules
    val add = Module(new Adder())
    val reg = Module(new Register())

    // The register output
    // Note that it automatically infers the bit-width
    // Connect to a "wire" count, note that it isn't a Wire
    val count = reg.io.q

    // Connect the adder
    add.io.a := 1.U
    add.io.b := count
    val result = add.io.y

    // Connect the mux and register input
    val next = Mux(count == 9.U, 0.U, result)
    reg.io.d := next
    
    // Assign the output
    io.dout := count
}

```

- The schematic of the above code is:

![alt text](image.png)

## Nested Components

- We can also make nested components like the one below:

![alt text](image-1.png)

- Observe that `CompA` and `CompB` are within `CompC` then of course `CompD` is outside.

- Consider the following code below which stitch these.
- Take note of the naming conventions.


```scala
class CompA extends Module {
    val io = IO(new Bundle {
        val a = Input(UInt(8.W))
        val b = Input(UInt(8.W))
        val x = Output(UInt(8.W))
        val y = Output(UInt(8.W))
    })
    // function of A
}

class CompB extends Module {
    val io = IO(new Bundle {
        val in1 = Input(UInt(8.W))
        val in2 = Input(UInt(8.W))
        val out = Output(UInt(8.W))
    })
    // function of B
}

class CompC extends Module {
    val io = IO(new Bundle {
        val inA = Input(UInt(8.W))
        val inB = Input(UInt(8.W))
        val inC = Input(UInt(8.W))
        val outX = Output(UInt(8.W))
        val outY = Output(UInt(8.W))
    })

    // create components A and B
    val compA = Module(new CompA())
    val compB = Module(new CompB())

    // connect A
    compA.io.a := io.inA
    compA.io.b := io.inB
    io.outX := compA.io.x

    // connect B
    compB.io.in1 := compA.io.y
    compB.io.in2 := io.inC
    io.outY := compB.io.out
}

class CompD extends Module {
    val io = IO(new Bundle {
        val in = Input(UInt(8.W))
        val out = Output(UInt(8.W))
    })
    // function of D
}

class TopLevel extends Module {
    val io = IO(new Bundle {
        val inA = Input(UInt(8.W))
        val inB = Input(UInt(8.W))
        val inC = Input(UInt(8.W))
        val outM = Output(UInt(8.W))
        val outN = Output(UInt(8.W))
    })
    // create C and D
    val c = Module(new CompC())
    val d = Module(new CompD())
    // connect C
    c.io.inA := io.inA
    c.io.inB := io.inB
    c.io.inC := io.inC
    io.outM := c.io.outX
    // connect D
    d.io.in := c.io.outY
    io.outN := d.io.out
}
```

## Arithmetic Logic Unit (ALU)

- ALU is usually a combinational unit with selected functions.
- Consider the code below.
- Use the `switch()` Chisel construct for case statements.
- Note that you need the `import chisel3.util._` for this.

```scala

import chisel3._
import chisel3.util._

class Alu extends Module {
    val io = IO(new Bundle {
        val a = Input(UInt(16.W))
        val b = Input(UInt(16.W))
        val fn = Input(UInt(2.W))
        val y = Output(UInt(16.W))
    })
    // some default value is needed
    io.y := 0.U
    // The ALU selection
    switch(io.fn) {
        is(0.U) { io.y := io.a + io.b }
        is(1.U) { io.y := io.a - io.b }
        is(2.U) { io.y := io.a | io.b }
        is(3.U) { io.y := io.a & io.b }
    }
}
```

## Bulk Connections

- For connecting components with multiple IO ports, Chisel provides the `<>` bulk connection operator.
- This operator connects parts of bundles in both directions.
- Chisel uses the names of the leaf fields for the connection.
- If a name is missing, it is not connected.
- Consider the example of building a pipelined processor:

```scala
class Fetch extends Module {
    val io = IO(new Bundle {
        val instr = Output(UInt(32.W))
        val pc = Output(UInt(32.W))
    })
    // ... Implementation of fetch
}

class Decode extends Module {
    val io = IO(new Bundle {
        val instr = Input(UInt(32.W))
        val pc = Input(UInt(32.W))
        val aluOp = Output(UInt(5.W))
        val regA = Output(UInt(32.W))
        val regB = Output(UInt(32.W))
    })
    // ... Implementation of decode
}

class Execute extends Module {
    val io = IO(new Bundle {
        val aluOp = Input(UInt(5.W))
        val regA = Input(UInt(32.W))
        val regB = Input(UInt(32.W))
        val result = Output(UInt(32.W))
    })
    // ... Implementation of execute
}
```

- From the above, we only need to connect them with the `<>` operator.

```scala
val fetch = Module(new Fetch())
val decode = Module(new Decode())
val execute = Module(new Execute())

fetch.io <> decode.io
decode.io <> execute.io
io <> execute.io
```

> Warning! As a classic Verilog designer, this is not something I would want... I think it is error prone if we are not careful, but it does have its benefits of automating connections if we are lazy.