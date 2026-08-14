// -------------------------------------------------------------------------
// Testbench for Gray Counter
// -------------------------------------------------------------------------

package common

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec
import chiseltest.simulator.WriteVcdAnnotation
import scala.util.Random

class GrayCounterTester extends AnyFlatSpec with ChiselScalatestTester {
  val countWidth = 4

  "GrayCounter" should "TC-03: Count in binary and gray code, check rollover" in {
    test(
      new GrayCounter(countWidth = countWidth)
    ).withAnnotations(Seq(WriteVcdAnnotation)) { dut =>

        dut.io.en.poke(true.B)
        dut.clock.step(1)
        val binCount = dut.io.binCount.peek().litValue
        val grayCount = dut.io.grayCount.peek().litValue
        val expectedGray = (binCount >> 1) ^ binCount
        dut.io.grayCount.expect(expectedGray.U)
        if (binCount == ((1 << countWidth) - 1)) {
            dut.io.rollover.expect(true.B)
        } else {
            dut.io.rollover.expect(false.B)
        }

    }
  }
}