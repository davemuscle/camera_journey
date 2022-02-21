# Mandlebrot Fractal Engine - FPGA
![Image](/doc/cam_switching.gif)

*Migrated to Git on February 20th, 2022. Original release on May 23rd, 2021*.

This is my first “nonrelease”: a self-project that has no good output. I didn’t really have a clear
vision or goal of the project going into this, so there were a few unexpected twists, turns, and
burns. I like to think the journey and the things you learn along the way are more important than
having a pretty product at the end. We’ll see.

The general timeframe for this project was between November 2020 to May 2021. A good “vertical
slice” of the project was finished before New Years, and I took a few breaks after that. I gave a
few weeks to play(?) Skyrim, a few weeks to play Valheim, some time to goof around with a Discord
bot in Python, and some time to speedrun video games. There were also a lot of nights of just not
wanting to do anything technical after getting off work.

## Journey's Start
It all started when I bought another FPGA board after the Fractal Project (link). Instead of getting
another Xilinx board, I decided I was going to go back to Altera with the DE10-Nano by Terasic.
Altera chips were the ones we used in school for learning digital logic / design.

| ![Image](/doc/de10nano.jpg) |
| :--: |
| *DE10-Nano from Terasic* |

The DE10-Nano is a nice SoC (System-on-Chip) board from Terasic for $150. It’s an FPGA coupled with
a CPU on the same chip.

The FPGA is a fairly sizable Cyclone V, with 110K LEs (4-input logic elements). The FPGA
architecture can also make use of Altera’s 8-input logic elements called ALMs. Equivalently, you get
40K ALMs. It would be a good data point to benchmark these and compare them to the flagship 6-input
LUTs of the 7series parts.

The CPU is a dual-core ARM Cortex A9 running at 800 MHz. It’s accompanied with an awesome 3500 page
manual of register descriptions (much less fun and interesting than FPGA architecture, huh!). Altera
refers to this part of the SoC as the HPS, the Hard Processor System.

## Twist One: The Pocket Synthesizer

The initial idea of the project was to make a handheld audio synthesizer. I’d slap a PCB with an
audio codec, a mini LCD, and a suite of input directly on top of the 2x20 male headers. I quickly
designed the schematic in KiCad, but ran into size constraints when picking out parts on DigiKey. If
it couldn’t have all the buttons I wanted, I wasn’t interested. So eventually this idea fizzled out.
The screenshot below is how far I got in the layout process of the PCB.

| ![Image](/doc/pocket_synth_end.png) |
| :--: |
| *Plug-in Synthesizer End* |

## Twist Two: The Single Camera

I’ve had some experience working with camera modules, namely the OV5640 from Omnivision. I decided
that hooking up one of these to the DE10-Nano and then implementing some real-time video effects via
FPGA would be fun. I ended up buying one of Waveshare’s camera modules for $25. These versions of
the OV5640 are easier to use since they send data over a parallel video port, instead of MIPI.

| ![Image](/doc/waveshare_board.jpg) |
| :--: |
| *Waveshare OV5640* |

The basic data flow idea was to have the camera send a raw 1920x1080 pixel stream at ~30 FPS into
the FPGA, buffer it, convert the Bayer sensor data to RGB, and send it to the HDMI sink. Here's the
hardware that had to be written to get the camera feed to show up on a TV or monitor:

| ![Image](/doc/FPGA_1cam.png) |
| :--: |
| *FPGA Block Diagram for Single Camera Setup* |


- **OV5640 Controller**
    - Main controller that drives the design. It contains an SCCB (I2C) driver and a FIFO for sending register reads and writes to the camera during run-time. I had to rewrite the I2C driver used in the ADV7513 controller because Omnivision are dumb hacks. They copied the I2C bus and renamed it to SCCB to avoid paying royalties to Phillips. Problem with that is their device easily holds the bus hostage unless you give it special treatment.
- **DVP to AXI Video**
    - The start of the video datapath. Converts a parallel video port (HREF, VSYNC, 8 data bits) into AXI Video (SOF, EOL, Valid, 8 data bits).
- **Framebuffer**
    - Video buffering to provide a constant output stream at 1080p 60 FPS. Fun to design because there were three clock domains to handle.
- **Debayer**
    - Performs image demosaicing with multiple 5x5 sliding kernels. Converts raw sensor image data into the RGB colorspace
- **AXI Video to VGA**
    - Converts AXI video into VGA (HSYNC, VSYNC, DE, 24 data bits).
- **ADV7513 Controller**
    - Final output of the design. I2C commands initialize the ADV7513 chip by Analog Devices onboard the DE10-Nano. This handles the TMDS encoding and serialization of the VGA stream. Pretty easy chip to use and it's well documented.


## The Fun of Cameras

Like most other camera sensors, the documentation for the OV5640 is horrible or nonexistent. The
register maps have tons of hidden/reserved registers that are actually needed to get it to function
well. The manufacturers hide these registers expecting companies to purchase thousands of their
camera sensors, and sign an NDA with them for a user guide. Even after that, the user guide is in
broken English, and only works for certain camera setups. If you need to change camera settings or
resolutions, have fun. Although sparse, there is good documentation and drivers from users floating
around on Github and EEVblog. I had to spend a while to get these registers right, so I'm including
them in the references.

## The Framebuffer and the HPS

The most difficult part of the design was the frame buffering. Because standard monitors won’t
accept 1080p at 30 FPS, and because the camera frame rate isn’t exact, the input stream needs to be
buffered and read out at 1080p at 60 FPS. The answer to this is the triple-buffered frame buffer.

| ![Image](/doc/framebuffer_design.png) |
| :--: |
| *Framebuffer Design* |



For an uncompressed raw Bayer stream at 8 bits, that’s (1920\*1080\*8) 16.5 Mbits. The FPGA definitely
does not have enough block RAM for three frames of that. We could use the JPEG format on the camera
sensor to reduce this, but I don’t want to imagine the horror of getting that setup. We could also
do the JPEG encoding/decoding in the FPGA, but for some reason I didn’t want to do that (in
retrospect, it’s not a bad idea). This leaves the only available memory option as the DDR3 onboard
the DE10-Nano.

The idea of my framebuffer is to have three buffers being used in memory. Two buffers will always be
used for writing, and one for reading. The arbiter manages the buffers such that the one being read
from is never written into.

The memory controller allows a wide data width of 256 bits, so incoming pixels are packed up and
written into the first asynchronous FIFO. A pulse is driven and syncronized to the memory clock
domain telling the arbiter to start moving that line into the DDR3. Once a full frame is written,
the arbiter allows a downstream timer to read lines at the rate required for the output resolution.
The output pixels are unpacked and then sent downstream.

Accessing the DDR3 from the FPGA on the Cyclone V is a bit strange, and it was definitely a
challenge for me. At this point I had written all the RTL for the FPGA, and hadn’t even touched the
HPS. The only way to access the DDR3 through the FPGA is to get the HPS programmed and have it
enable the bridge from the hardened memory controller to the FPGA, so here we go.

If you want to use the HPS in your FPGA design, you need to instantiate it as a component in Qsys.
Qsys is comparable to Xilinx’s IP integrator for block designs. I didn’t want to take any chances,
so I modified the Qsys file given by the golden reference design by Terasic. The part of note when
creating the Qsys was enabling the fpga2sdram bridge. This gives the FPGA access to the memory
controller. I programmed the SDcard given with the DE10-Nano with Terasic’s known-good image for
DDR3 communication, and was ready to go.

| ![Image](/doc/qsys_axi.png) |
| :--: |
| *Qsys Instantiating the HPS* |

My first iteration of the framebuffer used the Avalon interface to talk to the SDRAM controller.
Avalon is much simpler compared to AXI: there are a lot less signals and it’s pretty easy to
implement. My main problem with it was that the memory controller would lock up if I tried to do
even small bursts, like a burst of 8. So my design could only request one transaction at a time.
This was fine because of the interface's wide bus width of up to 256 bits.

I now had a real-time camera stream going to my TV from the OV5640. After adding a weird
font-overlay controller in RTL, I made a backup of the project, and took a break. This was on
December 31st 2020. Unfortunately I never recorded a demo video of this stage of the project, since
I didn’t think much of it.

After taking a break for maybe a month, I decided to come back and make some upgrades. I rewrote the
framebuffer entirely, made it more modular, and converted the bus from Avalon to AXI. This means I
had to change the fpga2sdram bridge in the HPS from Avalon to AXI. I also added in memory addressing
options, to provide vertical and horizontal effects like splitscreen, flip, mirror, and scrolling.

## The Preloader and U-Boot

I came across a major problem with my upgraded framebuffer -- I couldn’t write to it! The SDRAM
controller was never responding to my ‘awvalid’ requests. With some research, I decided that the
problem was because I needed to update the preloader or update U-Boot for the HPS. Below are
conceptual designs for the most important hardware chunks of the fractal engine: the fractal slice,
and the fractal core. 

The Cyclone V has a pretty involved boot process. First it reads from an onboard ROM for boot
information, then it reads from the preloader within the SDcard, then it reads from U-Boot, which is
also in the SDcard. After that, it finally loads up Linux.

Apparently, if you make some drastic changes to the HPS in Qsys, you need to subsequently update the
preloader, whoops! I started reading documentation on building embedded linux for the Cyclone V, and
tutorials from Rocketboards on rebuilding the preloader. Nothing was working for me though. I
downgraded my Quartus and SoC EDS versions to match what was used for the reference design, and
tried a whole suite of things. All the tutorials I was looking at were using Linux to rebuild the
preloader, and I was working in Windows, so I chalked it up to that.

There is a single post on the Intel forums that is dealing with this issue, where the AXI writes
don’t respond. In that post they say to update the preloader or update U-Boot: so it was time to try
U-Boot.

| ![Image](/doc/forum_post.png) |
| :--: |
| *Intel Forum Post* |

After looking into how U-Boot works, I plugged in the USB cable from the DE10-Nano into my PC,
opened PuTTy as a serial port at 115200 / 8bits / no parity, and booted it up. I pressed a key to
stop the autoboot and typed in “printenv” to see the U-Boot setup. U-Boot uses a bunch of
environment variables stored in the SDcard to configure the HPS after the preloader. To my surprise,
this fpga2sdram_handoff variable seemed funky.

According to the Cyclone V manual, the AXI bridges require two ports (compared to Avalon bridges
requiring one port) of the SDRAM controller. The default U-Boot script was holding my AXI port in
reset!

| ![Image](/doc/uboot_printenv.png) |
| :--: |
| *U-Boot Environment Variable Snippet* |


| ![Image](/doc/held_in_reset.png) |
| :--: |
| *Cyclone V Holding My AXI Port Hostage!* |

I added a single line to my U-boot script and placed it on the SDcard. Done, my upgraded framebuffer
was working great.

| ![Image](/doc/fixed_uboot_script.png) |
| :--: |
| *Fixed U-Boot Script* |

## Image Processing Verification Tools

To make verification of my video processing blocks better, I designed some VHDL blocks to easily
facilitate passing image data through a testbench. I use a MATLAB script to convert RGB images from
any filetype into a flattened text file of integers. The image_reader block within the
pattern_generator block reads this text file and provides it as an AXI video stream. The pattern
generator can also give counting patterns, or two types of standard color bars. 

The image data is passed through the DUT and then sent into the image_writer block, producing
another text file. Outputs are given to stop the testbench when a certain number of images have been
written. I then have another script in MATLAB that converts the text file back to an image, and
plots it on the screen. It can then be visually inspected to verify RTL image processing.

The image_writer and image_reader blocks accomplish this by using std.textio library to read and
write files. The way I’m using the std.textio library here is not synthesizable. This is meant only
for simulation. However, you can synthesize with this library! But it’s only to initialize BRAM, it
only works in Vivado, and it only works if the text files are of the bit_vector type. I did this in
my 96-Note Spectrum Analyzer.

| ![Image](/doc/img_ver.png) |
| :--: |
| *Testbench with Image Verification Suite* |

| ![Image](/doc/macman.png) |
| :--: |
| *You can get some pretty funky outputs with a buggy FPGA design! This was created due to a FIFO
underflow while simulating my debayer block.* |

## Python Control via UART

An interesting idea I had for debugging my FPGA designs was to hook up a UART-USB converter and use
PySerial to send scripted reads/writes over a serial port. I picked up a converter from Digilent and
wrote some RTL for a UART driver. 

| ![Image](/doc/uart_pmod.png) |
| :--: |
| *Digilent's PMOD UART to USB* |

Writing the RTL for serial interfaces like I2C, SPI, and UART are easy enough. The major part that I
overlooked was how UART expects bits LSB first, but pretty quickly I could read and write a register
using Python code. I set up a basic communication structure with byte stuffing so that PySerial
could send packets, giving it 32-bit access to a 16-bit address space.

I then came up with a commenting format, which would be written inside the VHDL register file. The
comments would describe various register descriptions, bit fields, and address offsets. A different
Python script would parse through the register file, and auto-generate a suite of classes that could
be imported and used for easily accessing FPGA registers without having to remember address offsets
or bitfield locations.

| ![Image](/doc/example_register_desc.png) | ![Image](/doc/FPGA_def_class.png) | ![Image](/doc/REG_def_class.png) |
| :--: | :--: | :--: |
| Register File with Comments for Parsing | Generated FPGA Class | Generated Register Class |

