// -------------------------------------------------------------------------
// Testbench for Barrel Shifter File
// -------------------------------------------------------------------------
package common

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec
import chiseltest.simulator.WriteVcdAnnotation
import scala.util.Random

class BarrelShifterTester extends AnyFlatSpec with ChiselScalatestTester {
  val dataW = 32
  val numTestCases = 10

  val rng = new Random(seed = 42)
  def randData(width: Int, rng: Random): BigInt = BigInt(width, rng.self)
  def randInRange(min: Int, max: Int): Int = min + rng.nextInt(max - min + 1)
  def toSigned(x: BigInt, w: Int): BigInt = if (x.testBit(w - 1)) x - (BigInt(1) << w) else x
  def maskUnsigned(x: BigInt, w: Int): BigInt = x & ((BigInt(1) << w) - 1)

  "BarrelShifter" should "TC-01: SLL shimft_amt_i = 0 -- passthrough" in {
    test(
      new BarrelShifter(dataW = dataW)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      for (i <- 0 until numTestCases) {
        val data = randData(dataW, rng)
        dut.io.data.poke(data.U)
        dut.io.shiftAmt.poke(0.U)
        dut.io.opSel.poke(0.U)
        dut.clock.step(1)
        dut.io.out.expect(data.U)
      }
    }
  }

  it should "TC-02: SLL, shift_amt_i = DATA_W - 1 — only original LSB survives, at the MSB" in {
    test(
      new BarrelShifter(dataW = dataW)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      for (i <- 0 until numTestCases) {
        val data = randData(dataW, rng)
        dut.io.data.poke(data.U)
        dut.io.shiftAmt.poke((dataW - 1).U)
        dut.io.opSel.poke(0.U)
        dut.clock.step(1)
        val expected = (data & 1) << (dataW - 1)
        dut.io.out.expect(expected.U)
      }
    }
  }

  it should "TC-03: SRL, shift_amt_i = DATA_W - 1 — only original MSB survives, at the LSB, zero-filled elsewhere" in {
    test(
      new BarrelShifter(dataW = dataW)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      for (i <- 0 until numTestCases) {
        val data = randData(dataW, rng)
        dut.io.data.poke(data.U)
        dut.io.shiftAmt.poke((dataW - 1).U)
        dut.io.opSel.poke(1.U)
        dut.clock.step(1)
        val expected = (data >> (dataW - 1)) & 1
        dut.io.out.expect(expected.U)
      }
    }
  }

  it should "TC-04: SRA with data_i[DATA_W-1] = 1 — verify sign fill, not zero fill" in {
    test(
      new BarrelShifter(dataW = dataW)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      for (i <- 0 until numTestCases) {
        val data = randData(dataW - 1, rng) | (BigInt(1) << (dataW - 1)) // Ensure MSB is 1
        val shiftAmt = randInRange(0, dataW - 1)

        dut.io.data.poke(data.U)
        dut.io.shiftAmt.poke(shiftAmt.U)
        dut.io.opSel.poke(2.U)

        val expected: BigInt = maskUnsigned(toSigned(data, dataW) >> shiftAmt, dataW)
        dut.io.out.expect(expected.U(dataW.W))
      }
    }
  }

  it should "TC-05: SRA with data_i[DATA_W-1] = 0 — verify SRA and SRL agree in this case" in {
    test(
      new BarrelShifter(dataW = dataW)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      for (i <- 0 until numTestCases) {
        val data = randData(dataW - 1, rng) // Ensure MSB is 0
        val shiftAmt = randInRange(0, dataW - 1)

        dut.io.data.poke(data.U)
        dut.io.shiftAmt.poke(shiftAmt.U)
        dut.io.opSel.poke(2.U) // SRA
        val expectedSRA: BigInt = maskUnsigned(toSigned(data, dataW) >> shiftAmt, dataW)

        dut.io.opSel.poke(1.U) // SRL
        val expectedSRL: BigInt = maskUnsigned(data >> shiftAmt, dataW)

        assert(
          expectedSRA == expectedSRL,
          s"SRA and SRL results differ for data=0x${data.toString(16)}, shiftAmt=$shiftAmt"
        )
      }
    }
  }

  it should "TC-06: ROL with shift_amt_i = 0 — passthrough, confirm the special-case doesn't corrupt output" in {
    test(
      new BarrelShifter(dataW = dataW)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      for (i <- 0 until numTestCases) {
        val data = randData(dataW, rng)
        dut.io.data.poke(data.U)
        dut.io.shiftAmt.poke(0.U)
        dut.io.opSel.poke(3.U) // ROL
        dut.clock.step(1)
        dut.io.out.expect(data.U)
      }
    }
  }

  it should "TC-07: ROL, arbitrary mid-range amount — confirm wrapped bits land correctly (use the worked example table)" in {
    test(
      new BarrelShifter(dataW = dataW)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      val data = BigInt("12345678", 16)
      val shiftAmt = 4
      val expected = BigInt("23456781", 16)

      dut.io.data.poke(data.U)
      dut.io.shiftAmt.poke(shiftAmt.U)
      dut.io.opSel.poke(3.U) // ROL
      dut.clock.step(1)
      dut.io.out.expect(expected.U)
    }
  }

  it should "TC-08: ROR, arbitrary mid-range amount — same, opposite direction" in {
    test(
      new BarrelShifter(dataW = dataW)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
      val data = BigInt("12345678", 16)
      val shiftAmt = 4
      val expected = BigInt("81234567", 16)

      dut.io.data.poke(data.U)
      dut.io.shiftAmt.poke(shiftAmt.U)
      dut.io.opSel.poke(4.U) // ROR
      dut.clock.step(1)
      dut.io.out.expect(expected.U)
    }
  }

}
