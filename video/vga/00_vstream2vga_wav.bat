
ghdl -a vstream2vga.vhd

ghdl -a vstream2vga_tb.vhd
ghdl -r testbench --wave=vstream2vga.ghw --stop-time=10us

pause