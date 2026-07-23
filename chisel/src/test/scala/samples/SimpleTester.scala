//---------------------------
// Sample Circuit Tester
//---------------------------

package samples

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec


class SimpleTester extends AnyFlatSpec with ChiselScalatestTester {
  "DUT" should "pass" in {
    test(new Simple) { dut =>
        dut.io.a.poke(10.U)
        dut.io.b.poke(20.U)
        dut.clock.step(1)
        println(s"Output: ${dut.io.out.peekInt()}")
        println(s"Equal: ${dut.io.equ.peekBoolean()}")
        dut.io.out.expect(30.U)
        dut.io.equ.expect(false.B)
        dut.io.a.poke(128.U)
        dut.io.b.poke(128.U)
        dut.clock.step(1)
        println(s"Output: ${dut.io.out.peekInt()}")
        println(s"Equal: ${dut.io.equ.peekBoolean()}")
        dut.io.out.expect(0.U)
        dut.io.equ.expect(true.B)
    }
  }
}