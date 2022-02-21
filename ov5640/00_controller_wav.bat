ghdl -a ov5640_controller_pkg.vhd
ghdl -a ov5640_controller.vhd
ghdl -a ov5640_controller_tb.vhd

ghdl -r ov5640_controller_tb --stop-time=40us --wave=ov5640_controller_tb.ghw
pause
