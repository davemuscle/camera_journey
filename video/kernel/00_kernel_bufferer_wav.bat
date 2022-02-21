ghdl -a ../../bram/inferred_ram_w_reset.vhd
ghdl -a ../../bram/inferred_ram.vhd
ghdl -a ../../fifo/sync_fifo.vhd

ghdl -a ../timing/video_timing_generator.vhd

ghdl -a kernel_bufferer.vhd

ghdl -a kernel_bufferer_tb.vhd
ghdl -r kernel_bufferer_tb --wave=kernel_bufferer_tb.ghw

pause