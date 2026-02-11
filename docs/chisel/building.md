# Build Process and Testing
- `sbt` is the build and compile tool which stands for Scala interactive build tool.
- Allows downloading the correct version of Scala and Chisel libraries.
- `build.sbt` reference the libraries you need.
- Here we just copy-pasted from other sources but it's good to know where to configure the system.
- Typical directory tree for a chisel project is shown below:

<img width="621" height="356" alt="image" src="https://github.com/user-attachments/assets/11d95f59-2562-435b-9918-d5033fc17469" />


- Chisel inherits from Scala, which inherits intself from Java, the organization of packages.
- Packages organize chisel code into namespaces.
- Packages can also contain sub-packages.
- Folder `target` contains class files and other generated files.
- `generated` directory is where verilog files are placed. You can rename this.
- You can declare your own packages this way:

```scala
package mypack

import chisel3._

class Abc extends Module{
    val io = IO(new Bundle{})
}
```

- In the above code, the package name is `mypack`
- Also, `import chisel3._` allows use to use Chisel classes.
- The `_` acts as a wild card.
- You can import your package this way:

```scala
import mypack._

class AbcUser extends Module{
    val io = IO(new Bundle{})
    val abc = new Abc()
}
```
- If you don't want to use all components in a package due to the wild card, you can:

```scala
class AbcUser2 extends Module{
    val io = IO(new Bundle{})
    val abc = new mypack.Abc()
}
```

- Alternatively:

```scala
import mypack.Abc

class AbcUser3 extends Module{
    val io = IO(new Bundle{})
    val abc = new Abc()
}
```

## Running Sbt

- You know this as: `sbt run`
- This compiles all chisel code from the source tree and search for classes that contain an object that either has `main` or extends `App`.
- If more than one exists, sbt will prompt you to select one.
- You can also directly specify the object that shall be executed as a parameter to sbt:

```bash
sbt "runMain mypacket.MyObject"
```

- By default sbt looks for main and not test. If you want to run test, do:

```bash
sbt test
```

- If you have a test that does not follow the ChiselTest convention and it contains a main function, but is placed in the test part of the source tree you can execute it with following sbt command:

```bash
sbt "test:runMain mypacket.MyMainTest
```

- Suppose you have a test class that is:

```scala
class MyAcceleratorTest extends AnyFlatSpec with ChiselScalatestTester {
```

- To run a single test you only need to use `testOnly`:

```scala
sbt "testOnly MyAcceleratorTest"
```

- If it's inside a package do:

```scala
sbt "testOnly mypackage.MyAcceleratorTest"
```

## Generating Verilog

- To generate Verilog, we need an application.
- Scala object that `extends App` is an application that implicitly generates the main function where the application starts.
- The only action of this application is to create a new Chisel module, then pass it to `emitVerilog()`function.

```scala
object Hello extends App{
    emitVerilog(new Hello())
}
```

- By default the Verilog code is emitted in the root of where the sbt ran.
- You can specify the output directory (generated) by:

```scala
object Hello extends App{
    emitVerilog(new Hello(), Array("--target-dir", "generated"))
}
```

- One can also just write verilog as a string, without having to generated the file:

```scala
object Hello extends App{
    val s = getVerilogString(new Hello())
    println(s)
}
```

# Testing with Chisel

- This is the part where we make testbenches
- Chisel provides the `ChiselTest` in package `chiseltest`
- Most useful because one can, for example, code the expected functionality of the hardware in a software simulator, then compare the hardware simulation with a software simulation!

## ScalaTest
- `ScalaTest` is a testing tool for Java
- `ChiselTest` is an extension of `ScalaTest`
- To use `ChiselTest` the following need to be imported:

```scala
import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec
```

- Consider the following code or module:

```scala
class DeviceUnderTest extends Module {
    val io = IO(new Bundle {
        val a = Input(UInt(2.W))
        val b = Input(UInt(2.W))
        val out = Output(UInt(2.W))
        val equ = Output(Bool())
    })

    // out is essentially just the AND of a and b
    // Note that they are 2 bits wide
    io.out := io.a & io.b
    // equ is literally a single bit signal
    // to check if the values are equivalent
    io.equ := io.a === io.b
}
```

- Create the testbench with:

```scala
class SimpleTest extends AnyFlatSpec with
    ChiselScalatestTester {
        "DUT" should "pass" in {
            test(new DeviceUnderTest) { dut =>
            dut.io.a.poke(0.U)
            dut.io.b.poke(1.U)
            dut.clock.step()
            println("Result is: " + dut.io.out.peekInt())
            dut.io.a.poke(3.U)
            dut.io.b.poke(2.U)
            dut.clock.step()
            println("Result is: " + dut.io.out.peekInt())
        }
    }
}
```

- Input and output are accessed with `dut.io`
- Set values via the `poke` function. Don't forget to put the appropriate data type.
- Get values with the `peekInt()` if it's a number or `peekBoolean()` if it's a single signal logic.
- Advance the simulation with `dut.clock.steop()` but take note that you can also specify how many clock cycles as an argument.
- Note that the circuit we have is completely combinationl, but to advance "time" we need to advance the clock.
- Print values like standard Java `println()`
- One can also express the expected results. Think like `assertions`

```scala
class SimpleTest extends AnyFlatSpec with
    ChiselScalatestTester {
        "DUT" should "pass" in {
            test(new DeviceUnderTest) { dut =>
            dut.io.a.poke(0.U)
            dut.io.b.poke(1.U)
            dut.clock.step()
            dut.io.out.expect(0.U)
            dut.io.a.poke(3.U)
            dut.io.b.poke(2.U)
            dut.clock.step()
            dut.io.out.expect(2.U)
        }
    }
}
```

- A failed test would describe the DUT test error in message.

```bash
[info] SimpleTestExpect:
[info] DUT
[info] - should pass *** FAILED ***
[info] io_out=2 (0x2) did not equal expected=4 (0x4)
(lines in testing.scala: 27) (testing.scala:35)
[info] ScalaTest
[info] Run completed in 1 second, 214 milliseconds.
[info] Total number of tests run: 1
[info] Suites: completed 1, aborted 0
[info] Tests: succeeded 0, failed 1, canceled 0, ignored 0, pending 0
[info] *** 1 TEST FAILED ***
[error] Failed: Total 1, Failed 1, Errors 0, Passed 0
[error] Failed tests:
[error] SimpleTestExpect
```

- The `peek()` function is a Chisel type which needs conversion to be used as Scala type for testing.
- Below is an example:

```scala
class SimpleTestPeek extends AnyFlatSpec with
    ChiselScalatestTester {
        "DUT" should "pass" in {
            test(new DeviceUnderTest) { dut =>
            dut.io.a.poke(0.U)
            dut.io.b.poke(1.U)
            dut.clock.step()
            dut.io.out.expect(0.U)
            val res = dut.io.out.peekInt()
            assert(res == 0)
            val equ = dut.io.equ.peekBoolean()
            assert(!equ)
            }
        }
    }
```

- The power of Chisel is to actually write tests.

## Waveforms

- You can dump waveforms by calling the `-DwriteVcd=1`

```bash
sbt "testOnly SimpleTest -- -DwriteVcd=1"
```

- The generated VCD is by default saved into the `test_run_dir` folder, and under the directory name of your test.
- Open it with gtkwave to see the waveforms.
- An alternative is to directly embed the VCD writing inside the test.
- Use the `WriceVcdAnnotation`. See example below:

> Be warned! This might load your files as VCD data bases can be large for a complex design.

```scala
class WaveformTest extends AnyFlatSpec with
    ChiselScalatestTester {
        "Waveform" should "pass" in {
            test(new DeviceUnderTest)
            .withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
                dut.io.a.poke(0.U)
                dut.io.b.poke(0.U)
                dut.clock.step()
                dut.io.a.poke(1.U)
                dut.io.b.poke(0.U)
                dut.clock.step()
                dut.io.a.poke(0.U)
                dut.io.b.poke(1.U)
                dut.clock.step()
                dut.io.a.poke(1.U)
                dut.io.b.poke(1.U)
                dut.clock.step()
            }
        }
    }
```

- Note that explicitly enumerating all values is taxing so use Scala to automate it for you.

```scala
class WaveformCounterTest extends AnyFlatSpec with
    ChiselScalatestTester {
        "WaveformCounter" should "pass" in {
            test(new DeviceUnderTest)
            .withAnnotations(Seq(WriteVcdAnnotation)) { dut =>
                // This is scala's way to make for loops
                for (a <- 0 until 4) {
                    for (b <- 0 until 4) {
                        dut.io.a.poke(a.U)
                        dut.io.b.poke(b.U)
                        dut.clock.step()
                    }
                }
            }
        }
    }
```

## Printf Debugging

- Our favorite debug tool is printf like in C code. We can do this as well!
- Note that the printf happens at the rising edge of the clock.

```scala
class DeviceUnderTestPrintf extends Module {
    val io = IO(new Bundle {
        val a = Input(UInt(2.W))
        val b = Input(UInt(2.W))
        val out = Output(UInt(2.W))
    })
        io.out := io.a & io.b
        printf("dut: %d %d %d\n", io.a, io.b, io.out)
    }

```
