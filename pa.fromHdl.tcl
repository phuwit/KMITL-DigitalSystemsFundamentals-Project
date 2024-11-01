
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name KMITL-DigitalSystemsFundamentals-Project -dir "/home/phuwit/Programming/KMITL-DigitalSystemsFundamentals-Project/planAhead_run_1" -part xc6slx9tqg144-3
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "/home/phuwit/Programming/KMITL-DigitalSystemsFundamentals-Project/main.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {input_decoder.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {main.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set_property top MAIN $srcset
add_files [list {main.ucf}] -fileset [get_property constrset [current_run]]
add_files [list {MAIN.ucf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc6slx9tqg144-3
