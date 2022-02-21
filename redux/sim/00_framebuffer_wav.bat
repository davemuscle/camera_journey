ghdl -a ../bram/inferred_ram.vhd
ghdl -a ../fifo/async_fifo.vhd
ghdl -a ../cdc/pulse_sync_handshake.vhd
ghdl -a ../video_verification/image_writer.vhd
ghdl -a framestreamer_img_pkg.vhd
ghdl -a ../axi/axi_pkg.vhd
ghdl -a ../axi/axi_bram_model.vhd
ghdl -a ../axi/axi_datamover.vhd
ghdl -a framestreamer.vhd
ghdl -a framestreamer_tb.vhd

ghdl -r framestreamer_tb --wave=framestreamer_tb.ghw
REM ghdl -r framestreamer_tb --max-stack-alloc=1073741824
pause
