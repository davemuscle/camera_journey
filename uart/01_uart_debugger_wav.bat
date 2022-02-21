ghdl -a ../bram/inferred_ram.vhd
ghdl -a ../fifo/sync_fifo.vhd
ghdl -a uart.vhd
ghdl -a uart_debugger.vhd
ghdl -a uart_debugger_tb.vhd

ghdl -r uart_debugger_tb --stop-time=200us --wave=uart_debugger_tb.ghw
pause
