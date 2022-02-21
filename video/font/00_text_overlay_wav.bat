ghdl -a ../../bram/inferred_ram.vhd

ghdl -a ../verification/image_reader.vhd
ghdl -a ../verification/pattern_generator.vhd
ghdl -a ../verification/image_writer.vhd
ghdl -a text_overlay_font_pkg.vhd
ghdl -a text_overlay.vhd
ghdl -a NameAndFPS.vhd
ghdl -a text_overlay_tb.vhd
ghdl -r text_overlay_tb --wave=text_overlay_tb.ghw

pause