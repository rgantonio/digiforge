#------------------------
# Static IR Analysis
#------------------------

# 0. Directory setup
set designdb_dir_path "../path_to_designdb_dir"
set sdc_dir_path "../path_to_sdc_dir"
set log_dir_path "../path_to_log_dir"
set em_dir_path "../path_to_em_dir"
set qrc_dir_path "../path_to_qrc_dir"
set pgv_dir_path "../path_to_pgv_dir"

# 1. Set multiprocessing
set_multi_cpu_usage -cpuPerRemoteHost 64 -remoteHost 64

# 2. Load design database
read_design -physical_data $designdb_dir_path/project.inn.dat project_top

# 3. Make sure to set target SDC constraints
set_interactive_constraint_modes [all_constraint_modes -active]
update_constraint_mode -name target_mode -sdc_files $sdc_dir_path/target.sdc
set_propagated_clock [ all_clocks ]

# 4. Update and set the analysis views
set_analysis_view \
-setup [list \
   AV_TT_0P750V_085C_setup_worst_rcworst \
   AV_TT_0P800V_025C_setup_worst_typical \
] \
-hold [list \
   AV_FF_0P88V_0C_hold_best_rcbest \
   AV_TT_0P800V_025C_hold_best_typical \
   AV_TT_0P800V_025C_hold_worst_typical \
   AV_TT_0P750V_085C_hold_worst_rcworst \
]

# 5. Define power analysis mode
set_power_analysis_mode \
  -method static \
  -analysis_view AV_FF_0P88V_0C_hold_best_rcbest \
  -create_binary_db true \
  -write_static_currents true \
  -honor_negative_energy true \
  -ignore_control_signals true

# 6. Setting up power analysis

# Simply set where to dump the output
set_power_output_dir $log_dir_path/power_analysis

# Set target switching activity for un-annotated logic
set_default_switching_activity -reset
set_default_switching_activity -input_activity 0.20 -period 1.5 -global_activity 0.20

# 7. Generating power reports
report_power -cell_type all -outfile $log_dir_path/power_analysis/project_power_ffcorner_celltype_all.rpt
report_power -rail_analysis_format VS -outfile $log_dir_path/power_analysis/project_power_ffcorner.rpt

# 8. (Optional) Setting up EM analysis mode
set_signal_em_analysis_mode \
  -method {rms peak avg} \
  -detailed true \
  -useQrcTech true \
  -ict_em_models {$em_dir_path/technology.ictem}

# 9. Setting rail analysis mode

# Reset for to make sure
set_rail_analysis_mode -reset

# Actual setting of rail analysis mode
set_rail_analysis_mode -method static \
                       -accuracy hd \
                       -extraction_tech_file "$qrc_dir_path/typical/Tech/typical/qrcTechFile" \
                       -ict_em_models {$em_dir_path/technology.ictem} \
                       -em_peak_analysis true \
                       -force_library_merging true \
                       -power_grid_library {  
                            pgv_dir_path/sram_512x32b.cl \
                            pgv_dir_path/sram_256x64b.cl \
                            pgv_dir_path/sram_256x128b.cl \
                            pgv_dir_path/std_cell.cl \
                            pgv_dir_path/clk_gen.cl \
                            pgv_dir_path/dimc.cl \
                        }
