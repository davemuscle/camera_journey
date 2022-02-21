ghdl -a ../bram/inferred_ram.vhd

ghdl -a uart_debugger_pkg.vhd
ghdl -a uart_debugger_switchbox.vhd
ghdl -a uart_debugger_switchbox_tb.vhd

ghdl -r uart_debugger_switchbox_tb --stop-time=200us --wave=uart_debugger_switchbox_tb.ghw
pause
