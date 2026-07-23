// -------------------------------------------------------------------------
// Basic Register File
// - With capabilities of having multiple read and write ports
// - With write-back forwarding for reads
// -------------------------------------------------------------------------
package common

import chisel3._
import chisel3.util._

class RegFile(
    dataW: Int = 32,
    addrW: Int = 5,
    numRdPorts: Int = 2,
    numWrPorts: Int = 1
) extends Module {

  val depth = 1 << addrW

  val io = IO(new Bundle {
    val wrEn = Input(Vec(numWrPorts, Bool()))
    val wrAddr = Input(Vec(numWrPorts, UInt(addrW.W)))
    val wrData = Input(Vec(numWrPorts, UInt(dataW.W)))
    val rdAddr = Input(Vec(numRdPorts, UInt(addrW.W)))
    val rdData = Output(Vec(numRdPorts, UInt(dataW.W)))
  })

  // Use RegInit with Vec form for something analogous to the SystemVerilog version
  val mem = RegInit(VecInit(Seq.fill(depth)(0.U(dataW.W))))

  // -------------------------------------------------------------------------
  // Write logic (synchronous, uses implicit reset)
  // -------------------------------------------------------------------------
  for (i <- 0 until numWrPorts) {
    when(io.wrEn(i) && (io.wrAddr(i) =/= 0.U)) {
      mem(io.wrAddr(i)) := io.wrData(i)
    }
  }

  // -------------------------------------------------------------------------
  // Read logic (combinational, with WBR forwarding)
  // -------------------------------------------------------------------------
  for (j <- 0 until numRdPorts) {
    val rdData = WireDefault(mem(io.rdAddr(j)))
    for (i <- 0 until numWrPorts) {
      when(io.wrEn(i) && (io.wrAddr(i) === io.rdAddr(j))) {
        rdData := io.wrData(i)
      }
    }
    // MUX to select whether we output 0 from address 0 or
    // the selected read data.
    io.rdData(j) := Mux(io.rdAddr(j) === 0.U, 0.U, rdData)
  }
}

object RegFileGen extends App {
  println("Generating the RegFile hardware")
  emitVerilog(
    new RegFile(
      dataW = 32,
      addrW = 5,
      numRdPorts = 2,
      numWrPorts = 1
    ),
    Array("--target-dir", "generated")
  )
}
