ghdl -a ../bram/inferred_ram.vhd

ghdl -a ../fifo/sync_fifo.vhd
ghdl -a ../fifo/async_fifo.vhd

ghdl -a ../cdc/pulse_sync_handshake.vhd

ghdl -a ../axi/axi_pkg.vhd
ghdl -a ../axi/axi_bram_model.vhd
ghdl -a ../axi/axi_datamover.vhd

ghdl -a ../i2c/i2c_driver.vhd

ghdl -a ../uart/uart.vhd
ghdl -a ../uart/uart_debugger.vhd

ghdl -a ../ov5640/ov5640_controller_pkg.vhd
ghdl -a ../ov5640/ov5640_sccb.vhd
ghdl -a ../ov5640/ov5640_controller.vhd
ghdl -a ../ov5640/ov5640_wrapper.vhd

ghdl -a ../adv7513/adv7513_i2c_if.vhd
ghdl -a ../adv7513/adv7513_hdmi_if.vhd

ghdl -a ../video/timing/dvp2stream.vhd

ghdl -a ../video/verification/image_reader.vhd
ghdl -a ../video/verification/image_writer.vhd
ghdl -a ../video/verification/pattern_generator.vhd

ghdl -a ../video/vga/vstream2vga.vhd

ghdl -a ../video/stereoscopics/stream_combiner.vhd
ghdl -a ../video/stereoscopics/frequency_monitor.vhd

ghdl -a ../video/kernel/kernel_bufferer.vhd
ghdl -a ../video/debayer/debayer.vhd

ghdl -a ../video/framebuffer/framebuffer_logic.vhd
ghdl -a ../video/framebuffer/framebuffer_arbiter.vhd
ghdl -a ../video/framebuffer/framebuffer_addressing_horz.vhd
ghdl -a ../video/framebuffer/framebuffer_addressing_vert.vhd
ghdl -a ../video/framebuffer/framebuffer.vhd

ghdl -a ../video/camera/camera_stim.vhd

ghdl -a ../system/camera_bridge_top_regfile.vhd

ghdl -a app_top.vhd

ghdl -a app_top_tb.vhd

ghdl -r app_top_tb --wave=app_top_tb.ghw
pause
