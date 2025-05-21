
# Making Modules and Testbenches

## Template for Any Module

- The module is always some class with `extends Module`
- The parameters sent into the class are after the class description: `width: Int`
- We declare the `io` using the `val io = IO(new Bundle{})`
  - Then inside this we have the port names and their widths
  - e.g. `val in = Input(UInt(width.W))`
- Note that they are declared as `val` because they are fixed *values* or *parameters*

```scala
class PassthroughGenerator(width: Int) extends Module { 
  val io = IO(new Bundle {
    val in = Input(UInt(width.W))
    val out = Output(UInt(width.W))
  })
  //----------------------------------
  // Insert whatever code is in here
  //----------------------------------
}
```

## Template for Making Tests

- They are always within a `test(new <insert module class>)`
- The `c` in here is like the `DUT` in Verilog
- You apply a stimulus with `poke`
- You check the value with `expect`. The `expect` is automatically an assertion already.
- If you want to just read the value you use `peek`.
- Take note that when you place values, they need to be type casted
  - e.g. `1.U` is unsigned 1, then later you see `2.S` which is signed
  - The inputs, outputs, and wires need to have the same types

```scala
test(new Passthrough()) { c =>
    c.io.in.poke(0.U)     // Set our input to value 0
    c.io.out.expect(0.U)  // Assert that the output correctly has 0
    c.io.in.poke(1.U)     // Set our input to value 1
    c.io.out.expect(1.U)  // Assert that the output correctly has 1
    c.io.in.poke(2.U)     // Set our input to value 2
    c.io.out.expect(2.U)  // Assert that the output correctly has 2
}
println("SUCCESS!!") // Scala Code: if we get here, our tests passed!
```