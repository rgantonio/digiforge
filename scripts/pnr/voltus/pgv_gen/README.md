# Power-Grid View (PGV) Generation

:alarm_clock: *Last update: 4/10/25*

This is the first step before doing power analysis. PGV is a library that contains the resistance and electron migration (EM) databases for power analysis. This is a requirement as either static or dynamic analysis requires the PGV libraries, annotated with a `.cl` data type.

There are 3 different PGV libraries that you need to generate: 
- Tech PGV: This is usually automatically generated already so we won't discuss this here.
- Standard Cell PGV: This is usually (or should be) provided by your foundry.
- Macro PGV: This is mostly for memories, custom IPs, or pads. You need to make this. We will focus on the macro PGV in this guide.

Note that in this guide, we assume that you provide also the spice and GDS information for more accurate library extraction.

# PGV for Macros

For this to work, you need the following:

- LEF files.
- Extraction command file (more details below).
- Cell list (more details below).
- The QRC tech file (this should be given by your foundry).
- LEF layermap (more details below).
- GDS layermap (more details below).

The [`pgv_gen.tcl`](./pgv_gen.tcl) has the following details:

1. Setup multiprocessing.

```tcl
# 1. Set multiprocessing
set_multi_cpu_usage -cpuPerRemoteHost 64 -remoteHost 64
```

2. Read LEF files

```tcl
# 2. Setup and read all lef files
set lef_dir_path "../path_to_lef_dir"

read_lib -lef { \
    $lef_dir_path/sram_512x32b.lef \
    $lef_dir_path/sram_256x64b.lef \
    $lef_dir_path/sram_256x128b.lef \
}

```

3. Setup PGV generation mode

First set the extraction mode and command for the run. This is mandatory to make the GDS extraction work.

```tcl
# Set extraction file for the GDS
set_advanced_pg_library_mode -xtc_command_file ./project.xtc
```

The `project.xtc` file just contains which metal and via layers need to be extracted. You need to be concistent with the tech LEF. For example, `project.xtc` could have:

```text
CONNECT M1 VIA1 M2 VIA2 M3 VIA3 M4 VIA4 M5 VIA5 M6 VIA6 M7 VIA7 M8 VIA8 M9 VIA9 M10 VIA10 M11 VIA11 M12 VIA12 M13 RV AP
```

Where all the `M*` and `VIA*` as well as the top metal `AP` and top via `RV` will be used. So the extraction tool sees this as to connect all the possible connections from all the layers. Of course, it depends on the libraries you are using. For the SRAM-like example we have, let's assume that all of these are connected.


The next command is to set the PGV library mode. There are several components to it:

```tcl
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
```

- `power_pins`: Power or source supplies. You need to set their operating voltage as well. Check your macro libraries.
- `ground_pins`: Ground supplies or power pins that need to be tied to 0.
- `cell_list_file`: This is just a list of all the cells you want to extract. It's possible that one LEF file can have multiple cells in it. This is just to specify which ones you need to extract. The list of names or macro names need to be consistent in the LEF, GDS, and spice files. Becareful if you have special IPs. For example it can contain the following:

```text
sram_512x32b
sram_256x64b
sram_256x128b
```

- `cell_type`: For this case we are using macros. There is also `tech` only and `std_cell`.
- `temperature`: Temperature.
- `extraction_tech_file`: This needs to be provided by your foundry. You should see it has the name `qrcTechFile`. It may change.
- `gds_files`: The corresponding GDS files for your macros.
- `spice_models`: The corresponding spice models for your macros.
- `lef_layermap`: The LEF layermap maps the name and usage of metals and vias. So it links the LEF definition to Voltus's (or Innovus's) definition. It contains the following:

```text
metal M1    lefdef M1   
metal M2    lefdef M2   
metal M3    lefdef M3   
metal M4    lefdef M4   
metal M5    lefdef M5   
metal M6    lefdef M6   
metal M7    lefdef M7   
metal M8    lefdef M8   
metal M9    lefdef M9   
metal M10   lefdef M10  
metal M11   lefdef M11  
metal M12   lefdef M12  
metal M13   lefdef M13  
metal AP    lefdef AP  
via   VIA1  lefdef VIA1 
via   VIA2  lefdef VIA2 
via   VIA3  lefdef VIA3 
via   VIA4  lefdef VIA4 
via   VIA5  lefdef VIA5 
via   VIA6  lefdef VIA6 
via   VIA7  lefdef VIA7 
via   VIA8  lefdef VIA8 
via   VIA9  lefdef VIA9 
via   VIA10 lefdef VIA10
via   VIA11 lefdef VIA11
via   VIA12 lefdef VIA12
via   RV    lefdef RV   
```

The 1st column indicates the type of component, the 2nd column is the name, 3rd should be `lefdef` to indicate it's a LEF definition, lastly the 4th is the LEF name.

- `gds_layermap`: The GDS layermap maps the name and usage of metals and vias of the GDS. So you need to map from GDS to Voltus (or Innovus). Similar to the lef layermap, this has the following example:

```text
metal M1    gds 31
metal M2    gds 32
metal M3    gds 33
metal M4    gds 34
metal M5    gds 35
metal M6    gds 36
metal M7    gds 37
metal M8    gds 38
metal M9    gds 39
metal M10   gds 40
metal M11   gds 41
metal M12   gds 42
metal M13   gds 43
metal AP	gds 74
via   VIA1  gds 51
via   VIA2  gds 52
via   VIA3  gds 53
via   VIA4  gds 54
via   VIA5  gds 55
via   VIA6  gds 56
via   VIA7  gds 57
via   VIA8  gds 58
via   VIA9  gds 59
via   VIA10 gds 60
via   VIA11 gds 61
via   VIA12 gds 62
via   RV    gds 85
```

In the 3rd column, you need to specify it as `gds` to indicate it's from a gds file. The 4th column is the functional code from the GDS. Where do you get it? Either check your DRC rule deck or manually check it in Cadence Virtuoso. The numbers are just examples to protect NDA.

4. Generate the library!

```tcl
# 4. Write the pg libraryexit
generate_pg_library -output $pgv_out_dir_path/sram_cell_pgv
```

At the end of this you should get a `.cl` library. You will use these files for power analysis.

# Other Notes

:pushpin: *Is it possible to create a PGV library without the GDS?* Yes! You just need to exclude the following:

- `set_advanced_pg_library_mode -xtc_command_file ./project.xtc` - this is not needed as this is used for GDS extraction only
- `gds_layermap` - option is of course not needed
- `spice_models` - the spice models are only matched with the GDS.

:pushpin: *It is recommended that you organize your PGV libraries*. For example, group together the SRAM PGV libraries. Create seperate libraries for PADs and custom IPs.


# Main References
:warning: You need to have a Cadence account to access these links. This guide is a synthesized version of all the information. The steps can vary from version to version so keep this updated as much as possible.

:bookmark: [Cadence: Power and Rail Analysis Using Voltus IC Integrity](https://support.cadence.com/apex/ArticleAttachmentPortal?id=a1O0V00000912FMUAY&pageName=ArticleContent)
- This has a more comprehensive guide. Might as well read it while running the scripts to understand each step.

:bookmark: [Cadence: Recommendations for characterizing mega cells like Macros, Memories, IOs, and IPs](https://support.cadence.com/apex/ArticleAttachmentPortal?id=a1O0V0000090tLOUAY&pageName=ArticleContent)

:bookmark: [Cadence: Generating the Standard Cells Power-Grid Library](https://support.cadence.com/apex/techpubDocViewerPage?%26xmlName%3D=voltusUGcom.xml&path=voltusUGcom%2FvoltusUGcom23.13%2Fpowergridlib_tk_Generating_the_Standard_Cells_Power-Grid_Library.html)