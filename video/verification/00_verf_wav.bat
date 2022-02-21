ghdl -a ../timing/video_timing_generator.vhd
ghdl -a image_reader.vhd
ghdl -a pattern_generator.vhd
ghdl -a image_writer.vhd

ghdl -a verf_tb.vhd
ghdl -r verf_tb --wave=verf_tb.ghw

pause