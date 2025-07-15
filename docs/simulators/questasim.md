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