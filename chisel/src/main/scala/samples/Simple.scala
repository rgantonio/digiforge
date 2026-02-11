//---------------------------
// Sample Circuit
//---------------------------
package samples

import chisel3._

class Simple extends Module {
  val io = IO(new Bundle {
    val a = Input(UInt(8.W))
    val b = Input(UInt(8.W))
    val out = Output(UInt(8.W))
    val equ = Output(Bool())
  })

  io.out := io.a + io.b
  io.equ := io.a === io.b
}