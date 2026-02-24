//---------------------------
// Sample Vector Reduce Tree
//---------------------------
package samples

import chisel3._

class ReduceTree (n: Int) extends Module {
  val io = IO(new Bundle {
    val in = Input(Vec(n, UInt(8.W)))
    val out = Output(UInt(16.W))
  })

  io.out := io.in.reduceTree(_+_)
}

object ReduceTreeMain extends App {
  println("Generating the ReduceTree hardware")
  emitVerilog(new ReduceTree(5), Array("--target-dir", "generated"))
}