
ghdl -a ov5640_vstream.vhd
ghdl -a ov5640_vstream_tb.vhd

ghdl -r ov5640_vstream_tb --stop-time=400us --wave=ov5640_vstream_tb.ghw
pause
