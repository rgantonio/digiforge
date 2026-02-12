# Finite State Machines

- The classic controllers in digital circuit design.
- In vanilla System Verilog, we always defined this in sets where we have the register updates, the combinational circuit for the next state, then the combinational circuit for the output.
- Here is one simple FSM:

```scala
import chisel3._
import chisel3.util.

class SimpleFsm extends Module {
    val io = IO(new Bundle{
        val badEvent = Input(Bool())
        val clear = Input(Bool())
        val ringBell = Output(Bool())
    })

    // The three states
    object State extends ChiselEnum {
        val green , orange , red = Value
    }

    import State._
    // The state register
    val stateReg = RegInit(green)

    // Next state logic
    switch (stateReg) {
        is (green) {
            when(io.badEvent) {
                stateReg := orange
            }
        }
        is (orange) {
            when(io.badEvent) {
                stateReg := red
            } .elsewhen(io.clear) {
                stateReg := green
            }
        }
        is (red) {
            when (io.clear) {
                stateReg := green
            }
        }
    }
    // Output logic
    io.ringBell := stateReg === red
}
```

- One key things is the `ChiselEnum` where we defined states.
- After defining the object, don't forget to declare the `import State._`
- What happens all the states `green , orange , red` already have values that can be directly called.
- The code above was a Moore FSM.
- We can also have a Mealy FSM where the output is only dependent on the state:

```scala
import chisel3._
import chisel3.util._

class RisingFsm extends Module {
    val io = IO(new Bundle{
        val din = Input(Bool())
        val risingEdge = Output(Bool())
    })

    // The two states
    object State extends ChiselEnum {
        val zero , one = Value
    }
    import State._

    // The state register
    val stateReg = RegInit(zero)

    // default value for output
    io.risingEdge := false.B

    // Next state and output logic
    switch (stateReg) {
        is(zero) {
            when(io.din) {
                stateReg := one
                io.risingEdge := true.B
            }
        }
        is(one) {
            when(!io.din) {
                stateReg := zero
            }
        }
    }
}
```

# FSM Communications
- Here are more interesting Chisel code examples.
- The first is a light flasher with the following specs:
  - One input `start`, and one output `light`
  - When `start` is high for one clock cycle, the `light` flashing sequence starts.
  - The sequence is to flash 3 times.
  - The light goes on for 6 clock cycles, and the light goes off for 4 clock cycles between flashes.
  - After the sequence the FSM switches the light off and waits for the next start.


```scala
// This is a timer FSM controller
val timerReg = RegInit(0.U)
timerDone := timerReg === 0.U

// Timer FSM (down counter)
when(!timerDone) {
    timerReg := timerReg - 1.U
}

when (timerLoad) {
    when (timerSelect) {
        timerReg := 5.U
    } .otherwise {
        timerReg := 3.U
    }
}

// This part is the main FSM
object State extends ChiselEnum {
    val off, flash1 , space1 , flash2 , space2 , flash3 = Value
}
import State._
val stateReg = RegInit(off)

val light = WireDefault(false.B) // FSM output

// Timer connection
// Note that these defaults are the go back to states
// As long as nothing overwrites them, they go back here
val timerLoad = WireDefault(false.B) // start timer
val timerSelect = WireDefault(true.B) // 6 or 4 cycles

val timerDone = Wire(Bool())
timerLoad := timerDone

// Master FSM (It's a Mealy!)
switch(stateReg) {
    is(off) {
        timerLoad := true.B
        timerSelect := true.B
        when (start) { stateReg := flash1 }
    }
    is (flash1) {
        timerSelect := false.B
        light := true.B
        when (timerDone) { stateReg := space1 }
    }
    is (space1) {
        // Note that timerSelect and light will
        // go back to their default
        // the timerLoad's default is hooked to timerDone
        when (timerDone) { stateReg := flash2 }
    }
    is (flash2) {
        timerSelect := false.B
        light := true.B
        when (timerDone) { stateReg := space2 }
    }
    is (space2) {
        when (timerDone) { stateReg := flash3 }
    }
    is (flash3) {
        timerSelect := false.B
        light := true.B
        when (timerDone) { stateReg := off }
    }
}
```

- Another design would be:

```scala
// Count down timers only
val cntReg = RegInit(0.U)
cntDone := cntReg === 0.U

// Down counter FSM
when(cntLoad) { cntReg := 2.U }
when(cntDecr) { cntReg := cntReg - 1.U }

object State extends ChiselEnum {
    val off, flash , space = Value
}

import State._
val stateReg = RegInit(off)

val light = WireDefault(false.B) // FSM output

// Timer connection
val timerLoad = WireDefault(false.B) // start timer with a load
val timerSelect = WireDefault(true.B) // select 6 or 4 cycles
val timerDone = Wire(Bool())

// Counter connection
// Observe that connections can be connected later
val cntLoad = WireDefault(false.B)
val cntDecr = WireDefault(false.B)
val cntDone = Wire(Bool())
timerLoad := timerDone

// State switching
switch(stateReg) {
    is(off) {
        timerLoad := true.B
        timerSelect := true.B
        cntLoad := true.B
        when (start) { stateReg := flash }
    }
    is (flash) {
        timerSelect := false.B
        light := true.B
        when (timerDone & !cntDone) { stateReg := space }
        when (timerDone & cntDone) { stateReg := off }
    }
    is (space) {
        cntDecr := timerDone
        when (timerDone) { stateReg := flash }
    }
}
```

# FSM with Datapaths
- In this example, let's do a Hamming count

```scala
class PopCountDataPath extends Module {
    val io = IO(new Bundle {
        val din = Input(UInt(8.W))
        val load = Input(Bool())
        val popCnt = Output(UInt(4.W))
        val done = Output(Bool())
    })

    val dataReg = RegInit(0.U(8.W))
    val popCntReg = RegInit(0.U(8.W))
    val counterReg= RegInit(0.U(4.W))

    dataReg := 0.U ## dataReg(7, 1)
    popCntReg := popCntReg + dataReg(0)
    val done = counterReg === 0.U

    when (!done) {
        counterReg := counterReg - 1.U
    }

    when(io.load) {
        dataReg := io.din
        popCntReg := 0.U
        counterReg := 8.U
    }

    // debug output
    printf("%x %d\n", dataReg , popCntReg)
    io.popCnt := popCntReg
    io.done := done
}

class PopCountFSM extends Module {
    val io = IO(new Bundle {
        val dinValid = Input(Bool())
        val dinReady = Output(Bool())
        val popCntValid = Output(Bool())
        val popCntReady = Input(Bool())
        val load = Output(Bool())
        val done = Input(Bool())
    })

    object State extends ChiselEnum {
        val idle , count , done = Value
    }
    import State._

    val stateReg = RegInit(idle)
    io.load := false.B
    io.dinReady := false.B
    io.popCntValid := false.B

    switch(stateReg) {
        is(idle) {
            io.dinReady := true.B
            when(io.dinValid) {
                io.load := true.B
                stateReg := count
            }
        }
        is(count) {
            when(io.done) {
                stateReg := done
            }
        }
        is(done) {
            io.popCntValid := true.B
            when(io.popCntReady) {
                stateReg := idle
            }
        } 
    }
}

class PopulationCount extends Module {
    val io = IO(new Bundle {
        val dinValid = Input(Bool())
        val dinReady = Output(Bool())
        val din = Input(UInt(8.W))
        val popCntValid = Output(Bool())
        val popCntReady = Input(Bool())
        val popCnt = Output(UInt(4.W))
    })

    val fsm = Module(new PopCountFSM)
    val data = Module(new PopCountDataPath)

    fsm.io.dinValid := io.dinValid
    io.dinReady := fsm.io.dinReady
    io.popCntValid := fsm.io.popCntValid
    fsm.io.popCntReady := io.popCntReady
    data.io.din := io.din
    io.popCnt := data.io.popCnt
    data.io.load := fsm.io.load
    fsm.io.done := data.io.done
}
```

# Ready-Valid Interface
- A very important well-known interface for synchronizing data transfers.
- This is quite conventional.
- Chisel defines this interface with `DecoupledIO`.
- This is built in the Chisel already.

```scala
class DecoupledIO[T <: Data](gen: T) extends Bundle {
    val ready = Input(Bool())
    val valid = Output(Bool())
    val bits = Output(gen)
}
```

- There are several warnings parts here though:

>One question remains if the ready or valid may be de-asserted after being asserted and no data transfer has happened. For example, a receiver might be ready for some time and not receive data, but due to some other events may become not ready. The same can be envisioned with the sender, having data valid only some clock cycles and becoming non-valid without a data transfer happening. If this behavior is allowed or not is not part of the ready/valid interface, but needs to be defined by the concrete usage of the interface.

- In the case where there is a necessity that the signals need to be sticky, Chisel has `IrrevocableIO`:

> A concrete subclass of ReadyValidIO that promises to not change the
value of bits after a cycle where valid is high and ready is low. Additionally, once valid is raised it will never be lowered until after ready has also been raised.

- Then for AXI, it actually is "required".
- The AXI bus [3] uses one ready/valid interface for each of the following parts of the bus: read address, read data, write address, and write data. 
- AXI restricts the interface so that once the sender assets valid, it is not allowed to deassert it until the data transfer happens.
- Furthermore, the sender is not allowed to wait for a receivers ready to assert valid.
- The receiver side is more relaxed. If ready is asserted, it is allowed to deassert it before valid is asserted. 
- Furthermore, the receiver can wait for an asserted valid before asserting ready.

- Here is an example usage:

```scala
class ReadyValidBuffer extends Module {
    val io = IO(new Bundle{
        val in = Flipped(new DecoupledIO(UInt(8.W)))
        val out = new DecoupledIO(UInt(8.W))
    })

    val dataReg = Reg(UInt(8.W))
    val emptyReg = RegInit(true.B)

    io.in.ready := emptyReg
    io.out.valid := !emptyReg
    io.out.bits := dataReg

    when (emptyReg & io.in.valid) {
        dataReg := io.in.bits
        emptyReg := false.B
    }

    when (!emptyReg & io.out.ready) {
        mptyReg := true.B
    }
}
```

- Note that the `DecoupledIO` is in the sender perspective, so the direction for ready-valid is going out.
- We need to flip that for the input hence the `Flipped`
- There is a bit of a confusion weakness about the Flipped and not flipped because we don't really specify the direction. For example, the `io.in.ready` actually is an output and not an input but because of the `DecoupledIO` definition that was `Flipped`.


