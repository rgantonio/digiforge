// -------------------------------------------------------------------------
// Testbench for PWM Generator
// In this version we will test the center-aligned PWM mode
// Disclaimer, we are testing a very simple case only
// -------------------------------------------------------------------------

package common

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec
import chiseltest.simulator.WriteVcdAnnotation
import scala.util.Random

class PwmGenTester extends AnyFlatSpec with ChiselScalatestTester {
    "PWM Generator" should "TC-14 Center period" in {
        test(new PwmGen(numCh = 1, phaseCorrect = true)) { dut =>
            dut.io.en.poke(true.B)
            dut.io.period.poke(10.U)
            dut.io.duty(0).poke(5.U)
            dut.clock.step(1) // 1-cycle to load
            for (i <- 0 until 20) {
                dut.clock.step(1)
                println(s"Cycle $i: PWM output = ${dut.io.pwm(0).peek().litValue}")
            }
        }
    }
}