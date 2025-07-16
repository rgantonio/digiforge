# :milky_way: Questasim Simulator Guide

Questasim is a commercial tool but it has several perparation steps. We'll do step-by-step for guidance.

:milky_way: You need to make a verilog library. The code below creates a verilog work library called `work`.

```bash
vlib work
```

:milky_way: Load the RTL one by one:

```bash
vlog -sv <path to RTL> <path to TB>
```

Or through filelist:

```bash
vlog -sv -f <path to filelist>
```

If you plan to add include files:

```bash
vlog -sv -f <path to filelist> +incdir+<path to incdir>
```

:milky_way: To invoke questasim and run simulations run the following below.
- the `-voptargs="+acc"` tracks all signals (but does not necessarily dump waves immediatley) and consider them to be viewable manually in the GUI.
- `work.tb_top` needs to replace `tb_top` with the target top-module testbench you will run.
- the `-do "<insert commands>"` runs the commands inside the questasim terminal immediatley.
  - `add wave -r /*` - dumps all the waves when simulation runs.
  - `run -all` - run until the end. You can alternatively do `run 100us` with a specified time if needed.

```bash
vsim -voptargs="+acc" work.tb_top -do "add wave -r /*; run -all"
```

:milky_way: It is better to make a run from a `script.do` file with the following sequence:

```tcl
# Make work directories
vlib work

# Source files
vlog -sv -f <insert filelist> +incdir+<path to incdir>

# VSIM commands
vsim -voptargs="+acc" wotk.<insert tb top>

# Run commands
add wave -r /*
run -all
```

Then call it via `vsim -gui -do script.do`.

:milky_way: Optionally, if you don't want the gui but just to load the program and run the testbench without signals, you can do `vsim -c -do script.do`.

:milky_way: Questasim is useful to annotate SDF and simulate actual logic gate delays. In your `.do` script make sure to add `-sdftyp /tb_top/i_top=<path to sdf>/top.sdf` such that:

```tcl
vsim -voptargs="+acc" work.tb_top -sdftyp /tb_top/i_top=<path to sdf>/top.sdf -do "add wave -r /*; run -all"
```

Where the left-side of the equals is the hierarchical path in simulation and the right-hand side is the path to the sdf.

:warning: There are times when SDF annotation isn't correct due to the following reasons:

- The path of your hierarchy and the one in the sdf may not match. Make sure you have the correct hierarchy.
- There are some escape characters that are not friendly. In questasim, the square brackets `[]` need to be escaped with `\[ \]` otherwise it will complain.

:milky_way: Sometimes, some of those hanging delays may not be important for synthesis measurements so you can skip them. Just add the `-sdfnoerror` into the `vsim` arguments.

:warning: This can be a make or break. Sometimes it is okay, sometimes it is not. The only time it is OK if it hits a clock-domain crossing (CDC) which are mostly hold violations due to the clock. If it's a setup problem, you need to sanity check it.


:milky_way: A good sdf annotation is when it achieves 100% annotation and when there are no errors. Bypassing errors is a "watch-out!" scenario. If you see negative timing checks, that is fine because it is due to the library specs. Negative timing checks appear as warnings anyway.


:milky_way: To do proper power analysis, we need to generate `.saif` files (switching activitiy) for a more compact model for toggling against the `.vcd` which is magnitudes higher on memory consumption. The correct solution is hidden in the [Xilinx guide](https://docs.amd.com/r/en-US/ug900-vivado-logic-simulation/Dumping-SAIF-in-Questa-Advanced-Simulator/ModelSim). Just in case the site gets obsolete the solution is to add `power add <insert module to record>` and `power report -all -basif <insert dump file>` to dump the SAIF.

```tcl
power add -r tb_top/i_dut/*
run -all
power report -all -bsaif dut.saif
```

- Take note that the `-r` needs to be before the top-module path.
