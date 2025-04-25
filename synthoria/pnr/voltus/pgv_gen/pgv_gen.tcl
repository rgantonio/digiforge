#------------------------
# PGV Generation Script
#------------------------

# 0. Directory setup
set lef_dir_path "../path_to_lef_dir"
set gds_dir_path "../path_to_gds_dir"
set spi_dir_path "../path_to_spi_dir"
set xtc_dir_path "../path_to_xtc_dir"
set qrc_dir_path "../path_to_xtc_dir"
set layermap_dir_path "../path_to_layermap_dir"
set pgv_out_dir_path "../path_to_pgv_out_dir"

# 1. Set multiprocessing
set_multi_cpu_usage -cpuPerRemoteHost 64 -remoteHost 64

# 2. Setup and read all lef files
read_lib -lef { \
    $lef_dir_path/sram_512x32b.lef \
    $lef_dir_path/sram_256x64b.lef \
    $lef_dir_path/sram_256x128b.lef \
}

# 3. Set PG mode library generation mode


# Set extraction file for the GDS
set_advanced_pg_library_mode -xtc_command_file $xtc_dir_path/project.xtc

# Just to make sure to reset all
set_pg_library_mode -reset

# Set the PGV library mode
set_pg_library_mode \
-power_pins {VDD 0.8 VDDPST 1.8} \
-ground_pins {VSS VSSPST POCCTRL ESD} \
-cell_list_file /users/micas/shares/project_snax/voltus_dir/cell_list/sram_cell.list \
-celltype macros \
-temperature 25 \
-extraction_tech_file $qrc_dir_path/typical/Tech/typical/qrcTechFile \
-gds_files { \
    $gds_dir_path/sram_512x32b.gds \
    $gds_dir_path/sram_256x64b.gds \
    $gds_dir_path/sram_256x128b.gds \
            } \
-spice_models { \
    $spi_dir_path/sram_512x32b.spi \
    $spi_dir_path/sram_256x64b.spi \
    $spi_dir_path/sram_256x128b.spi \
            } \
-lef_layermap $layermap_dir_path/project_lef.layermap \
-gds_layermap $layermap_dir_path/project_gds.layermap 

# 4. Write the pg libraryexit
generate_pg_library -output $pgv_out_dir_path/sram_cell_pgv





