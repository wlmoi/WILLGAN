# =====================================================
# WGAN Generator - Vivado Build Script
# =====================================================
# Usage: vivado -mode batch -source build_project.tcl -tclargs [board_name]
# Boards: pynq_z1, zybo, kria, zcu104 (default)

puts "========================================"
puts "WGAN Generator FPGA Build Script"
puts "========================================"
puts ""

# =====================================================
# Configuration (must be first!)
# =====================================================
set project_name "wgan_build"
set project_base_dir "D:/WILLGAN/hardware/top_entity"

# Use timestamp-based unique directory to avoid cached runs
set timestamp [clock seconds]
set project_dir "$project_base_dir/build_$timestamp"

set src_dir "D:/WILLGAN/hardware"
set constraint_file "$project_base_dir/top_entity.xdc"

# Create temporary build directory
file mkdir $project_dir

# Get board selection from command line arguments
if {$argc > 0} {
    set board_name [lindex $argv 0]
} else {
    set board_name "zcu104"
}

# Board configuration
switch $board_name {
    "pynq_z1" {
        set target_part "xc7z020clg400-1"
        set board_part "tul.com.tw:pynq-z1:part0:1.0"
        puts "WARNING: Pynq-Z1 may not have enough resources"
    }
    "zybo" {
        set target_part "xc7z020clg400-1"
        set board_part "digilentinc.com:zybo-z7-20:part0:1.1"
        puts "WARNING: Zybo Z7 may not have enough resources"
    }
    "kria" {
        set target_part "xck26-sfvc784-2LV-c"
        set board_part "xilinx.com:kv260_som:part0:1.3"
        puts "Using Kria KV260 - sufficient resources"
    }
    "zcu104" {
        set target_part "xczu7ev-ffvc1156-2-e"
        set board_part "xilinx.com:zcu104:part0:1.1"
        puts "Using ZCU104 - sufficient resources (RECOMMENDED)"
    }
    default {
        puts "ERROR: Unknown board '$board_name'"
        puts "Valid options: pynq_z1, zybo, kria, zcu104"
        exit 1
    }
}

puts ""
puts "Board: $board_name"
puts "Part: $target_part"
puts "Build Directory: $project_dir"
puts "Sources: $src_dir"
puts "Constraints: $constraint_file"
puts ""

# =====================================================
# Project Setup
# =====================================================
puts "Setting up project..."

# Close any open project
catch {close_project}

# Remove entire .runs directory
if {[file exists "$project_dir/.runs"]} {
    puts "  Removing .runs directory..."
    catch {file delete -force "$project_dir/.runs"}
}

# Clean temporary files
if {[file exists "$project_dir/$project_name.xpr"]} {
    puts "  Cleaning existing project files..."
    catch {file delete -force "$project_dir/$project_name.cache"}
    catch {file delete -force "$project_dir/$project_name.hw"}
    catch {file delete -force "$project_dir/$project_name.sim"}
    catch {file delete -force "$project_dir/.Xil"}
    catch {file delete -force "$project_dir/$project_name.xpr"}
    after 500
}

# Create project - menggunakan -force yang kuat
puts "  Creating project..."
# Close first
catch {close_project}

# Create fresh project in unique directory
after 500
puts "  Creating project in fresh directory..."
create_project -force $project_name $project_dir -part $target_part

# Set board part if available
if {![catch {set_property board_part $board_part [current_project]}]} {
    puts "  Board part: $board_part"
}

puts ""

# =====================================================
# Add Files
# =====================================================
puts "Adding source files..."

# Utility modules
add_files -fileset sources_1 -force [glob "$src_dir/layers/fixed_point_alu.v"]
add_files -fileset sources_1 -force [glob "$src_dir/layers/neuron_processing_unit.v"]
add_files -fileset sources_1 -force [glob "$src_dir/layers/relu.v"]
add_files -fileset sources_1 -force [glob "$src_dir/layers/tanh_lut.v"]
add_files -fileset sources_1 -force [glob "$src_dir/layers/tanh.v"]
add_files -fileset sources_1 -force [glob "$src_dir/layers/leaky_relu.v"]
add_files -fileset sources_1 -force [glob "$src_dir/layers/pipelined_mac.v"]
add_files -fileset sources_1 -force [glob "$src_dir/layers/serialregisterIn.v"]
add_files -fileset sources_1 -force [glob "$src_dir/layers/serialregisterOut.v"]

# Generator layers
add_files -fileset sources_1 -force [glob "$src_dir/layers/layer1_generator_v2.v"]
add_files -fileset sources_1 -force [glob "$src_dir/layers/layer2_generator_v2.v"]
add_files -fileset sources_1 -force [glob "$src_dir/layers/layer3_generator_v2.v"]

# Generator pipeline
add_files -fileset sources_1 -force [glob "$src_dir/layers/generator.v"]

# Header files
add_files -fileset sources_1 -force [glob "$src_dir/layers/generator_layers.vh"]
add_files -fileset sources_1 -force [glob "$src_dir/layers/discriminator_layers.vh"]

# Top entity
add_files -fileset sources_1 -force [glob "$src_dir/top_entity.v"]

puts "  Source files added"

# Add constraints (use absolute path to constraint file in base dir)
puts "Adding constraint file..."
if {[file exists $constraint_file]} {
    add_files -fileset constrs_1 -force $constraint_file
    puts "  Constraint file added"
} else {
    puts "ERROR: Constraint file not found!"
    puts "Expected: $constraint_file"
    exit 1
}

puts ""

# =====================================================
# Set Top Module
# =====================================================
puts "Setting top module to: top_entity"
set_property top top_entity [current_fileset]
puts ""

# =====================================================
# Create Runs (Vivado creates default synth_1 and impl_1 with create_project)
# =====================================================
puts "Runs configuration..."
# The default runs are already created, just ensure they have correct properties

# Update compile order
puts "Updating compile order..."
update_compile_order -fileset sources_1
puts ""

# =====================================================
# Run Synthesis
# =====================================================
puts "========================================"
puts "Starting Synthesis..."
puts "========================================"
puts ""

launch_run synth_1 -jobs 4
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
puts "Synthesis Status: $synth_status"
puts ""

if {$synth_status != "synth_design_complete"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}

puts "Synthesis completed successfully!"
puts ""

# =====================================================
# Run Implementation
# =====================================================
puts "========================================"
puts "Starting Implementation..."
puts "========================================"
puts ""

launch_run impl_1 -jobs 4
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
puts "Implementation Status: $impl_status"
puts ""

if {$impl_status != "route_design_complete"} {
    puts "ERROR: Implementation failed!"
    exit 1
}

puts "Implementation completed successfully!"
puts ""

# =====================================================
# Generate Reports
# =====================================================
puts "Generating reports..."
open_run impl_1

report_utilization -file "$project_dir/utilization_report.txt"
report_timing_summary -file "$project_dir/timing_summary.txt"
report_power -file "$project_dir/power_report.txt"

puts "Reports generated"
puts ""

# =====================================================
# Generate Bitstream
# =====================================================
puts "========================================"
puts "Generating Bitstream..."
puts "========================================"
puts ""

write_bitstream -force "$project_dir/top_entity.bit"

puts "Bitstream generated: $project_dir/top_entity.bit"
puts ""

# =====================================================
# Finalize
# =====================================================
puts "========================================"
puts "Build Complete!"
puts "========================================"
puts ""
puts "Output Files:"
puts "  Bitstream: $project_dir/top_entity.bit"
puts "  Utilization: $project_dir/utilization_report.txt"
puts "  Timing: $project_dir/timing_summary.txt"
puts "  Power: $project_dir/power_report.txt"
puts ""

puts "Saving project..."
save_project_as -force -overwrite $project_name $project_dir

close_project

puts "========================================"
puts "Done!"
puts "========================================"

exit 0
