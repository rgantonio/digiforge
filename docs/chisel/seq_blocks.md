# Sequential Building Blocks
- These are where the registers come in.
- Mostly dependent on circuits where outputs are dependent on inputs and previous values. AKA memory.

## Registers
- Revisit the `basic_components.md` tutorial for how we declare registers.
- Chisel's default declartion of a register with no reset:

```scala
val q = RegNext(d)
```

- Chisel automatically has a clock declared in it so no need to write the clock
- Alternative declaration of register is:

```scala
val delayReg = Reg(UInt(4.W))
delayReg := delayIn
```

- Register with reset signal uses `RegInit`
- By default, reset is synchronous in Chisel

```scala
val valReg = RegInit(0.U(4.W))
valReg := inVal
```

- Register with enable capture:

```scala
val enableReg = Reg(UInt(4.W))

when(enable){
    enableReg := inVal
}
```

- Chisel also has the `RegEnable`, as an alternative shortcut.

```scala
val enableReg2 = RegEnable(inVal, enable)
```

- If you want it to reset you can do either of the two

```scala
val resetEnableReg = RegInit(0.U(4.W))

when(enable){
    resetEnableReg := inVal
}
```

```scala
val resetEnableReg2 = RegEnable(inVal, 0.U(4.W), enable)
```

- A more situational case is when a register can be part of an expression at the same time:

```scala
val risingEdge = din & !RegNext(din)
```

## Counters

- We built this before but introduced here again:

```scala
val cntReg = RegInit(0.U(4.W))
cntReg := cntReg + 1.U
```

- We can count events as well:

```scala
val cntEventsReg = RegInit(0.U(4.W))
when(event){
    cntEventsReg := cntEventsReg + 1.U
}
```

- Counting up and down is basic too.
- Note that the default exists, then the next `when()` overwrites it.


```scala
val cntReg = RegInit(0.U(8.W))

cntReg := cntReg + 1.U

when(cntReg === N){
    cntReg := 0.U
}
```

- Can also use a multiplexer for the counter:

```scala
val cntReg = RegInit(0.U(8.W))

cntReg := Mux(cnt_reg === N, 0.U, cntReg + 1)
```

- If we want to count down, then it's just a matter of reversing the count. Start with `N`

```scala
val cntReg = RegInit(N)
cntReg := cntReg - 1.U
when(cntReg === 0.U){
    cntReg := N
}
```

- Now is a nice time to introduce about functions. If we want to create more counters we can:

```scala
// Function returns a counter
def genCounter(n: Int) = {
    val cntReg := RegInit(0.U(8.W))
    cntReg := Mux(cntReg === n.U, 0.U, cntReg + 1.U)
    cntReg
}

// Can easily create many counters
val count10 = genCounter(10)
val count99 = genCounter(99)
```

- Note that the last statement of the function is the return value. Here, we return the counter.

## Counter Ticker
- This example is not really a clock divider but an enable trigger to when updates must be made. It's like a virtual clock divider because we don't drive the clock directly.

```scala
// Let this be the ticker
val tickCounterReg = RegInit(0.U(32.W))
val tick = tickCounterReg === (N-1).U
tickCounterReg := tickCounterReg + 1.U
when (tick) {
    tickCounterReg := 0.U
}

// This one ticks when the end of the other happens
val lowFrequCntReg = RegInit(0.U(4.W))
when (tick) {
    lowFrequCntReg := lowFrequCntReg + 1.U
}
```

- Counting up or down needed a comparison against all counting bits so far. What if we count from N-2 down to -1? A negative number has the most significant bit set to 1, and a positive number has this to 0. We must only check this bit to detect that our counter reached -1.
- Nerd counter:

```scala
val MAX = (N - 2).S(8.W)
val cntReg = RegInit(MAX)
io.tick := false.B
cntReg := cntReg - 1.S
when(cntReg(7)) {
    cntReg := MAX
    io.tick := true.B
}
```

## Timer
- This is a one-shot timer:

```scala
val cntReg = RegInit(0.U(8.W))
val done = cntReg === 0.U
val next = WireDefault(0.U)
when (load) {
    next := din
} .elsewhen (!done) {
    next := cntReg - 1.U
}
cntReg := next
```

## Pulse-Width Modulation
- PWM is periodic but with the high state or level at a different high time compared to the low time.
- Useful for certain applications especially in communications.
- `unsignedBitLength()` is a function that specifices the number of bits required to set the counter cntReg. A useful Chisel function like the `$log2()` in System Verilog.
- Chisel also has the `signedBitLength` equivalent for a signed value instead. Usually 1 extra bit more.
- The last line of the function compares the counter value with the input value `din` to return the PWM signal. 
- The last expression in a Chisel function is the return value, the wire connected to the compare function.
- It's a bit weird to embrace the concept that the output of a function can be a wire. It is so implicative because sometimes it can be the actual hardware, or it can be the wire and hardware at the same time.
- But I think in general it is easier to remember that the return of the function returns the wire output to be used.

```scala
def pwm(nrCycles: Int, din: UInt) = {
    val cntReg = RegInit(0.U(unsignedBitLength(nrCycles -1).W))
    cntReg := Mux(cntReg === (nrCycles -1).U, 0.U, cntReg + 1.U)
    // This outputs a wire
    din > cntReg
}
val din = 3.U
// Connect that 1-bit wire into the dout signal
val dout = pwm(10, din)
```

- Here is an example for dimming LEDs where PWM matters:

```scala
val FREQ = 100000000 // a 100 MHz clock input
val MAX = FREQ/1000 // 1 kHz

val modulationReg = RegInit(0.U(32.W))
val upReg = RegInit(true.B)

// This is like the updating of the always @ (posedge) registers
// Notice that the registers don't need to be completely specified
// If it doesn't have any, it retains the state based on its last update
// for as long as the conditions are not satisfies yet 
when (modulationReg < FREQ.U && upReg) {
    modulationReg := modulationReg + 1.U
} .elsewhen (modulationReg === FREQ.U && upReg) {
    upReg := false.B
} .elsewhen (modulationReg > 0.U && !upReg) {
    modulationReg := modulationReg - 1.U
} .otherwise { // 0
    upReg := true.B
}

// divide modReg by 1024 (about the 1 kHz)
val sig = pwm(MAX, modulationReg >> 10)
```

## Shift Registers
- It's a collection of flip-flops connected in sequence.

```scala
// Create 4-bit shift reg
val shiftReg = Reg(UInt(4.W))
// On every date, concatenate the {shiftReg[2:0], din}
shiftReg := shiftReg(2, 0) ## din
// The MSB is shifted into the output
val dout = shiftReg(3)
```

- Shift register with parallel output.
- This is more of a serial to parallel block.

```scala
val outReg = RegInit(0.U(4.W))
outReg := serIn ## outReg(3, 1)
val q = outReg
```

- Shifter register with a parallel load

```scala
val loadReg = RegInit(0.U(4.W))
when (load) {
    loadReg := d
} otherwise {
    loadReg := 0.U ## loadReg(3, 1)
}
val serOut = loadReg(0)
```

## Memory

- Chisel actually implements a memory.
- In this, suppose read and write are in the same cycle for the same address, the output of the read was the previous data first and the write writes after. It happens in many SRAMs actually.

```scala
class Memory() extends Module {
    val io = IO(new Bundle {
        val rdAddr = Input(UInt(10.W))
        val rdData = Output(UInt(8.W))
        val wrAddr = Input(UInt(10.W))
        val wrData = Input(UInt(8.W))
        val wrEna = Input(Bool())
    })
    // Memory module
    val mem = SyncReadMem(1024, UInt(8.W))
    io.rdData := mem.read(io.rdAddr)
    when(io.wrEna) {
        mem.write(io.wrAddr , io.wrData)
    }
}
```

- This is the version where we forward the write:

```scala
class ForwardingMemory() extends Module {
    val io = IO(new Bundle {
        val rdAddr = Input(UInt(10.W))
        val rdData = Output(UInt(8.W))
        val wrAddr = Input(UInt(10.W))
        val wrData = Input(UInt(8.W))
        val wrEna = Input(Bool())
    })

    val mem = SyncReadMem(1024, UInt(8.W))
    val wrDataReg = RegNext(io.wrData)
    val doForwardReg = RegNext(io.wrAddr === io.rdAddr && io.wrEna)
    val memData = mem.read(io.rdAddr)

    when(io.wrEna) {
        mem.write(io.wrAddr , io.wrData)
    }
    io.rdData := Mux(doForwardReg , wrDataReg , memData)
}
```

- Chisel actually provides the appropriate model or behaviours for this.
- `Writefirst` means it writes first then the read follows after.
- `ReadFirst` means it reads first.
- `Undefined` gives undefined result.

```scala
val mem = SyncReadMem(1024, UInt(8.W), SyncReadMem.WriteFirst)
```

- Chisel also provides the equivalent of `$readmemb` and `$readmemh`

```scala
val hello = "Hello , World!"
val helloHex = hello.map(_.toInt.toHexString).mkString("\n")
val file = new java.io.PrintWriter("hello.hex")
file.write(helloHex)
file.close()

val mem = SyncReadMem(1024, UInt(8.W))
loadMemoryFromFileInline(mem, "hello.hex", firrtl.annotations.MemoryLoadFileType.Hex)
```

