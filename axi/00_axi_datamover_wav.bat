ghdl -a ../bram/inferred_ram.vhd
ghdl -a ../fifo/sync_fifo.vhd
ghdl -a axi_pkg.vhd
ghdl -a axi_bram_model.vhd
ghdl -a axi_datamover.vhd

ghdl -a axi_datamover_tb.vhd

ghdl -r axi_datamover_tb --stop-time=1000us --wave=axi_datamover_tb.ghw
pause
