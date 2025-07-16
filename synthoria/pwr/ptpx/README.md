# PrimeTime Power PX Power Analysis Script

:alarm_clock: *Last update: 7/16/25*

This guide explains how to use the `ptpx.tcl` script for PrimeTime (Synopsys) to do power analysis. There are two modes that you can do: (1) time-based and (2) average power. In time-based you can get peak and average, while average is just average. The advantage is a trade-off between accuracy and simulation-run time.

# Synthesis Steps

For this to work, you need to have the following:

- Filelist for your design. Preferrably the one already made into a `tcl` script which uses the commands for reading your RTL code.
- You need your main `.db` libraries for:
  - Standard cells
  - Pre-generated macros for memories
  - Custom IPs if needed and available
- You need your well-defined timing constraints, the `.sdc` file.
- You need to generate a `.vcd` or `.saif` file for analyzing toggle rates.
  - Note that `.vcd` are magnitudes larger in memory compared to `.saif` because it saves all signal toggles with the corresponding time in a database. `.saif` only saves the toggle counts.

## 0. Setup steps

This step is particularly preparing DC to maximize cores, naming strategies, and of course setting of libraries.

Below sets the number of max cores to be used and other switches to avoid limiting multiprocessing:

```tcl
# This sets the max number of cores to be used
set_host_options -max_cores 16
```

Define your working directories:

```tcl
set stdcell_dir_path "./path_to_stdcell_dir"
set memories_dir_path "./path_to_memories_dir"
set other_ip_dir_path "./path_to_other_ip_dir"

set workdir_path "./path_to_workdir"
set log_path "./path_to_logs"
set report_path "./path_to_reports"
set output_path "./path_to_outputs"

set sdc_constraints_path "./path_to_sdc_constraints"
set syn_rtl "./path_to_syn_rtl/system_top.v"
set top_saif "./path_to_saif/systolic_array.saif"
set top_module system_top
```
## 1. Set power analysis mode

PrimeTime (PT) is a tool that does both static-timing analysis (STA) and power analysis. You need to configure PT to be in power analysis mode. Also, the switch between time-based and averaged mode. Time-based measures both peak and average, and you can track at the certain time when the power spikes. Average is for faster simulation and analysis since it only looks into toggle time.

```tcl
set power_enable_analysis TRUE

# Change me to either time-based or averaged power analysis
# - time-based: uses switching activity from a VCD file
# - averaged: uses a SAIF file for average power analysis
set power_analysis_mode averaged
```

## 2. Set the library paths

This is a crucial step, because the libraries contain the logic gates to which your design will be linked to later. These libraries are provided by your foundry. Special libraries like the memories need to be generated. Generally, the libraries are generated along with the memory compiler. For custom IPs, like clock generators, they need to be provided as well. 

Consider some of the best practices:

- Best practice is to set the SS corner as the default
- Make sure to add all libraries from standard cells, memories, IOs, and other IPs like clock generators
- Best case to have all voltage and temperature ranges in the same values
- Take note that DC compiler uses .db so you may need to convert the .lib files to .db if they are not immediateley available

**Note: The `link_library` variable is a built-in variable which DC compiler uses**


```tcl
set target_library [list \
    $stdcell_dir_path/stdcells_ss_corner_0p75v85c.db \
    $memories_dir_path/memories_ss_corner_0p75v85c.db \
    $other_ip_dir_path/other_ip_ss_corner_0p75v85c.db \
]

set link_library "* $target_library"
```

## 3. Sourcing your design

At this step, we need to source and read the mapped synthesized design, set the top-module, and link it to the library.

```tcl
read_verilog $syn_rtl

current_design $top_module

link
```

## 4. Read the timing constraints and perform initial timing analysis

Simply read the well-defined timing constraints.

```tcl
read_sdc $sdc_constraints_path
```

Then we need to make sure the tool aligns the constraints with the design. In particular, this sets the input and output loads, then of course aligns with the operating frequency we are using.

```tcl
check_timing -verbose
update_timing
report_timing
```

## 5. read the switching activity file

At this point, you may want to analyze using your `.vcd` or `.saif` file and annotate the toggles and switches unto your design. The report after the `read_*` should return a 100% annotation. Otherwise, investigate what is causing the issue. You can also investigate deeper with the `report_switching_activity` and other options it provides. Your goal is to have a 100% annotatation, not unless there's a good reason not to complete it.


```tcl
read_saif $top_saif -strip_path tb_systolic_array
report_switching_activity -list_not_annotated

#-----------------------------
# Alternatively using VCD:
# invoke:
#
# read_vcd -rtl <path_to_vcd_file> -strip_path <appropriate strip>
# set_power_analysis_options -waveform_format fsdb -waveform_output vcd
#
# - Use this if we are interested in time-based power analysis
# - You can also do average power with this
# - WARNING: VCD files are magnitudes larger
#-----------------------------
```

## 6. Do some initial power checks and update the design

This is simply updating the design's power measruements. The `check_power` is an initial check and would be nice to observe any anomalies in the analysis.

```tcl
check_power
update_power 
```

## 7. Report generation

The main report generation is either `report_power` and `report_switching_activity` as they give the important details we are interested in.

```tcl
# Report power hierarchy
report_power -hierarchy -nosplit -verbose > $report_path/power_hierarchy.rpt

# Report easy summary
report_power -nosplit > $report_path/power.rpt

# Report some switching activity info
report_switching_activity -average_activity -hierarchy > $report_path/switching_activity_hierarchy.rpt
```


# Reference

Information on how to run these are scattered throughout the web. There are some new tools and some old.

- [Old PrimeTime PX 2010 Guide](https://picture.iczhiku.com/resource/eetop/SYieRrkKUOILfMvn.pdf): Was a hidden gem to use legacy analysis methodology.