ghdl -a video_timing_generator.vhd

ghdl -a stream2dvp.vhd
ghdl -a dvp2stream.vhd

ghdl -a ../verification/image_reader.vhd
ghdl -a ../verification/pattern_generator.vhd
ghdl -a ../verification/image_writer.vhd

ghdl -a dvp_tb.vhd
ghdl -r dvp_tb --wave=dvp_tb.ghw

pause