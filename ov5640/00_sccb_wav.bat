ghdl -a ov5640_sccb.vhd
ghdl -a ov5640_sccb_tb.vhd

ghdl -r ov5640_sccb_tb --stop-time=40us --wave=ov5640_sccb_tb.ghw
pause
