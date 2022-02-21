ghdl -a ../i2c/i2c_driver.vhd

ghdl -a adv7513_i2c_if_pkg.vhd
ghdl -a adv7513_i2c_if.vhd
ghdl -a adv7513_i2c_if_tb.vhd
ghdl -r adv7513_i2c_if_tb --stop-time=80us --wave=adv7513_i2c_if_tb.ghw
pause
