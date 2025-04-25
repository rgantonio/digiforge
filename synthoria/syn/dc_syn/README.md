# DC Compiler (Synopsys) Synthesis Script

:alarm_clock: *Last update: 4/25/25*

This guide explains how to use the `dc_syn.tcl` script for DC Compiler (Synopsys). The main goal is to produce a gate-level netlist based on your RTL design.

# Synthesis Steps

For this to work, you need to have the following:

- Filelist for your design. Preferrably the one already made into a `tcl` script which uses the commands for reading your RTL code.
- You need your main `.db` libraries for:
  - Standard cells
  - Pre-generated macros for memories
  - Custom IPs if needed and available
- You need your well-defined timing constraints, the `.sdc` file.

## 0. Setup steps

This step is particularly preparing DC to maximize cores, naming strategies, and of course setting of libraries.

Below sets the number of max cores to be used and other switches to avoid limiting multiprocessing:

```tcl
# This sets the max number of cores to be used
set_host_options -max_cores 16

# Need to enable these variables
# To ensure that the cores run in parallel
set disable_multicore_resource_checks true
set dcnxt_adaptive_multithreading true
```

Defining rules for re-writing the netlist later:

```tcl
define_name_rules verilog \
    -target_bus_naming_style "%s\[%d\]" \
    -first_restricted "0-9_" \
    -replacement_char "_" \
    -equal_ports_nets -inout_ports_equal_nets \
    -collapse_name_space -case_insensitive -special verilog \
    -add_dummy_nets \
    -dummy_net_prefix "synp_unconn_%d" \
    -preserve_struct_ports
```

Define your working directories and search paths:

```tcl
set workdir_path "./path_to_workdir"
set log_path "./path_to_logs"
set report_path "./path_to_reports"
set output_path "./path_to_outputs"
set flist_path "./path_to_flist"
set sdc_constraints_path "./path_to_sdc_constraints"
set stdcell_dir_path "./path_to_stdcell_dir"
set memories_dir_path "./path_to_memories_dir"
set other_ip_dir_path "./path_to_other_ip_dir"

# Define working directories
define_design_lib WORK -path $workdir_path/work
set search_path "$search_path $log_path $output_path $sdc_constraints_path ./"
```

## 1. Set the library paths

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

## 2. Sourcing your design

At this step, we need to source and read the RTL design, then do an elaboration to check the details of the design.

First, we read the design:

```tcl
source $flist_path/syn_flist.tcl
```

Then, we do an elaboration. During elaboration we get several details like how many registers are used, unconnected ports, and even how many **combinational loops and latches (things that must be avoided!)**. Make sure to indicate the top-level module to be used.

```tcl
elaborate system_top
```

Change the elaborated names in the design to the rules defined earlier in step 0:

```tcl
change_names -rules verilog -hierarchy
```

Set the top-level module:

```tcl
current_design system_top
```

Link the elaborated design to the libraries. At this step you should verify if the link is correct. It reports an error if there are missing libraries that cannot be mapped to the elaborated deisgn.

```tcl
link
```

Finally, do a check of the design to see if there are any dubious design details.

```tcl
check_design > $log_path/check_design.log
```

## 3. Read the timing constraints

Simply read the well-defined timing constraints.

```tcl
source $sdc_constraints_path/syn_constraints.sdc
```

## 4. Set other optimization settings

Add other optimization settings:

```tcl
# Prioritize delay
set_cost_priority -delay

# Buffer constants to reduce density
set_fix_multiple_port_nets -all -buffer_constants
```

## 5. Set special rules for the design

In some cases there are components you don't want to be touched or optimized. This is important for the tie cells and other technology specific cells like the RTE:

```tcl
# Preserving the RTE net
set_dont_touch [get_nets {wire_rte}]
set_compile_directives -constant_propagation false [get_lib_cells */RTE_CELL]

# Don't touch tie cells
set_dont_touch [get_cells clock_dvddpg]
set_dont_touch [get_cells clock_dvddpgz]
set_dont_touch [get_cells clock_dislvl]
set_dont_touch [get_cells clock_dislvlz]

set_dont_touch [get_nets clock_dvddpg]
set_dont_touch [get_nets clock_dvddpgz]
set_dont_touch [get_nets clock_dislvl]
set_dont_touch [get_nets clock_dislvlz]
```

## 5. Main compiler command

Note that there are several initial options that go along with the `compile_ultra` command. Depending on the design and depending on your needs for the design, you may want to switch other options.

Some nice to know options:
- `incremental`: Use this after the initial compile to further optimize your design.
- `no_autoungroup`: This avoids breaking the boundaries of each module of your design.
- `retime`: Automatically retimes registers to meet setup time.

More details of these options can be accessed through the documentation, or do a `man` command within the tool. For example, `man compile_ultra` displays the options and their descriptions in the terminal.

```tcl
compile_ultra -retime
```

## 6. Report generation

There are several reports that can be generated. It is better to check the list from the documentation, or use the `man` again from the terminal. 

The most important summary report is the `qor` since it display thes WNS, TNS, number of violating paths, and even estimated hold violations. It gives a good *overview* of your design. If you have well-defined SDC constraints with path groups, it also display the statistics for each path group.

```tcl
# General QoR report
report_qor -significant_digits 5 > $report_path/qor.rpt

# Reporting all the timing violations
# Warning: this can be huge so you can also limit the max number of violations
report_constraint -all_violators -nosplit -verbose -significant_digits 5 -max_delay > $report_path/constraint_report_setup.rpt
report_constraint -all_violators -nosplit -verbose -significant_digits 5 -min_delay > $report_path/constraint_report_hold.rpt

# Reporting area of the design
report_area > $report_path/area_report.rpt
report_area -hierarchy -nosplit > $report_path/area_hierarchy.rpt

# Reporting the power of the design
report_power > $report_path/power_report.rpt
report_power -hierarchy > $report_path/power_report_hierarchy.rpt
report_power -verbose > $report_path/power_report_verbose.rpt
report_power -verbose -hierarchy > $report_path/power_report_verbose_hierarchy.rpt
```

##  7. (Optional) Further optimization

This step is highly optional but a very useful for cleaning up the quality of your design. Typically, a better design is when number of violations, and effectively, the TNS is reduced. Sometimes the WNS is not fully-optimized, but reducing the total number of violations also indirectly helps with meeting the timing of the entire design. More details can be found in the documentation:

```tcl
# Automatically group critical paths
create_auto_path_groups -mode mapped

# Optimize the design incrementally on the critical paths only
compile_ultra -incremental

# Reset the groups since some of the critical paths may have been cleared
remove_auto_path_groups

# Redo the reports here again
report_qor -significant_digits 5 > $report_path/qor_after_opt.rpt
```

In the end, you can compare the QoR of the design again. You may want to iterate this step if you want. Take note, that further optimizing also increases overall run-time. *You do not need to over design the synthesis for the backend. It is the backend that does the final checking*

## 8. Write the final design

Writing the outputs of the design:


```tcl
# Write the netlist
write_file -format verilog -hierarchy -output $output_path/occamy_chip_mapped.v

# Write the database
write_file -format ddc -hierarchy -output $output_path/occamy_chip_mapped.ddc

# Write the delay annotations
write_sdf $output_path/occamy_chip_mapped.sdf

# Save the final design constraints
write_sdc $output_path/occamy_chip_mapped.sdc
```

# Generating `.db` Files from `.lib`

In several cases, only the `.lib` timing libraries are available. To fix this, we need to generate `.db` which DC uses. To do so, you need to create a shell script:

```tcl
set lib_path "./path_to_lib"
set db_path  "./path_to_db"

read_lib $lib_path/std_cell_ss_0p75v85c.lib
read_lib $lib_path/std_cell_tt_0p8v25c.lib
read_lib $lib_path/std_cell_ff_0p88v0c.lib

write_lib std_cell_ss_0p75v85c -f db -o $db_path/std_cell_ss_0p75v85c.db
write_lib std_cell_tt_0p8v25c  -f db -o $db_path/std_cell_tt_0p8v25c.db
write_lib std_cell_ff_0p88v0c  -f db -o $db_path/std_cell_ff_0p88v0c.db
```

In the above:

- `read_lib` basically reads the `.lib` file.
- `write_lib` re-writes the newly read lib into `.db` format with `-f db` to the file indicated by the `-o` argument.

These are the `.db` files that need to be read in step number 1.
