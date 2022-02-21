ghdl -a ../bram/inferred_ram.vhd
ghdl -a ../fifo/sync_fifo.vhd
ghdl -a ../uart/uart_debugger_pkg.vhd
ghdl -a ../uart/uart_regfile.vhd

ghdl -a ov5640_sccb.vhd
ghdl -a ov5640_controller_pkg.vhd
ghdl -a ov5640_controller.vhd
ghdl -a ov5640_wrapper.vhd
ghdl -a ov5640_wrapper_tb.vhd

ghdl -r ov5640_wrapper_tb --stop-time=400us --wave=ov5640_wrapper_tb.ghw
pause
