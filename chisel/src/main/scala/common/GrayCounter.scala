package common

import chisel3._
import chisel3.util._

class GrayCounter(countWidth: Int = 4) extends Module {
  val io = IO(new Bundle {
    val en = Input(Bool())
    val binCount = Output(UInt(countWidth.W))
    val grayCount = Output(UInt(countWidth.W))
    val rollover = Output(Bool())
  })

  val binReg = RegInit(0.U(countWidth.W))
  val grayReg = RegInit(0.U(countWidth.W))
  val rollReg = RegInit(false.B)

  // Normal binary counting
  val nextBin = binReg + 1.U

  // Gray code conversion: gray = (bin >> 1) ^ bin
  val nextGray = (nextBin >> 1) ^ nextBin

  // Rollover detection
  val nextRoll = io.en && (binReg === ((1.U << countWidth) - 1.U))

  // Always active
  rollReg := nextRoll

  // Updates only on enable
  when(io.en) {
    binReg := nextBin
    grayReg := nextGray
  }

  io.binCount := binReg
  io.grayCount := grayReg
  io.rollover := rollReg
}

object GrayCounterGen extends App {
  println("Generating the GrayCounter hardware")
  emitVerilog(
    new GrayCounter(
      countWidth = 4
    ),
    Array("--target-dir", "generated")
  )
}
