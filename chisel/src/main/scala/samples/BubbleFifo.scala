//---------------------------
// Sample BubbleFIFO
//---------------------------
package samples

import chisel3._

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
        buffers(i + 1).io.enq.write := ~buffers(i).io.deq.empty
        buffers(i).io.deq.read := ~buffers(i + 1).io.enq.full
    }

    // Recall that <> means to hook up all ports
    io.enq <> buffers(0).io.enq
    io.deq <> buffers(depth - 1).io.deq
}

object BubbleFifoMain extends App {
  println("Generating the BubbleFifoMain hardware")
  emitVerilog(new BubbleFifo(8, 3), Array("--target-dir", "generated"))
}