# Design Examples
- Here we explore some small design examples

## FIFO Buffer

```scala

// Declaration of bundles for the ports
class WriterIO(size: Int) extends Bundle {
    val write = Input(Bool())
    val full = Output(Bool())
    val din = Input(UInt(size.W))
}

class ReaderIO(size: Int) extends Bundle {
    val read = Input(Bool())
    val empty = Output(Bool())
    val dout = Output(UInt(size.W))
}

// A single unit of FIFO register
class FifoRegister(size: Int) extends Module {
    val io = IO(new Bundle {
        // Declare the IO ports here
        val enq = new WriterIO(size)
        val deq = new ReaderIO(size)
    })

    object State extends ChiselEnum {
        val empty , full = Value
    }
    import State._

    val stateReg = RegInit(empty)
    val dataReg = RegInit(0.U(size.W))

    when(stateReg === empty) {
        when(io.enq.write) {
            stateReg := full
            dataReg := io.enq.din
        }
    }.elsewhen(stateReg === full) {
        when(io.deq.read) {
            stateReg := empty
            dataReg := 0.U // just to better see empty slots in the waveform
        }
    }.otherwise {
        // There should not be an otherwise state
    }

    io.enq.full := (stateReg === full)
    io.deq.empty := (stateReg === empty)
    io.deq.dout := dataReg
}

// The FIFO deep
class BubbleFifo(size: Int, depth: Int) extends Module {
    val io = IO(new Bundle {
        val enq = new WriterIO(size)
        val deq = new ReaderIO(size)
    })

    // Create `depth` deep buffers
    val buffers = Array.fill(depth) { Module(new FifoRegister(size)) }

    // Chaining the FIFO buffers
    for (i <- 0 until depth - 1) {
        buffers(i + 1).io.enq.din := buffers(i).io.deq.dout
        buffers(i + 1).io.enq.write := ˜buffers(i).io.deq.empty
        buffers(i).io.deq.read := ˜buffers(i + 1).io.enq.full
    }

    // Recall that <> means to hook up all ports
    io.enq <> buffers(0).io.enq
    io.deq <> buffers(depth - 1).io.deq
}
```

## Serial Port
- Sample are UART and RS-32

```scala
class UartIO extends DecoupledIO(UInt(8.W)) {
}

class Tx(frequency: Int, baudRate: Int) extends Module {
    val io = IO(new Bundle {
        val txd = Output(UInt(1.W))
        val channel = Flipped(new UartIO())
    })

    val BIT_CNT = ((frequency + baudRate / 2) / baudRate - 1).asUInt
    val shiftReg = RegInit(0x7ff.U)
    val cntReg = RegInit(0.U(20.W))
    val bitsReg = RegInit(0.U(4.W))

    io.channel.ready := (cntReg === 0.U) && (bitsReg === 0.U)
    io.txd := shiftReg(0)

    when(cntReg === 0.U) {
        cntReg := BIT_CNT

        when(bitsReg =/= 0.U) {
            val shift = shiftReg >> 1
            shiftReg := 1.U ## shift(9, 0)
            bitsReg := bitsReg - 1.U
        } .otherwise {
            when(io.channel.valid) {
                // two stop bits , data , one start bit
                shiftReg := 3.U ## io.channel.bits ## 0.U
                bitsReg := 11.U
            } .otherwise {
                shiftReg := 0x7ff.U
            }
        }
    } .otherwise {
        cntReg := cntReg - 1.U
    }
}

class Buffer extends Module {
    val io = IO(new Bundle {
        val in = Flipped(new UartIO())
        val out = new UartIO()
    })

    object State extends ChiselEnum {
        val empty , full = Value
    }
    import State._

    val stateReg = RegInit(empty)
    val dataReg = RegInit(0.U(8.W))

    io.in.ready := stateReg === empty
    io.out.valid := stateReg === full

    when(stateReg === empty) {
        when(io.in.valid) {
            dataReg := io.in.bits
            stateReg := full
        }
    } .otherwise { // full
        when(io.out.ready) {
            stateReg := empty
        }
    }
    io.out.bits := dataReg
}

class BufferedTx(frequency: Int, baudRate: Int) extends
    Module {
        val io = IO(new Bundle {
        val txd = Output(UInt(1.W))
        val channel = Flipped(new UartIO())
    })
    val tx = Module(new Tx(frequency , baudRate))
    val buf = Module(new Buffer())
    buf.io.in <> io.channel
    tx.io.channel <> buf.io.out
    io.txd <> tx.io.txd
}
```