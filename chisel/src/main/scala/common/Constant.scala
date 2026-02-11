/*
 * Dummy file to start a Chisel project.
 *
 * Author: Martin Schoeberl (martin@jopdesign.com)
 * 
 */

package common

import chisel3._
// import chisel3.util._

class Constant extends Module {
  val io = IO(new Bundle {
    val a = Output(UInt(8.W))
    val b = Output(UInt(8.W))
    val c = Output(SInt(8.W))
  })

  io.a := 42.U
  io.b := 255.U
  io.c := -42.S
}

object ConstantMain extends App {
  println("Generating the constant hardware")
  emitVerilog(new Constant(), Array("--target-dir", "generated"))
}