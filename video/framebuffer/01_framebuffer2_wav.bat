ghdl -a ../../bram/inferred_ram.vhd
ghdl -a ../../fifo/async_fifo.vhd
ghdl -a ../../fifo/sync_fifo.vhd
ghdl -a ../../cdc/pulse_sync_handshake.vhd
ghdl -a ../verification/image_writer.vhd
ghdl -a ../verification/image_reader.vhd
ghdl -a ../verification/pattern_generator.vhd
ghdl -a ../timing/video_timing_generator.vhd
ghdl -a ../../axi/axi_pkg.vhd
ghdl -a ../../axi/axi_bram_model.vhd
ghdl -a ../../axi/axi_datamover.vhd
ghdl -a ../timing/stream_pack.vhd
ghdl -a ../timing/stream_unpack.vhd
ghdl -a framebuffer_arbiter.vhd
ghdl -a framebuffer_addressing_vert.vhd
ghdl -a framebuffer_addressing_horz.vhd
ghdl -a framebuffer2.vhd
ghdl -a framebuffer2_tb.vhd

ghdl -r framebuffer2_tb --wave=framebuffer2_tb.ghw
pause
