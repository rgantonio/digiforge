# Hardware Generation Capabilities

- Some notes about how scala becomes a nice hardware generator.
- Also some notes a beginner should know about Scala.

## Some Scala Basics
- `val` gives an expression a name and cannot be changed, while `var` is the opposite.
- In the code below, the bits of a shift register connect to each other. The variable `i` is a `var`:

```scala
val regVec = Reg(Vec(8, UInt(1.W)))
regVec(0) := io.din
for (i <- 1 until 8) {
    regVec(i) := regVec(i-1)
}
```

- Scala has `if` and `else` conditions but these do not create MUXes, but rather they are meant to be conditional generators:

```scala
for (i <- 0 until 10) {
    print(i)
    if (i%2 == 0) {
        println(" is even")
    } else {
        println(" is odd")
    }
}
```

- Scala has `tuples` as well.
- Elements are accessible with the `._` followed by the index

```scala
val city = (2000, "Frederiksberg")
val zipCode = city._1
val name = city._2
```

- Tuples are useful when we want to return more than one value from a function.
- Tuples allow us to represent Chisel components with more than one output as a lightweight function instead of a full-blown module.

- Scala also has `Seq` like a `list` in Python:

```scala
val numbers = Seq(1, 15, -2, 0)
val second = numbers(1)
```

## Lightweight Components with Functions
- Consider the adder generator.
- Then we create 2 instances of seperate adders.

```scala
def adder (x: UInt , y: UInt) = {
    x + y
}

val x = adder(a, b)
// another adder
val y = adder(c, d)
```

- The example below is a register delay:

```scala
def delay(x: UInt) = RegNext(x)
```

- Then we can make a 2-FF delay:

```scala
val delOut = delay(delay(delIn))
```

- Suppose we need functions with multiple outputs, we can use `tuples` at the last line.
- Then we can access the data from a single tuple return or return to tuples as well.

```scala
def compare(a: UInt , b: UInt) = {
    val equ = a === b
    val gt = a > b
    (equ, gt)
}

val cmp = compare(inA, inB)
val equResult = cmp._1
val gtResult = cmp._2

val (equ, gt) = compare(inA, inB)
```

## Generate Combinational Logic

- A read only memory can be built as:

```scala
val squareROM = VecInit(0.U, 1.U, 4.U, 9.U, 16.U, 25.U)
val square = squareROM(n)
```

- Another example is a binary-coded decimal. So it's like given a binary input, the output is the value of the decimal but each chunk is a number.
- For example, the binary of number `13` is `1101` and the output of the BCD encoder would be `0001_0011`.

```scala
import chisel3._
class BcdTable extends Module {
    val io = IO(new Bundle {
        val address = Input(UInt(8.W))
        val data = Output(UInt(8.W))
    })
    val table = Wire(Vec(100, UInt(8.W)))
    // Convert binary to BCD
    for (i <- 0 until 100) {
        table(i) := (((i/10) <<4) + i%10).U
    }
    io.data := table(io.address)
}
```

## File Reading

- We can generate alogic table from a Scala array.
- Like it can come from a file.

```scala
import chisel3._
import scala.io.Source //You need this part

class FileReader extends Module {
    val io = IO(new Bundle {
        val address = Input(UInt(8.W))
        val data = Output(UInt(8.W))
    })
    val array = new Array[Int](256)
    var idx = 0
    // read the data into a Scala array
    val source = Source.fromFile("data.txt")
    for (line <- source.getLines()) {
        array(idx) = line.toInt
        idx += 1
    }
    // convert the Scala integer array to a Seq
    // and then into a vector of Chisel UInt
    val table = VecInit(array.toIndexedSeq.map(_.U(8.W)))
    // use the table
    io.data := table(io.address)
}
```

- In the above, the `toIndexedSeq` converts Scala array to Scala sequence. Recall that the sequence is like the list. For some magical reason array and lists have distinctions.
- The `_.U(8.W)` converts each element in the array to a Chisel UInt type first of 8-bits then places it into a sequence to wich is later declared as a `VecInit`.


## Type Conversion

- For example packing 4 bytes into a single 32-bit UInt:

```scala
val vec = Wire(Vec(4,UInt(8.W)))
val word = vec.asUInt
```

- The above converts by placing the LS-byte into the lower 8 bits and so on.
- We can convert back into 8-bits too.

```scala
val vec2 = word.asTypeOf(Vec(4, UInt(8.W)))
```

- It's also possible to convert `Bundle` to a `UInt`
- Of course we can also convert back to the bundle.
- Also to intialize all fields of a bundle to 0.

```scala
class MyBundle extends Bundle {
    val a = UInt(8.W)
    val b = UInt(16.W)
}

// Convert from Bundle to UInt
val bundle = Wire(new MyBundle)
val word2 = bundle.asUInt

// Convert UInt to bundle
val bundle2 = word2.asTypeOf(new MyBundle)

// The version where all values are initialized to 0
val bundle3 = 0.U.asTypeOf(new MyBundle)
```

## Configurations with Parameters
- Parametric designs are powerful. Chisel supports this greatly.
- Then we instantiate and input the parameter as arguments.

```scala
class ParamAdder(n: Int) extends Module {
    val io = IO(new Bundle{
        val a = Input(UInt(n.W))
        val b = Input(UInt(n.W))
        val c = Output(UInt(n.W))
    })
    io.c := io.a + io.b
}

val add8 = Module(new ParamAdder(8))
val add16 = Module(new ParamAdder(16))
```

## Functions with Type Parameters
- The expression in the square brackets `[T <: Data]` defines a type parameter `T` that is `Data` or a subclass of `Data`. `Data` is the root of the Chisel type system.
- The Mux has 3 parameters, the sel of type `Bool`, the tpath and the fpath both of which are type `T`
- The type `T` is `Data` that is flexible. Hence in the examples below we can instantiate different data types for the selection.

```scala
def myMux[T <: Data](sel: Bool , tPath: T, fPath: T): T = {
    val ret = WireDefault(fPath)
    when (sel) {
        ret := tPath
    }
    ret
}
// Same unsigned
val resA = myMux(selA , 5.U, 10.U)

// The other one is signed
val resErr = myMux(selA , 5.U, 10.S)
```

- Another example is:

```scala
class ComplexIO extends Bundle {
    val d = UInt(10.W)
    val b = Bool()
}

// This is one type for the tval
val tVal = Wire(new ComplexIO)
tVal.b := true.B
tVal.d := 42.U

// Here is the other with different values
val fVal = Wire(new ComplexIO)
fVal.b := false.B
fVal.d := 13.U

// The multiplexer with a complex type
val resB = myMux(selB , tVal , fVal)
```

## Modules with Type Parameters

- Useful, for example, for cases where we want different channel definitions on an AXI network.

```scala
class NocRouter[T <: Data](dt: T, n: Int) extends Module {
    val io =IO(new Bundle {
    val inPort = Input(Vec(n, dt))
    val address = Input(Vec(n, UInt(8.W)))
    val outPort = Output(Vec(n, dt))
    })
    // Route the payload according to the address
    // ...
}

// First define Bundle type
class Payload extends Bundle {
    val data = UInt(16.W)
    val flag = Bool()
}

// Use that new Payload type
val router = Module(new NocRouter(new Payload , 2))
```

## Parametrized Bundles
- The same concept goes to the Bundles too

```scala
class Port[T <: Data](dt: T) extends Bundle {
    val address = UInt(8.W)
    val data = dt.cloneType
}
```

- One can make the parameter private. The only difference is that the previous one is accessible via `p.dt` while the other will not return it.

```scala
class Port[T <: Data](private val dt: T) extends Bundle {
    val address = UInt(8.W)
    val data = dt.cloneType
}
```

- From here you can access the parametrized `Bundle` to be fed into the module ports:

```scala
class NocRouter2[T <: Data](dt: T, n: Int) extends Module {
    val io =IO(new Bundle {
        val inPort = Input(Vec(n, dt))
        val outPort = Output(Vec(n, dt))
    })
    // Route the payload according to the address
    // ...
}

val router = Module(new NocRouter2(new Port(new Payload), 2))
```

## Optional Ports
- Some hardware generators might have IO ports that are dependent on a configuration.
- As an example, we implement a register file for a typical 32-bit RISC processor.
- For debugging, we want to be able to access all registers. Therefore, we want to have an additional port where we can read all registers in the tester. 
- However, at Verilog generation, we do not want this expensive extra port.

```scala
class RegisterFile(debug: Boolean) extends Module {
    val io = IO(new Bundle {
        val rs1 = Input(UInt(5.W))
        val rs2 = Input(UInt(5.W))
        val rd = Input(UInt(5.W))
        val wrData = Input(UInt(32.W))
        val wrEna = Input(Bool())
        val rs1Val = Output(UInt(32.W))
        val rs2Val = Output(UInt(32.W))
        val dbgPort = if (debug) Some(Output(Vec(32, UInt(32.W)))) else None
    })

    val regfile = RegInit(VecInit(Seq.fill(32)(0.U(32.W))))
    io.rs1Val := regfile(io.rs1)
    io.rs2Val := regfile(io.rs2)
    when(io.wrEna) {
        regfile(io.rd) := io.wrData
    }
    if (debug) {
        io.dbgPort.get := regfile
    }
}

// Then in the tester get this
dut.io.dbgPort.get(4).expect(123.U)
```

## Using Inheritance
- Since Chisel is object-oriented language, the classes can be inherited.
- Consider the following codes:

```scala
abstract class Ticker(n: Int) extends Module {
    val io = IO(new Bundle{
        val tick = Output(Bool())
    })
}

class UpTicker(n: Int) extends Ticker(n) {
    val N = (n-1).U
    val cntReg = RegInit(0.U(8.W))
    cntReg := cntReg + 1.U
    val tick = cntReg === N
    when(tick) {
        cntReg := 0.U
    }
    io.tick := tick
}

class DownTicker(n: Int) extends Ticker(n) {
    val N = (n-1).U
    val cntReg = RegInit(N)
    cntReg := cntReg - 1.U
    when(cntReg === 0.U) {
        cntReg := N
    }
    io.tick := cntReg === N
}

class NerdTicker(n: Int) extends Ticker(n) {
    val N = n
    val MAX = (N - 2).S(8.W)
    val cntReg = RegInit(MAX)
    io.tick := false.B
    cntReg := cntReg - 1.S
    when(cntReg(7)) {
        cntReg := MAX
        io.tick := true.B
    }
}
```

- Then we can use the same test bench but to test different types of Ticker.
- The one below is like a test checker.

```scala
import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

trait TickerTestFunc {
    def testFn[T <: Ticker](dut: T, n: Int) = {
        // -1 means that no ticks have been seen yet
        var count = -1
        for (_ <- 0 to n * 3) {
            // Check for correct output
            if (count > 0)
                dut.io.tick.expect(false.B)
            else if (count == 0)
                dut.io.tick.expect(true.B)
            // Reset the counter on a tick
            if (dut.io.tick.peekBoolean())
                count = n-1
            else
                count -= 1
            dut.clock.step()
        }
    }
}
```

- Here is how we use it for the same module but different blocks in the same test bench:

```scala
class TickerTest extends AnyFlatSpec with ChiselScalatestTester with TickerTestFunc {
    "UpTicker 5" should "pass" in {
        test(new UpTicker(5)) { dut => testFn(dut, 5) }
    }
    "DownTicker 7" should "pass" in {
        test(new DownTicker(7)) { dut => testFn(dut, 7) }
    }
    "NerdTicker 11" should "pass" in {
        test(new NerdTicker(11)) { dut => testFn(dut, 11) }
    }
}
```


## Hardware Generation with Functional Programming
- Scala supports functional programming, so Chisel does as well.
- One example is the sum of a vector:

```scala
def add(a: UInt , b:UInt) = a + b
val sum = vec.reduce(add)
```

- Alternatively, we can also do:
- This creates a chain of adders.

```scala
val sum = vec.reduce(_ + _)
```

- Chisel has the `reduceTree` to make a tree of adders instead:

```scala
val sum = vec.reduceTree(_ + _)
```

## Minimum Search Example
- Here's an example to build a circuit to find the minimum value in `Vec`
- *functional literal* is used to express this circuit

```scala
(param) => function body
```

- Consider the following code:

```scala
val min = vec.reduceTree((x, y) => Mux(x < y, x, y))
```

- The functional literal of the minimum function is composed of two parameters, x and y and returns a Mux and compares the two parameters and returns the smaller one.
- Then the reduceTree makes a series of finding the minimum all throughout.

- The code below returns both the minimum value and the corresponding index:

```scala
class Two extends Bundle {
    val v = UInt(w.W)
    val idx = UInt(8.W)
}
// Mapping it to a list
val vecTwo = Wire(Vec(n, new Two()))
for (i <- 0 until n) {
    vecTwo(i).v := vec(i)
    vecTwo(i).idx := i.U
}

// Find the minimum
// Returns both the minimum value and the index
val res = vecTwo.reduceTree((x, y) => Mux(x.v < y.v, x, y))
```

## A Simple Arbitration Tree

- Consider the circuit below:

```scala
class Arbiter[T <: Data: Manifest](n: Int, private val gen: T) extends Module {
    val io = IO(new Bundle {
        val in = Flipped(Vec(n, new DecoupledIO(gen)))
        val out = new DecoupledIO(gen)
    })
    io.out <> io.in.reduceTree((a, b) => arbitrateSimp(a, b))
}

def arbitrateSimp(a: DecoupledIO[T], b: DecoupledIO[T]) = {

    val regData = Reg(gen)
    val regEmpty = RegInit(true.B)
    val regReadyA = RegInit(false.B)
    val regReadyB = RegInit(false.B)
    val out = Wire(new DecoupledIO(gen))

    when (a.valid & regEmpty & !regReadyB) {
        regReadyA := true.B
    } .elsewhen (b.valid & regEmpty & !regReadyA) {
        regReadyB := true.B
    }

    a.ready := regReadyA
    b.ready := regReadyB

    when (regReadyA) {
        regData := a.bits
        regEmpty := false.B
        regReadyA := false.B
    }

    when (regReadyB) {
        regData := b.bits
        regEmpty := false.B
        regReadyB := false.B
    }

    out.valid := !regEmpty

    when (out.ready) {
        regEmpty := true.B
    }

    out.bits := regData
    out
}

def arbitrateFair(a: DecoupledIO[T], b: DecoupledIO[T]) = {
    object State extends ChiselEnum {
        val idleA , idleB , hasA , hasB = Value
    }
    import State._

    val regData = Reg(gen)
    val regState = RegInit(idleA)
    val out = Wire(new DecoupledIO(gen))

    a.ready := regState === idleA
    b.ready := regState === idleB
    out.valid := (regState === hasA || regState === hasB)

    switch(regState) {
        is (idleA) {
            when (a.valid) {
                regData := a.bits
                regState := hasA
            } otherwise {
                regState := idleB
            }
        }

        is (idleB) {
            when (b.valid) {
                regData := b.bits
                regState := hasB
            } otherwise {
                regState := idleA
            }
        }

        is (hasA) {
            when (out.ready) {
                regState := idleB
            }
        }

        is (hasB) {
            when (out.ready) {
                regState := idleA
            }
        }
    }

    out.bits := regData
    out
}
```