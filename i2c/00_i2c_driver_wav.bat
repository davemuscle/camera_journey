ghdl -a i2c_driver.vhd
ghdl -a i2c_driver_tb.vhd

ghdl -r i2c_driver_tb --stop-time=40us --wave=i2c_driver_tb.ghw
pause
