import os
import sys
import re

# Change these based on MATLAB results / font generation
CHAR_HEIGHT = 50
CHAR_WIDTH  = 29
NUM_CHARS   = 95
pkg_name = "text_overlay_font_pkg.vhd"
font_file = "font_data.txt"

# ########################################################

if os.path.exists(pkg_name):
    os.remove(pkg_name)

pkg = open(pkg_name, "x")

pkg.write("--Auto Generated PKG File For Displaying Fonts\n")
pkg.write("library IEEE;\nuse IEEE.std_logic_1164.all;\nuse IEEE.numeric_std.all;\n\n")
pkg.write("package text_overlay_font_pkg is\n\n")

pkg.write("\tconstant CHAR_HEIGHT : integer := " + str(CHAR_HEIGHT) + ";\n")
pkg.write("\tconstant CHAR_WIDTH  : integer := " + str(CHAR_WIDTH ) + ";\n")
pkg.write("\tconstant NUM_CHARS   : integer := " + str(NUM_CHARS  ) + ";\n")

pkg.write("\n\ttype font_rom_t is array(0 to CHAR_HEIGHT*NUM_CHARS-1) of std_logic_vector(CHAR_WIDTH-1 downto 0);\n")
pkg.write("\tconstant font_rom : font_rom_t := (\n")

font = open(font_file,"r")
line_cnt = 0
for font_line in font:

    if line_cnt != 0:
        pkg.write(",\n")
        
    font_line = re.sub(",","",font_line)
    font_line = re.sub("\n","",font_line)
    
    if line_cnt < 10:
        num_spaces = "    "
    elif line_cnt < 100:
        num_spaces = "   "
    elif line_cnt < 1000:
        num_spaces = "  "
    else:
        num_spaces = " "
    
    
    pkg.write("\t\t" + str(line_cnt) + num_spaces + " => \"" + str(font_line) + "\"")
    line_cnt = line_cnt + 1
    
pkg.write("\n\t);\n")
pkg.write("end text_overlay_font_pkg;")
    