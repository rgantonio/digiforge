# Chisel Project Directory
- In this directory, we explore some basic and easy designs. It is nice to compare how one makes things with Chisel vs. vanilla System Verilog code.
- Chisel is known to be much more productive because of the Scala language that is used for HDL.
- Think about Python and C, Chisel is like Python while System Verilog is more like C.
- Of course, in this case the degrees of freedom for configuration varies greatly.

# Getting Started
- Take note that you need to download scala for this.
- There are several projects in this directory, but make sure to always start here to run the `sbt.
- To generate a specific module do:

```bash
sbt "runMain samples.SimpleMain"
```

- Make sure that the scala code has the emitVerilog to generate the actual verilog code.
- To run a test do:

```bash
sbt "testOnly samples.SimpleTester"
```

- Make sure the tester has the main module for it.

# Directory Structure and Details

- `./src/main/scala`: contains all scala source files organized into their packages.
- `./src/test/scala`: contains all test benches also organized into their packages.
- `./generated`: this is generated when you run `sbt` to generate verilog files.
- `./test_run_dir`: this is generated when you run `sbt` to do simulations.
- `./project`: this is generated for every sbt run.
- `./target`: this is generated for every sbt run.



