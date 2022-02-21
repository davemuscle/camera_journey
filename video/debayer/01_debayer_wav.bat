
ghdl -a ../../bram/inferred_ram.vhd

ghdl -a ../timing/video_timing_generator.vhd
ghdl -a ../verification/image_reader.vhd
ghdl -a ../verification/pattern_generator.vhd
ghdl -a ../verification/image_writer.vhd

ghdl -a ../../fifo/sync_fifo.vhd
ghdl -a ../kernel/kernel_bufferer.vhd

ghdl -a debayer.vhd

ghdl -a debayer_tb.vhd
ghdl -r debayer_tb --wave=debayer_tb.ghw

pause