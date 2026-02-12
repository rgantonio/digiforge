# Combinational Building Blocks

- Various combinational circuits

## Combinational Circuits
- Boolean expression. Straightforward.
- However, these expressions are fixed.
- Re-assignment results in an error.

```scala
val e = (a & b) | c
val f = ˜e
```

- Describing combinational circuits with conditional updates.
- Such a circuit is declared as a `Wire`. Think the `always_comb` block.
- Consider the code below where `w` had a default value, but because of the condition, it ends up being a multiplexer to select `0.U` or `3.U`

```scala
val w = Wire(UInt())
w := 0.U
when (cond) {
    w := 3.U
}
```

- Chisel construct `when()` has its "else" counterpart called `.otherwise`

```scala
val w = Wire(UInt())
when (cond) {
    w := 1.U
} .otherwise {
    w := 2.U
}
```

- There is an equivalent `elif` as `.elsewhen`.
- This creates a chain of multiplexers.

```scala
val w = Wire(UInt())
when (cond) {
    w := 1.U
} .elsewhen (cond2) {
    w := 2.U
}.otherwise {
    w := 3.U
}
```

- Note that `when`, `.elsewhen`, and `.otherwise` are all multiplexer hardware equivalents.
- Scala has `if`, `else if`, and `else` but they are used for conditional ways to generate hardware.

## Decoder

- Converts a binary number of n-bits to m-bits where $m \leq 2^n$ 
- Use chisel switch statement to make decoders.
- Don't forget to use `chisel.util._`
- Note that even if we enumerate all possible input values, Chisel still needs us to assign a default value, as we do by assigning an initial 0 to result.

```scala
import chisel.util._

result := 0.U
switch(sel) {
    is (0.U) { result := 1.U}
    is (1.U) { result := 2.U}
    is (2.U) { result := 4.U}
    is (3.U) { result := 8.U}
}
```

## Encoder
- Converts 1-hot code to a specific binary code
- Technically inverse of decoder

```scala
b := "b00".U

switch(sel){
    is("b0001".U) { b := "b00".U }
    is("b0010".U) { b := "b01".U }
    is("b0100".U) { b := "b10".U }
    is("b1000".U) { b := "b11".U }
}
```

- This one is cumbersome to write if we need to write more. 
- We can use scala to "automate" this thing.
- Use the "for loop" of scala


```scala
// Loops i from 0 to 9
for (i <- 0 until 10) {
    // use i to index into a Wire or Vec
}
```

- Loop variable `i` can index bits from a `Wire` or `Reg` or an element of a `Vec`
- Note that loop is a circuit generation time and not a counter.
- The code below is a 16-to-4 encoder.
- Note that the input is named `hotIn` and the output is `encOut`. But taken out just for simplicity.

```scala
val v = Wire(Vec(16, UInt(4.W)))
v(0) := 0.U
for (i <- 1 until 16) {
    // If element hotIn(i) is 1,
    // set the output element v(i) to the value of the index
    // then the |v(i-1) is to do an OR reduction
    // to combien all elements into 1 output
    v(i) := Mux(hotIn(i), i.U, 0.U) | v(i - 1)
}
val encOut = v(15)
```

## Arbiter
- We use arbiter to arbitrate requests from several clients to a shared resource.
- It's a priority arbiter.
- See the figure below:

![alt text](image.png)

- Suppose request `r = {0101}` then the grant is `g = {0001}`.
- Bit position of request is the requestor, and grant is the grantor.
- The priority arbiter prioritizes LSBs.

```scala
val grant = VecInit(false.B, false.B, false.B)
val notGranted = VecInit(false.B, false.B)

grant(0) := request(0)
notGranted(0) := !grant(0)
grant(1) := request(1) && notGranted(0)
notGranted(1) := !grant(1) && notGranted(0)
grant(2) := request(2) && notGranted(1)
```

- Alternatively, one can also encode it this way:

```scala
val grant = WireDefault("b0000".U(3.W))
switch (request) {
    is ("b000".U) { grant := "b000".U}
    is ("b001".U) { grant := "b001".U}
    is ("b010".U) { grant := "b010".U}
    is ("b011".U) { grant := "b001".U}
    is ("b100".U) { grant := "b100".U}
    is ("b101".U) { grant := "b001".U}
    is ("b110".U) { grant := "b010".U}
    is ("b111".U) { grant := "b001".U}
}
```

- If it's small it's doable. But if it's big, we need some tricks:

```scala
val grant = VecInit.fill(n)(false.B)
val notGranted = VecInit.fill(n)(false.B)
grant(0) := request(0)
notGranted(0) := !grant(0)
for (i <- 1 until n) {
    grant(i) := request(i) && notGranted(i-1)
    notGranted(i) := !grant(i) && notGranted(i-1)
}
```

## Comparators

- One of the most common units in digital design. Literally, for comparison purposes.

```scala
val equ = a === b
val gt = a > b
```
