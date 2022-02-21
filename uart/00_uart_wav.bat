ghdl -a ../bram/inferred_ram.vhd
ghdl -a ../fifo/sync_fifo.vhd
ghdl -a uart.vhd
ghdl -a uart_tb.vhd

ghdl -r uart_tb --stop-time=2000us --wave=uart_tb.ghw
pause
