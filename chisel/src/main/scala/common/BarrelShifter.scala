package common

import chisel3._
import chisel3.util._

class BarrelShifter(dataW: Int = 32) extends Module {
  val stages = log2Ceil(dataW)

  val io = IO(new Bundle {
    val data = Input(UInt(dataW.W))
    val shiftAmt = Input(UInt(stages.W))
    val opSel = Input(UInt(3.W))
    val out = Output(UInt(dataW.W))
  })

  object OpSel {
    val SLL = 0.U(3.W) // Shift Left Logical
    val SRL = 1.U(3.W) // Shift Right Logical
    val SRA = 2.U(3.W) // Shift Right Arithmetic
    val ROL = 3.U(3.W) // Rotate Left
    val ROR = 4.U(3.W) // Rotate Right
  }

  val stageWires = Wire(Vec(stages + 1, UInt(dataW.W)))
  stageWires(0) := io.data

  for (k <- 0 until stages) {
    // Syntax of args is: MuxLookup(key, default)(Seq(key -> value, ...))
    val shifted = MuxLookup(io.opSel, stageWires(k))(
      Seq(
        OpSel.SLL -> (stageWires(k) << (1 << k)),
        OpSel.SRL -> (stageWires(k) >> (1 << k)),
        OpSel.SRA -> (stageWires(k).asSInt >> (1 << k)).pad(dataW).asUInt,
        OpSel.ROL -> (Cat(stageWires(k), stageWires(k)) >> (dataW - (1 << k)))(dataW - 1, 0),
        OpSel.ROR -> (Cat(stageWires(k), stageWires(k)) >> (1 << k))(dataW - 1, 0)
      )
    )
    stageWires(k + 1) := Mux(io.shiftAmt(k), shifted, stageWires(k))
  }

  when(io.opSel > 4.U) {
    io.out := 0.U
  }.otherwise {
    io.out := stageWires(stages)
  }

}

object BarrelShifterGen extends App {
  println("Generating the BarrelShifter hardware")
  emitVerilog(
    new BarrelShifter(
      dataW = 32
    ),
    Array("--target-dir", "generated")
  )
}
