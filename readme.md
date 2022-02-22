# Camera Journey Nonrelease - FPGA
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

| Youtube Videos |
| :--: |
| *Camera Journey Nightmare* |
| [![Image](/doc/vid01_tb.png)](https://youtu.be/W62MrYm8ThQ) |

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
| *You can get some pretty funky outputs with a buggy FPGA design! This was created due to a FIFO underflow while simulating my debayer block.* |

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

Description | Image
:--: | :--: 
VHDL Register File with Comments for Parsing | ![Image](/doc/example_register_desc.png) 
Generated FPGA Class | ![Image](/doc/FPGA_def_class.png) 
Generated Register Class | ![Image](/doc/REG_def_class.png)
Using iPython | ![Image](/doc/open_ipython.png)
Help Command for the FPGA | ![Image](/doc/show_fpga_regs.png)
Help Command for the Registers | ![Image](/doc/show_help_regs.png)
iPython with tab auto-completion | ![Image](/doc/tab_completion.png)
Writing to all 32-bits of a register | ![Image](/doc/write_to_32.png)
Writing to a single bitfield of a register | ![Image](/doc/write_to_bitfield.png)

Was there a better way to do this? For sure. If I ever decide to use Python again for this, I’ll use
XML-type formatting in the RTL to standardize things instead of using my own format. Is this kind of
an abuse of the Python class construct? Ha, yeah!

## Twist Three: The Double Cameras
One of the main projects floating around online for the DE10-Nano is a “Real-time HDR Video”
project. It’s even packaged with the System-CD by Terasic. The idea involves feeding two camera
streams into the FPGA with differing exposure settings. The streams are then mixed together to give
a single feed but with a higher dynamic range. I decided I wanted to do something similar. Maybe use
two cameras to emulate our brain’s depth perception, or do some parallax effect.

I designed a PCB in KiCad to hold two cameras, sent it off, and had it back in a week or so. It’s a
really simple board that just plugs into one of the 2x20 headers on the DE10-Nano, and then two
Waveshare cameras plug into the PCB to give two streams. When I made the PCB, I also included a
design to hold four cameras, just in case I wanted to try and do something with 360 degree coverage.

![Image](/doc/camera_plugin_board.png) | ![Image](/doc/dualcams.jpg)
:--: | :--:
*Camera Board PCB* | *Dual Camera Board in Action*

The PCB worked fine, but the Waveshare camera modules definitely were not behaving the way I
expected. Two OV5460 camera modules with the same external input clocks, same I2C inputs, and same
register initializations do not behave the same way!

My first approach to fix this was using an asynchronous FIFO to match the rates, IE: if one camera
sent their start-of-frame 10 clocks early, then it was delayed and the proper CDC was applied to
make sure the streams lined up. The biggest problem with this was the skew between frames. Both
cameras need to be running at exactly the same FPS, and that just won’t happen. Eventually the skew
would cause the FIFO to overflow, and then it’s over. The reference project does some hack where
they lower the external clock rate of one camera for a short amount of time, but I don’t like that.

![Image](/doc/cam_skew.gif) | ![Image](/doc/awful_cam_noise.gif)
:--: | :--:
*Dual Camera Skew* | *Awful Camera Noise*

The best solution for me would be to upgrade the framebuffer to support multiple channels. So I did.
But then Qsys reported the HPS couldn’t support multiple AXI channels, so I’d need to either write
an interconnect or downgrade back to the Avalon bus. This annoyed me, so I started evaluating
options.

The quality of the camera streams wasn’t even good: they were filled with intensive raw pixel noise.
Even my work with just one of the camera modules suffered from this. I tried tons of register
configurations and couldn’t get the noise to go away. The OV5640 manual lists a maximum of 3.0V on
the digital IO, but Waveshare is driving them with 3.3V, maybe that’s it? The horrible Waveshare
board is also driving IO pins directly to 3.3V and GND (seriously, look that up), maybe that's it?
The DVP mode is a parallel video bus running at ~80 MHz, so there is probably extreme crosstalk
happening between the data bits, maybe that’s it? 

Either way, I wasn’t too excited about working more with these camera modules. It was time to move
on. At least I had got my demo to the point of being able to switch between camera streams. In the
GIF below you can see the parallax effect for a flash drive closely in front of both cameras. This
is the same thing as putting your thumb in front of your face, then alternating between which eye
you have open.

![Image](/doc/cam_switching.gif)
:--:
*Camera Parallax*

## Twist Four: The IP Camera

This DE10-Nano board has a few interesting peripherals connected only to the HPS: ethernet, USB-OTG,
and an accelerometer. So far, the entire project hasn’t touched these because I’ve stayed away from
the HPS. Not anymore, I’m diving right in!

The new idea was to buy an IP camera from Amazon, plug it into the ethernet port on the DE10-Nano,
and have a Linux image loaded onto the ARM CPU to pull from the camera. I could then use the FPGA to
apply video effects, then send it over the USB port to my PC as a UVC Webcam.

I bought a cheap camera, plugged it into my router, and logged into its HTML page. This was so
refreshing just being able to mouse around and change the camera settings, instead of sending
commands over an I2C bus! I made sure the camera wasn’t DOA by viewing the feed in Internet
Explorer.

![Image](/doc/cam_amazon.png)
:--:
*IP Security Camera*

After making sure the IP address was static, I connected the camera directly to the DE10-Nano and
started poking around in Linux. I wanted to see packets being sent that carried the video data, even
if I couldn’t view the frames. I used ifconfig and tcpdump to try and read packets. The main thing I
could see was the camera asking for a MAC address over ARP.

![Image](/doc/arp.png)
:--:
*Viewing Packets and ARP Requests*

Even after making sure the ARP was set up correctly, I could tell the camera wasn’t sending enough
data for a video stream. So there is some initialization that needs to happen here. I put the camera
back into the router, and used Wireshark on my main PC to see what was happening.

![Image](/doc/no_video_packets.png) | ![Image](/doc/video_packets.png)
:--: | :--:
*Slow Packets with No Video | RTSP Packets using UDP to Send Video*

I determined that I shouldn’t be thinking about this in such a low-level way. Eg: I don’t need to
manually construct the TCP packets to initialize this. There is already software to do it all. With
research, FFmpeg seemed like the way to go.

## H264 and FFMPEG

FFMPEG is a FOSS library for performing various video processing applications. Most specifically,
with the installation of libx264, it could read H.264 encoded video over an RTSP stream. This is
exactly what my camera is sending, so I started working on getting FFmpeg installed.

The Linux distribution that Terasic gives with the System-CD is Angstrom. I tried using ‘opkg’ to
install FFmpeg, but it wasn’t giving me anything usable. I also didn’t see an option for libx264. So
I decided to compile it from source.

I used GIT to pull both sets of source codes, and started running Makefiles. I followed some
instructions online and had to manually modify a few paths. Libx264 compiles pretty quickly, but
FFmpeg was taking a few hours. FFmpeg also failed about an hour due to memory constraints, so I
plugged in a 16GB flash drive, mounted it in Linux, and compiled it under there. Eventually I had a
usable FFmpeg binary.

**Editor's note 02/20/2022: Cross compiling here would have been a better choice**

![Image](/doc/from_source.jpg)
:--:
*Compiling FFmpeg with an SD card*

FFmpeg could now pull a single frame from the camera and convert it into JPG. I opened an SFTP
session within MobaXterm to view the image over windows by just double clicking it. Even if it’s out
of focus, it’s looking good! Much less painful than the OV5640. I also tested FFmpeg by converting a
view seconds of the stream into an MP4, and it worked decently well. It was a bit slow though.

![Image](/doc/running_ffmpeg_single.png)
:--:
*Capturing a Still with FFmpeg*

![Image](/doc/talking_to_china.png)
:--:
*Bonus: Security camera trying to send data back to China. Hope you enjoyed the bathrobe show.*

## Hardware Software Bridge

The next step was to get the IP camera feed to show up on my HDMI monitor/TV. This required
functional communication between the HPS and FPGA. I quickly converted my framebuffer into a
framestreamer, which would only read from the DDR3 and let the HPS fill the memory with what should
be shown on the screen. I also added some AXI ports in the Qsys to allow the HPS to control the
framestreamer parameters like the frame offsets, which frame number is active, and the resolution of
the frame. These AXI ports would connect the FPGA to the HPS via the “lighweight AXI bridge”, which
was viewable in the device tree.

![Image](/doc/FPGA_IPcam.png)
:--:
*Simpler FPGA Design to Leverage SW*

It was quite a breath of fresh air writing C code for this. I memory mapped the lightweight bridge,
and three portions of memory in DDR3 for the three triple-buffered frames. My first check was to
fill that image-space and make sure it would show up on the screen. On my Windows PC I converted a
JPG image to a binary file, then used C code on the DE10-Nano to write the binary file into DDR3
memory. The output is below.

![Image](/doc/copy_buffer_c_code.png)
:--:
*C code snippet to copy the binary file into shared SDRAM*

![Image](/doc/wedding.jpg)
:--:
*HW SW Bridge in Action: Software Sets Up the Image, Hardware Displays it*

## Journey's End

Things fell apart when I wanted to see the real-time security camera video on the monitor. The ARM
CPU was just not keeping up with the requirements to read the RTSP packets, decode the H264 stream,
and convert it to raw RGB video. I checked the CPU usage with “htop”, and both were at 100%. The
FPGA also wasn’t helping, because it has to take priority over the memory controller to read the
frames at a constant rate. Since the memory controller arbitrates access to the FPGA and HPS, there
is some slowdown here. Even with a lower resolution I couldn't get a good output.

I had hit the limit, and was out of ideas. This camera was definitely not right for the project
goals (if there ever were any), and I had enough with the twists and turns, so I called it quits.
The video shown at the top and on the front page was the farthest I got with this camera. There were
definitely still improvements needed to the C code and FPGA design.

I take a lot of pride in having the grit to push through issues and never giving up, but the idea of
moving on and doing something new is too exciting. So this marked the end of the camera journey.

![Image](/doc/ip_setup.jpg) | ![Image](/doc/wave.gif)
:--: | :--:
*IP Camera Setup to DE10-Nano Embedded Linux* | *Glitchy, High Latency, ~1FPS IP Camera Output*


## In Retrospect

Here are various things that I got some exposure to, designed, or enjoyed doing:
- Serial interfaces like UART and I2C 
- Debayer RTL block
- Framebuffer RTL block
- Asynchronous FIFOs, handshake-based pulse synchronizers, CDC with >2 clock domains
- Video verification techniques, testbench improvements
- Python generated classes for FPGA control
- Quartus flow (even if it was just clicking in the GUI)
- Quartus Qsys Design, using Altera IP (PLLs)
- U-Boot
- Embedded Linux
- Basic Networking (I'm still a baby - but this was good to learn)
- Real C-code (memory mapping, malloc, free)

Here are some of the ideas I had that didn't pan out, or that I didn't get to:
- Ray-tracing
- Face Detection via Viola Jones (did a lot of MATLAB studying on this, but struggled with it. Neural network next time)
- Real-time Video Fx in RTL
- Stereoscopics

Here are some of the things I didn't like:
- Altera/Intel Documentation, lack of active forum compared to Xilinx
- Cyclone V preloader issues

**Editor's Note, 02/20/2022: Looks like Xilinx forums are going in a similar direction?**

## Downloads
- [OV5640 Init Sequence for 1080p DVP Mode](/doc/ov5640_init.txt)
- [ADV7513 Init Sequence for DE10-Nano at 24-bit RGB 1080](/doc/adv7513_init.txt)

## References
1. [Terasic, DE10-Nano Kit Downloads](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=1046&PartNo=4)
2. [Analog Devices, ADV7513 Programming Guide](https://www.analog.com/media/en/technical-documentation/user-guides/ADV7513_Programming_Guide.pdf)
3. [Waveshare (hooligans), OV5640 Board](https://www.waveshare.com/wiki/OV5640_Camera_Board_(B))
4. [Sparkfun, OV5640 Manual](https://cdn.sparkfun.com/datasheets/Sensors/LightImaging/OV5640_datasheet.pdf)
5. [Xenpac/sun4csi, Great OV5640 Driver](https://github.com/xenpac/sun4i_csi/blob/master/device/ov5640.c)
6. [Standford, High-Quality Linear Interpolation For Demosaicing of Bayer-Patterned Color Images](https://stanford.edu/class/ee367/reading/Demosaicing_ICASSP04.pdf)
7. [Altera, Avalon Bus Spec](http://www1.cs.columbia.edu/~sedwards/classes/2011/4840/mnl_avalon_spec.pdf)
8. [ARM, AXI Bus Spec](http://www.gstitt.ece.ufl.edu/courses/fall15/eel4720_5721/labs/refs/AXI4_specification.pdf)
9. [Intel Forum, How can I enable the FPGA2SDRAM bridge on Cyclone V SOC devices?](https://www.intel.com/content/www/us/en/support/programmable/articles/000086918.html)
10. [Criticallink.com, Important Note about FPGA/HPS SDRAM Bridge](https://support.criticallink.com/redmine/projects/mityarm-5cs/wiki/Important_Note_about_FPGAHPS_SDRAM_Bridge)
11. [Oguz Meteer, Building embedded Linux for the Terasic DE10-Nano](https://bitlog.it/20170820_building_embedded_linux_for_the_terasic_de10-nano.html)
12. [Altera, Cyclone V HPS TRM](https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/hb/cyclone-v/cv_54001.pdf)
13. [Wimsworld, New FFMPEG install on BeagleBone Black](https://wimsworld.wordpress.com/2013/06/26/new-ffmpeg-install-on-beaglebone-black/)
14. [Batchloaf, A simple way to read and write audio and video files in C using FFmpeg](https://batchloaf.wordpress.com/2017/02/12/a-simple-way-to-read-and-write-audio-and-video-files-in-c-using-ffmpeg-part-2-video/)
