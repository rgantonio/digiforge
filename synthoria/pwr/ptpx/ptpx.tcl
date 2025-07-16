#-----------------------------
# 0. Set-up Directories and Settings
#-----------------------------

# This sets the max number of cores to be used
set_host_options -max_cores 16

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

#-----------------------------
# 1. Set the power analysis mode
#-----------------------------
set power_enable_analysis TRUE

# Change me to either time-based or averaged power analysis
# - time-based: uses switching activity from a VCD file
# - averaged: uses a SAIF file for average power analysis
set power_analysis_mode averaged

#-----------------------------
# 2. Read technology  lib
#-----------------------------

set target_library [list \
    $stdcell_dir_path/stdcells_ss_corner_0p75v85c.db \
    $memories_dir_path/memories_ss_corner_0p75v85c.db \
    $other_ip_dir_path/other_ip_ss_corner_0p75v85c.db \
]

set link_library "* $target_library"

#-----------------------------
# 3. Read and link the design
#-----------------------------

read_verilog $syn_rtl

current_design $top_module

link

#-----------------------------
# 4. Set input transition and annotate parasitics
#-----------------------------

read_sdc $sdc_constraints_path

#-----------------------------
# Performing timing analysis before running the `update_power` command
# This improves performance and avoids additional timing updates 
# triggered by the switching activity annotation commands
#-----------------------------
check_timing -verbose
update_timing
report_timing

#-----------------------------
# 5. Read the switching activity file
#-----------------------------
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

#-----------------------------
# 6. Perform power analysis
#-----------------------------
check_power
update_power 

#-----------------------------
# 7. Report Results
#-----------------------------

# Report power hierarchy
report_power -hierarchy -nosplit -verbose > $report_path/power_hierarchy.rpt

# Report easy summary
report_power -nosplit > $report_path/power.rpt

# Report some switching activity info
report_switching_activity -average_activity -hierarchy > $report_path/switching_activity_hierarchy.rpt

#-----------------------------
# Finish
#-----------------------------
quit