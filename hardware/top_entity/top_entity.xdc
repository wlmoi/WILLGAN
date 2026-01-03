## PYNQ-Z1 Constraints File for WGAN Generator top_entity
## Rev C Board - Zynq XC7Z020 FPGA

# =====================================================
# Clock Signal - 125 MHz
# =====================================================
set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }]

# =====================================================
# Control Signals - Using Switches and Buttons
# =====================================================
# Reset (active low) - Button 0
set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { rst_n }]

# Start signal - Button 1
set_property -dict { PACKAGE_PIN D20   IOSTANDARD LVCMOS33 } [get_ports { start }]

# =====================================================
# Data Input - Using Pmod Header JA (8 pins = 16-bit in serial)
# =====================================================
# Note: data_in uses both timing and proper I/O placement
set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33 } [get_ports { data_in[0] }]
set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33 } [get_ports { data_in[1] }]
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { data_in[2] }]
set_property -dict { PACKAGE_PIN Y17   IOSTANDARD LVCMOS33 } [get_ports { data_in[3] }]
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { data_in[4] }]
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports { data_in[5] }]
set_property -dict { PACKAGE_PIN W18   IOSTANDARD LVCMOS33 } [get_ports { data_in[6] }]
set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33 } [get_ports { data_in[7] }]

# =====================================================
# Data Output - Using Pmod Header JB (8 pins = 16-bit out serial)
# =====================================================
set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33 } [get_ports { data_out[0] }]
set_property -dict { PACKAGE_PIN Y14   IOSTANDARD LVCMOS33 } [get_ports { data_out[1] }]
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { data_out[2] }]
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { data_out[3] }]
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { data_out[4] }]
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports { data_out[5] }]
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { data_out[6] }]
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { data_out[7] }]

# =====================================================
# Status Signals - Using LEDs
# =====================================================
# valid signal - LED 0
set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { valid }]

# busy signal - LED 1
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { busy }]

# FSM state[0] - LED 2
set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33 } [get_ports { state[0] }]

# FSM state[1] - LED 3
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { state[1] }]

# RGB LED 4 (Red) - state[2]
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { state[2] }]

# =====================================================
# Timing Constraints
# =====================================================
set_input_delay  -clock [get_clocks sys_clk_pin] -min 0.000 [get_ports {rst_n start data_in*}]
set_input_delay  -clock [get_clocks sys_clk_pin] -max 3.000 [get_ports {rst_n start data_in*}]

set_output_delay -clock [get_clocks sys_clk_pin] -min 0.500 [get_ports {data_out* valid busy state*}]
set_output_delay -clock [get_clocks sys_clk_pin] -max 3.000 [get_ports {data_out* valid busy state*}]

# Debug signal constraints (less critical)
set_output_delay -clock [get_clocks sys_clk_pin] -min 0.500 [get_ports {input_count* output_count*}]
set_output_delay -clock [get_clocks sys_clk_pin] -max 5.000 [get_ports {input_count* output_count*}]
