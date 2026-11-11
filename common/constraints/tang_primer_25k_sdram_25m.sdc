create_clock -name clk50m -period 20.000 -waveform {0.000 10.000} [get_ports {clk}]
create_generated_clock -name sdram_user_clk -source [get_ports {clk}] -master_clock clk50m -divide_by 2 [get_nets {memory_clk}]
