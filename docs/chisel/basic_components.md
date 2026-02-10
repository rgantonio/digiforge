# Basic Components
- Here we learn some shortcuts to basic components in Chisel

## Chisel Types and Constants
- Describe connections for combinational logic and registers.
- Bits, UInt, SInt which are respectively quite idiomatic for their meaning.
- Chisel uses 2's complement for SInt
- Warning that the Bits type is missing operations and not really gonna be useful in several cases...

```scala
Bits(8.W)  // 8-bit bits
UInt(8.W)  // 8-bit unsigned
SInt(10.W) // 10-bit signed
```

- Constants can be defined using Scala integers and converting it to a Chisl type

```scala
 0.U // Creates a 0 unsigned constant
-3.S // Creates a -3 signed constant

// A 4-bit constant of unsigned 3
 3.U(4.W)
```

- Becareful not to miss the .W because if you do, what happens is that it selects the bit position at that case. For example, `1.U(32)` simply gets the 32-th position which is 0.

- Scala has the capability to infer data types, and bit-widths so you don't need to count the bit-widths manually.

- The examples below are the non-decimal ways of representing 255. You simply encapsulate them in quotations `" "`.

- Scala automatically infers data widths from these.

```scala
"hff".U
"o377".U
"b1111_1111".U
```

- Characters to represent text can also be constants.

```scala
val aChar = 'A'.U
```

- There is also boolean declaration

```scala
Bool()
true.B
false.B
```

## Combinational Circuits

- Boolean logic are just like in any programming language.
- The bit-width of variables are inferred in Chisel.
- In the examples below, we don't know if they are single-bit or multi bit.

```scala
val logic = (a & b) | c
val and = (a & b)
val or = (a | b)
val xor = (a ^ b)
val not = ~a
```

- Arithmetic operations are standard too.
- The resulting width is the max width of the operators for add and sub.
- Sum of the two widths of the operands in multiplication.
- Width of numberator for div and modulo.

```scala
val add = a + b
val sub = a - b
val neg = -a
val mul = a * b
val div = a / b
val mod = a % b
```

- A signal can be defined as a wire of some type.
- Assign a value with `:=` operator.

```scala
val w = Wire(UInt())
w := a & b
```

- Single bit can be extracted as follows.
- This grabs the 31st bit.

```scala
val sign = x(31)
```

- Subfields or slices can be extracted from end to start position.

```scala
val lowByte = largeWord(7,0)
```

- Bit fields are concatenated with the `##` operator.

```scala
val word = highByte ## lowByte
```

- Below is a list of builtin operators in Chisel:

![alt text](image.png)


- Below is a list of various functions:

![alt text](image-1.png)

- One of the most common mechanisms in digital logic design is the multiplexer
- a is selected when sel is `true.B`; b otherwise

```scala
val result = Mux(sel, a, b)
```

## Registers

- The most basic sequential and memory element.
- Implicitly connected to a global clock with rising edge update.
- Uses a synchronous reset signal, to a global reset signal.
- Reset value can be configured.
- Code below defines an 8-bit registers, initialized to 0 at reset.

```scala
val reg = RegInit(0.U(8.W))
```

- Input is connected to the reg with the `:=` operator
- Output can be used with just the name of the registers

```scala
reg := d     // input to reg
val q = reg  // output from reg
```

- A register can be connected to its input during declaration
- Also a version where an initial value is also defined during reset
- In most cases, it is better to postfix `Reg` at the end of the name to distinguish a register from a combinational signal.

```scala
val nextReg = RegNext(d)
val bothReg = RegNext(d, 0.U)
```

- It is best to use CamelCase for scala.
- Start functions and variables with lower case.
- Start types with upper case.


### Counters
- Counters are a fundamental block in digital circuits.
- The following examples counts from 0 to 9 and wraps around when it overflows from 9.
- Notice that constants need to be declared correctly.

```scala
val cntReg = RegInit(0.U(8.W))
cntReg := Mux(cntReg == 9.U, 0.U, cntReg + 1.U)
```


## Structure with Bundle and Vec

- Chisel's means to group signals together
- `Bundle`: groups signals fo different types as named fields.
- `Vec`: represents an indexable collection of signals (elements) of the same type. This are like the buses.
- Both create new Chisel types and can be arbitrarily nested.

### Bundle
- Similar to struct in C or SystemVerilog
- To use a bundle, create it with new and wrap it into a wire
- Fields are accessed with `.` notation

```scala
class Channel() extends Bundle {
    val data = UInt(32.W)
    val valid = Bool()
}

// Create the wire
val ch = Wire(new Channel())

// Channel assignments
ch.data := 123.U
ch.valid := true.B

// Putting channel into a variable
val b = ch.valid
```

- Note that a bundle can also be referenced or assigned as a whole:

```scala
val channel = ch
```

### Vec
- Collection of chisel types of the same type
- Used for (1) dynamic address in hardware, (2) a register file, and (3) parametrization of the number of ports of a module
- For other collections of things, it is better to use the scala collection `Seq`

#### Combinational Sec

- A combinational Vec needs to be wrapped into a Wire
- Below creates a set of 3 4-bit unsigned int elements
- Individual elements are accessed with `(index)`
- A vector wrapped into a wire is just a multiplexer

![alt text](image-2.png)

```scala
val v = Wire(Vec(3, UInt(4.W)))

// Assignments towards the inputs of the MUX
v(0) := 1.U // x
v(1) := 3.U // y
v(2) := 5.U // z

// index is like a wire set to 2'b01
val index = 1.U(2.W)
// a gets the selection of the mux v
val a = v(index)
```

- Another example as a mux

```scala
// Selection of 3 8-bit unsigned elements
val m = Wire(Vec(3, UInt(8.W)))

// Assignment of variables
m(0) := x
m(1) := y
m(2) := z

val muxOut = m(select)
```

- Similar to WireDefault, we can set Vec with VecInit for default values
- VecInit already returns Chisel hardware so no need to wrap in a Wire
- The 1st constant is specified to be 3 bits
- With the `cond` condition, we overwrite those default values
- I feel like this part is confusing and I would avoid such technique

```scala
val defVec = VecInit(1.U(3.W), 2.U, 3.U)

when (cond) {
    defVec(0) := 4.U
    defVec(1) := 5.U
    defVec(2) := 6.U
}

val vecOut = defVec(sel)
```

- Another example:

```scala
val defVecSig = VecInit(d, e, f)
val vecOutSig = defVecSig(sel)
```

#### Regsiter Vec

- Possible to wrap Vec into a register to define an array of registers
- Schematic below describes this

```scala
// Create the array of registers
val vReg = Reg(Vec(3, UInt(8.W)))

// Imagine the "read" index
val dout = vReg(rdIdx)

// wrIdx is like write index
vReg(wrIdx) := din
```

![alt text](image-3.png)



- A register of a vector can also be initialized during reset
- Use VecInit for this with constants for the reset wrappes into RegInit as well

```scala
val initReg = RegInit(VecInit(0.U(3.W), 1.U, 2.U))
val resetVal = initReg(sel)

initReg(0) := d
initReg(1) := e
initReg(2) := f
```

- To reset all elements of a large register file to the same value (like 0), use Scala's sequence `Seq`
- VecInit can be constructed with a sequence of Chisel types
- `Seq` contains a creation function fill to initialize a sequence with identical values

```scala
// Read this as initialize registers, initialize vector,
// with a sequence fill of 32 repetitions of 0 values
// but each element is 32 bits wide
val resetRegFile = RegInit(VecInit(Seq.fill(32)(0.U(32.W))))
val rdRegFile = resetRegFile(sel)
```

### Combining Bundle and Vec

- Freely mix bundles and vectors
- Using a channel one can make a vector of channels with:

```scala
// Create channel bundle first
class Channel() extends Bundle {
    val data = UInt(32.W)
    val valid = Bool()
}

// So make a vector of 8 channel bundles
val vecBundle = Wire(Vec(8, new Channel()))
```

- Bundle itself can contain a vector:

```scala
// The vector field creates a vector of 4 8-bit elements
class BundleVec extends Bundle {
    val field = UInt(8.W)
    val vector = Vec(4, Uint(8.W))
}
```

- Creating a register of a bundle type that needs a reset value
- Create a wire of the bundle first, then set the fields as needed, then pass the bundle to `RegInit`

```scala
// Assuming we use the same channel definition again
val initVal = Wire(new Channel())

// Set default values
initVal.data = 0.U
initVal.valid = false.B

// Essentially a register with the channel definitions
val channelReg = RegInit(initVal)
```

> WARNING: Partial assignments is not allowed in Chisel 3!

- Consider the following code below
- That is not allowed in Chisel 3
- It is best to assign an explicit bundle instead as encouraged more

```scala
val assignWord = Wire(Uint(16.W))

assignWord(7,0) = lowByte
assignWord(15,8) = highByte
```

- If you insist on such structure, there is a long work around
- Create local bundle, create wire from that bundle, assign the fields, cast the bundle with asUint to a UInt

```scala
val assignWord = Wire(Uint(16.W))

class Split extends Bundle{
    val high = UInt(8.W)
    val low = UInt(8.W)
}

val split = Wire(new Split())
split.low := lowByte
split.high := highByte

assignWord := split.asUInt
```

## Wire, Reg, and IO

- UInt, SInt, and Bits are just data types but they don't correspond to a hardware
- You need to wrap them into Wire, Reg, or IO to generate actual hardware
- `Wire` represents combinational logic (think of the `always @ posedge` procedure blocks)
- `Reg` represents registers
- `IO` represents ports for connection of a module
- Give the hardware a component name by assigning it to a Scala immutable variable

```scala
val number = Wire(Uint())
val reg = Reg(SInt())
```

- Then assign a value or expression to the Wire, Reg, or IO with `:=`

```scala
number := 10.U
reg := value - 3.U
```

- Note when we use `=` and `:=`
- The `=` makes a hardware name assignment, while `:=` assigns values

> Combinational values can be conditionally assigned but they need to be assigned in every branch of the condition otherwise a latch would appear. Chisel will automatically reject this!

- Best practice is to create a default value of the wire just in case
- Although I fear this might be tricky as a Verilog user but I guess it just needs getting used to

```scala
val number = WireDefault(10.U(4.W))
```

- Best practice to set registers to known values. Most effective are registers and not necessarily the wires.

```scala
// Signed registers but by default at 0
// Registers are 8-bits
val reg = RegInit(0.S(8.W))
```


