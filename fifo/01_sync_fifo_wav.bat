ghdl -a ../bram/inferred_ram.vhd
ghdl -a sync_fifo.vhd
ghdl -a sync_fifo_tb.vhd

ghdl -r sync_fifo_tb --stop-time=40us --wave=sync_fifo_tb.ghw
pause
