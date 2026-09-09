package common

import chisel3._
import chisel3.util._

class PwmGen(
    val cntW: Int = 8,
    val numCh: Int = 1,
    val phaseCorrect: Boolean = false
) extends Module {

  require(cntW >= 1, "cntW must be >= 1")
  require(numCh >= 1, "numCh must be >= 1")

  val io = IO(new Bundle {
    val en = Input(Bool())
    val period = Input(UInt(cntW.W))
    val duty = Input(Vec(numCh, UInt(cntW.W)))
    val pwm = Output(Vec(numCh, Bool()))
    val periodTick = Output(Bool())
  })

  // -------------------------------------------------------------
  // State
  // -------------------------------------------------------------
  val cntReg = RegInit(UInt(cntW.W), 0.U)
  val dirReg = RegInit(Bool(), false.B)
  val periodReg = RegInit(UInt(cntW.W), 0.U)
  val dutyReg = RegInit(VecInit(Seq.fill(numCh)(0.U(cntW.W))))
  val pwmReg = RegInit(VecInit(Seq.fill(numCh)(false.B)))
  val tickReg = RegInit(Bool(), false.B)

  // Extra wires
  val cntNext = WireDefault(cntReg)
  val dirNext = WireDefault(dirReg)
  val pwmNext = WireDefault(VecInit(Seq.fill(numCh)(false.B)))

  // -------------------------------------------------------------
  // 1 - end-of-period detection (R5)
  //   phaseCorrect is a Scala Boolean, so use `if` here. It picks
  //   which hardware to build and the other branch disappears.
  //   Use `when` only for conditions on hardware values like dirReg.
  // -------------------------------------------------------------
  // default 0
  val endOfPeriod = WireDefault(false.B)

  // otherwise choose one of each
  if (phaseCorrect) {
    endOfPeriod := (((dirReg === 1.U) & (cntReg === 1.U)) || (periodReg === 0.U)) && io.en
  } else {
    endOfPeriod := (cntReg >= periodReg) && io.en
  }

  val reload = endOfPeriod || !io.en

  // -------------------------------------------------------------
  // 2 - counter and direction next-state (R3, R4)
  // -------------------------------------------------------------
  when(!io.en) {
    cntNext := 0.U
    dirNext := false.B
  }.otherwise {
    // center-aligned version
    if (phaseCorrect) {
      // Special case when 0 happens
      when(periodReg === 0.U) {
        cntNext := 0.U
        dirNext := false.B
      }.otherwise {
        // Counting up case
        when(dirReg === false.B) {
          when(cntReg === periodReg) {
            cntNext := cntReg - 1.U
            dirNext := true.B
          }.otherwise {
            cntNext := cntReg + 1.U
            dirNext := false.B
          }
          // Counting down case
        }.otherwise {
          when(cntReg === 1.U) {
            cntNext := 0.U
            dirNext := false.B
          }.otherwise {
            cntNext := cntReg - 1.U
            dirNext := true.B
          }
        }
      }
    } else {
      cntNext := Mux(endOfPeriod, 0.U, cntReg + 1.U)
      dirNext := false.B
    }
  }

  // -------------------------------------------------------------
  // 3 - comparator array (R7, R8)  <-- the core of the exercise
  //
  //   Edge   : pwmNext(ch) = (cntReg < dutyReg(ch))
  //   Center : dirReg === false.B   ->  cntReg <  dutyReg(ch)
  //            dirReg === true.B    ->  cntReg <= dutyReg(ch)
  //
  //   Compare against cntReg and dutyReg. Never against duty_i.
  //   Force to 0 when io.en is low.
  // -------------------------------------------------------------
  when(io.en) {
    for (ch <- 0 until numCh) {
      if (phaseCorrect) {
        when(dirReg === false.B) {
          pwmNext(ch) := (cntReg < dutyReg(ch))
        }.otherwise {
          pwmNext(ch) := (cntReg <= dutyReg(ch))
        }
      } else {
        pwmNext(ch) := (cntReg < dutyReg(ch))
      }
    }
  }.otherwise {
    for (ch <- 0 until numCh) {
      pwmNext(ch) := false.B
    }
  }

  // -------------------------------------------------------------
  // Register updates
  // -------------------------------------------------------------
  cntReg := cntNext
  dirReg := dirNext
  pwmReg := pwmNext
  tickReg := endOfPeriod
  when(reload) {
    periodReg := io.period
    for (ch <- 0 until numCh) {
      dutyReg(ch) := io.duty(ch)
    }
  }.otherwise {
    periodReg := periodReg
    for (ch <- 0 until numCh) {
      dutyReg(ch) := dutyReg(ch)
    }
  }

  // Wire to output
  io.pwm := pwmReg
  io.periodTick := tickReg

}

object PwmGenGen extends App {
  println("Generating the PWM Generator hardware")
  emitVerilog(
    new PwmGen(
      numCh = 4,
      phaseCorrect = true
    ),
    Array("--target-dir", "generated")
  )
}
