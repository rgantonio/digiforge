# Input Processing
- Getting data from an asynchronous input to a synchronous one that digital cricuits can process.

## Asynchronous Input
- A common one is the 2-FF synchronizer.
- The code below is one and assume that the button `btn` is an asynchronous signal.

```scala
val btnSync = RegNext(RegNext(btn))
```

## Debouncing

- Useful for switches or push buttons because when you press the signal, it toggles fast for a certain amount of time, so we need to filter it.
- In the example below, `btnSync` is an asynchronous input.

```scala
// From 1MHz to a 100 Hz
val fac = 100000000/100

val btnDebReg = Reg(Bool())
val cntReg = RegInit(0.U(32.W))
val tick = cntReg === (fac - 1).U

cntReg := cntReg + 1.U
when (tick) {
    cntReg := 0.U
    btnDebReg := btnSync
}
```

## Further Filtering of Input Signal
- Here is an example where we have further filtering via a majority vote.
- `btnDebReg` once debounced we further in a fast frequency synchronize it further with shift registers.
- Majority of the 3-bit is a 1 then it is overall clean.

```scala
val shiftReg = RegInit(0.U(3.W))
when (tick) {
    // shift left and input in LSB
    shiftReg := shiftReg(1, 0) ## btnDebReg
}
// Majority voting
val btnClean = (shiftReg(2) & shiftReg(1)) | (shiftReg(2) & shiftReg(0)) | (shiftReg(1) & shiftReg(0))
```

- Then we further process the debug with a nice rising edge detector circuit.

```scala
val risingEdge = btnClean & !RegNext(btnClean)
// Use the rising edge of the debounced and
// filtered button to count up
val reg = RegInit(0.U(8.W))
when (risingEdge) {
    reg := reg + 1.U
}
```

## Combining Input Processing with Other Functions
- When we create functions, it is as if we can generate them per function call.

```scala
// 2FF sync
def sync(v: Bool) = RegNext(RegNext(v))

// Rising edge detector
def rising(v: Bool) = v & !RegNext(v)

// Tick generator that samples at lower freq
// Note that fac is a variable defined at top most
// It is assumed that way 
def tickGen() = {
    val reg = RegInit(0.U(log2Up(fac).W))
    val tick = reg === (fac -1).U
    reg := Mux(tick , 0.U, reg + 1.U)
    tick
}

// Majority filter
def filter(v: Bool , t: Bool) = {
    val reg = RegInit(0.U(3.W))
    when (t) {
        reg := reg(1, 0) ## v
    }
    (reg(2) & reg(1)) | (reg(2) & reg(0)) | (reg(1) & reg(0))
}

// Function calls
// Synchronize button unsynched
val btnSync = sync(io.btnU)

// Tick
val tick = tickGen()

// Note that the tick output from the tickGen()
// and the btnSync is the synchronized button
val btnDeb = Reg(Bool())
when (tick) {
    btnDeb := btnSync
}

// Majotiry filter
val btnClean = filter(btnDeb , tick)

// Rising edge capture
val risingEdge = rising(btnClean)

// Use the rising edge of the debounced
// and filtered button for the counter
val reg = RegInit(0.U(8.W))
when (risingEdge) {
    reg := reg + 1.U
}
```

## Synchronizing Reset

- Reset synchronization is also important to reduce reset recall problems.
- Essentially, the metastability on the reset signal.
- The reset and clock signals are by default not directly listed but it's always present.
- Simply connect the reset signal from the module.

```scala
class SyncReset extends Module {
    val io = IO(new Bundle() {
        val value = Output(UInt())
    })
    // Reset synchronizer
    val syncReset = RegNext(RegNext(reset))
    // Assume a WhenCounter module that literally counts to 5
    val cnt = Module(new WhenCounter(5))
    // Here we simply connect the reset of the module
    cnt.reset := syncReset
    io.value := cnt.io.cnt
}
```