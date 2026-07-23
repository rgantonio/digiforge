// -------------------------------------------------------------------------
// Testbench for Basic Register File
// -------------------------------------------------------------------------
package common

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec
import scala.util.Random

class RegFileTester extends AnyFlatSpec with ChiselScalatestTester {

  val dataW = 32
  val addrW = 5

  "RegFile" should "TC-01: Reset all registers to 0" in {
    test(
      new RegFile(
        dataW = dataW,
        addrW = addrW
      )
    ) { dut =>
      dut.reset.poke(true.B)
      dut.clock.step(1)
      dut.reset.poke(false.B)
      for (i <- 0 until 32) {
        dut.io.rdAddr(0).poke(i.U)
        dut.io.rdData(0).expect(0.U)
      }
    }
  }

  it should "TC-02: Write to a register and read it back" in {
    test(
      new RegFile(
        dataW = dataW,
        addrW = addrW
      )
    ) { dut =>
      val rng = new Random(seed = 42)
      dut.reset.poke(true.B); dut.clock.step(1); dut.reset.poke(false.B)
      for (i <- 1 until 32) {
        val randomData = rng.nextLong() & ((1L << dataW) - 1L)
        dut.io.wrEn(0).poke(true.B)
        dut.io.wrAddr(0).poke(i.U)
        dut.io.wrData(0).poke(randomData.U)
        dut.clock.step(1)
        dut.io.wrEn(0).poke(false.B)
        dut.io.rdAddr(0).poke(i.U)
        dut.io.rdData(0).expect(randomData.U)
        dut.clock.step(1)
      }
    }
  }

  it should "TC-03: Ignore writes to register 0 and always read 0" in {
    test(
      new RegFile(
        dataW = dataW,
        addrW = addrW
      )
    ) { dut =>
      val rng = new Random(seed = 43)
      dut.reset.poke(true.B); dut.clock.step(1); dut.reset.poke(false.B)
      for (_ <- 0 until 10) {
        val randomData = rng.nextLong() & ((1L << dataW) - 1L)
        dut.io.wrEn(0).poke(true.B)
        dut.io.wrAddr(0).poke(0.U)
        dut.io.wrData(0).poke(randomData.U)
        dut.clock.step(1)
        dut.io.wrEn(0).poke(false.B)
        dut.io.rdAddr(0).poke(0.U)
        dut.io.rdData(0).expect(0.U)
        dut.clock.step(1)
      }
    }
  }

  it should "TC-04: Forward write data to read port in same cycle (WBR)" in {
    test(
      new RegFile(
        dataW = dataW,
        addrW = addrW
      )
    ) { dut =>
      val rng = new Random(seed = 44)
      dut.reset.poke(true.B); dut.clock.step(1); dut.reset.poke(false.B)
      for (i <- 1 until 32) {
        val randomData = rng.nextLong() & ((1L << dataW) - 1L)
        dut.io.wrEn(0).poke(true.B)
        dut.io.wrAddr(0).poke(i.U)
        dut.io.wrData(0).poke(randomData.U)
        dut.io.rdAddr(0).poke(i.U)
        dut.io.rdData(0).expect(randomData.U) // combinational forward, no step
        dut.clock.step(1)
      }
    }
  }
}
