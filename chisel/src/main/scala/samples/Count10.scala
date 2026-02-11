//---------------------------
// Sample Counter
//---------------------------
package samples

import chisel3._

class Adder extends Module{
    val io = IO( new Bundle {
        val a = Input(UInt(8.W))
        val b = Input(UInt(8.W))
        val y = Output(UInt(8.W))
    })

    io.y := io.a + io.b
}

class Register extends Module{
    val io = IO( new Bundle {
        val d = Input(UInt(8.W))
        val q = Output(UInt(8.W))
    })
    val reg = RegInit(0.U)
    reg := io.d
    io.q := reg
}

class Count10 extends Module{
    val io = IO( new Bundle {
        val dout = Output(UInt(8.W))
    })

    // Declaration of modules
    val add = Module(new Adder())
    val reg = Module(new Register())

    // The register output
    // Note that it automatically infers the bit-width
    // Connect to a "wire" count, note that it isn't a Wire
    val count = reg.io.q

    // Connect the adder
    add.io.a := 1.U
    add.io.b := count
    val result = add.io.y

    // Connect the mux and register input
    val next = Mux(count === 9.U, 0.U, result)
    reg.io.d := next
    
    // Assign the output
    io.dout := count
}

object Count10Main extends App {
  println("Generating the Count10 hardware")
  emitVerilog(new Count10(), Array("--target-dir", "generated"))
}
