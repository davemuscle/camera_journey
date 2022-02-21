ghdl -a ../bram/inferred_ram.vhd
ghdl -a async_fifo.vhd
ghdl -a async_fifo_tb.vhd

ghdl -r async_fifo_tb --stop-time=40us --wave=async_fifo_tb.ghw
pause
