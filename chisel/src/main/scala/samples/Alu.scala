//---------------------------
// Sample ALU
//---------------------------
package samples

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

object AluMain extends App {
  println("Generating the ALU hardware")
  emitVerilog(new Alu(), Array("--target-dir", "generated"))
}