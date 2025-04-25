#-----------------------------
# Synthesis script for Synopsys Design Compiler
#-----------------------------

#-----------------------------
# 0. Setup steps
#-----------------------------

# This sets the max number of cores to be used
set_host_options -max_cores 16

# Need to enable these variables
# To ensure that the cores run in parallel
set disable_multicore_resource_checks true
set dcnxt_adaptive_multithreading true

# Set other synthesis settings
# Preserve FF with not load used as spare"
set hdlin_preserve_sequential ff+loop_variables

# Set the naming rules for the design
# Add any additional Design Compiler variables needed here
define_name_rules verilog \
    -target_bus_naming_style "%s\[%d\]" \
    -first_restricted "0-9_" \
    -replacement_char "_" \
    -equal_ports_nets -inout_ports_equal_nets \
    -collapse_name_space -case_insensitive -special verilog \
    -add_dummy_nets \
    -dummy_net_prefix "synp_unconn_%d" \
    -preserve_struct_ports

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

#-----------------------------
# 1. Set the library paths
#-----------------------------

# - Best practice is to set the SS corner as the default
# - Make sure to add all libraries from standard cells, memories, IOs, and other IPs like clock generators
# - Best case to have all voltage and temperature ranges in the same values
# - Take note that DC compiler uses .db so you may need to convert the .lib files to .db if they are not immediateley available

set target_library [list \
    $stdcell_dir_path/stdcells_ss_corner_0p75v85c.db \
    $memories_dir_path/memories_ss_corner_0p75v85c.db \
    $other_ip_dir_path/other_ip_ss_corner_0p75v85c.db \
 ]

set link_library "* $target_library"

#-----------------------------
# 2. Sourcing your design
#-----------------------------

# Sourcing your filelist, it can be in any format
source $flist_path/syn_flist.tcl

# Elaborate to check and see the synthesizability of the design
# Also check for latches at this point
# Eveen with weird looking components
elaborate system_top

# Apply the defined named rules to the design
change_names -rules verilog -hierarchy

# Set the top module of your design
current_design system_top

# Link the elaborated design to the libraries
# At this step you should verify that the link is correct
# It reports an error if there are missing libraries that
# cannot be mapped to the elaborated deisgn
link

# Do a check of the design
# You would see a summary of several parameters
# e.g., unconnected ports, combinational logic ... etc.
check_design > $log_path/check_design.log

#-----------------------------
# 3. Read the timing constraints
#-----------------------------

# Make sure this is well defined
source $sdc_constraints_path/syn_constraints.sdc

#-----------------------------
# 4. Set other optimization settings
#-----------------------------

# Prioritize delay
set_cost_priority -delay

# Buffer constants to reduce density
set_fix_multiple_port_nets -all -buffer_constants

#-----------------------------
# 5. Set special rules for the design
#-----------------------------

# E.g., in some cases there are components you don't want to be touched or optimized
# This is important for the tie cells and other technology specific cells like the RTE

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

#-----------------------------
# 5. Main compiler command
#-----------------------------
compile_ultra -retime

#-----------------------------
# 6. Report generation
#-----------------------------
# There are several reports of different types and settings that can be generated

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

#-----------------------------
# 7. (Optional) Further optimization
#-----------------------------
# This is optional and can be used to further optimize the design

# Automatically group critical paths
create_auto_path_groups -mode mapped

# Optimize the design incrementally on the critical paths only
compile_ultra -incremental

# Reset the groups since some of the critical paths may have been cleared
remove_auto_path_groups

# Redo the reports here again
report_qor -significant_digits 5 > $report_path/qor_after_opt.rpt

#-----------------------------
# 8. Write the final design
#-----------------------------

# Write the netlist
write_file -format verilog -hierarchy -output $output_path/occamy_chip_mapped.v

# Write the database
write_file -format ddc -hierarchy -output $output_path/occamy_chip_mapped.ddc

# Write the delay annotations
write_sdf $output_path/occamy_chip_mapped.sdf

# Save the final design constraints
write_sdc $output_path/occamy_chip_mapped.sdc

#-----------------------------
# Finish
#-----------------------------
quit
