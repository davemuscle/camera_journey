ghdl -a ../bram/inferred_ram.vhd

ghdl -a uart_debugger_pkg.vhd
ghdl -a uart_regfile.vhd
ghdl -a uart_regfile_tb.vhd

ghdl -r uart_regfile_tb --stop-time=200us --wave=uart_regfile_tb.ghw
pause
