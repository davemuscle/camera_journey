import serial
import time
import sys
#import UART
#from UART import register_read
#from UART import register_write
    
from gen_fpga import FPGA_def

FPGA = FPGA_def()
    
delaytime=1
    
def CAM_DWRITE(addr,data):
    data1 = data >> 8;
    
    FPGA.CameraWrite.Address.write(addr)
    FPGA.CameraWrite.Data.write(data1)
    FPGA.CameraWrite.Enable.write(1)
    
    time.sleep(delaytime/1000)
    addr = addr + 1
    data2 = data & 0xFF

    FPGA.CameraWrite.Address.write(addr)
    FPGA.CameraWrite.Data.write(data2)
    FPGA.CameraWrite.Enable.write(1)
    
    
    time.sleep(delaytime/1000)
    
def CAM_WRITE(addr,data):
    FPGA.CameraWrite.Address.write(addr)
    FPGA.CameraWrite.Data.write(data)
    FPGA.CameraWrite.Enable.write(1)
    time.sleep(delaytime/1000)
    
def CAM_FIFO_WRITE(addr,data):
    FPGA.CameraWrite.Address.write(addr)
    FPGA.CameraWrite.Data.write(data)
    FPGA.CameraWrite.EnableFIFO.write(1)
    time.sleep(1/1000)

    
def CAM_READ(addr):
    FPGA.CameraRead.Address.write(addr)
    FPGA.CameraRead.Enable.write(1)
    time.sleep(delaytime/1000)
    x = FPGA.CameraRead.Data.read()
    time.sleep(1/1000)
    return x
    
def CAM_DREAD(addr):
    FPGA.CameraRead.Address.write(addr)
    FPGA.CameraRead.Enable.write(1)
    time.sleep(delaytime/1000)
    save1 = FPGA.CameraRead.Data.read()
    time.sleep(delaytime/1000)
    addr = addr + 1;
    FPGA.CameraRead.Address.write(addr)
    FPGA.CameraRead.Enable.write(1)
    time.sleep(delaytime/1000)
    save2 = FPGA.CameraRead.Data.read()
    time.sleep(delaytime/1000)
    save = (save1 << 8) + save2;
    return save
    
    
ov5640_config = (
[0x3008,0x82], # Software Reset
[0x3008,0x42], # Chip Power Down
[0x3103,0x03], # Sys Clk From PLL
[0x3017,0xff], # Data bits as outputs
[0x3018,0xff], # Data bits as outputs
[0x3503,0x02],
[0x350B,0xC4], # Gain Lower
[0x350A,0x03], # Gain Upper
[0x3034,0x1a], # [7:4] Charge Pump (always 1), [3:0] BIT Div (0x8 = 2, 0xA = 2.5)
[0x3035,0x11], # System Clocking[7:4] Sys Div, [3:0] MIPI Div (always 0x1)
[0x3036,0x69], # PLL Multiplier
[0x3037,0x13], # [7:4] PLL Root Bypass or Div2, [3:0] PLL Pre Div
[0x3108,0x01], # [7:4] PCLK Div, [3:0] SCLK Div
[0x3630,0x36], # Not Documented
[0x3631,0x0e], # Not Documented
[0x3632,0xe2], # Not Documented
[0x3633,0x12], # Not Documented
[0x3621,0xe0], # Not Documented
[0x3704,0xa0], # Not Documented
[0x3703,0x5a], # Not Documented
[0x3715,0x78], # Not Documented
[0x3717,0x01], # Not Documented
[0x370b,0x60], # Not Documented
[0x3705,0x1a], # Not Documented
[0x3905,0x02], # Not Documented
[0x3906,0x10], # Not Documented
[0x3901,0x0a], # Not Documented
[0x3731,0x12], # Not Documented
[0x3600,0x08], # VCM
[0x3601,0x33], # VCM
[0x302d,0x60], # Not documented
[0x3620,0x52], # Not documented
[0x371b,0x20], # Not documented
[0x471c,0x50], # Not documented
[0x3a13,0x43], # AEC These sure make the screen dark!
[0x3a18,0x00], # AEC These sure make the screen dark!
[0x3a19,0xf8], # AEC These sure make the screen dark!
[0x3635,0x13], # Not documented
[0x3636,0x03], # Not documented
[0x3634,0x40], # Not documented
[0x3622,0x01], # Not documented
[0x3c01,0x34], # 50/60 Hz Light Fix
[0x3c04,0x28], # 50/60 Hz Light Fix
[0x3c05,0x98], # 50/60 Hz Light Fix
[0x3c06,0x00], # 50/60 Hz Light Fix
[0x3c07,0x07], # 50/60 Hz Light Fix
[0x3c08,0x00], # 50/60 Hz Light Fix
[0x3c09,0x1c], # 50/60 Hz Light Fix
[0x3c0a,0x9c], # 50/60 Hz Light Fix
[0x3c0b,0x40], # 50/60 Hz Light Fix
[0x3820,0x42], # ISP Control, Flip
[0x3821,0x02], # ISP Control, Mirror, No binning
[0x3814,0x11], # Sample Increments
[0x3815,0x11], # Sample Increments
[0x3800,0x01],  # X START
[0x3801,0x50],  # X START
[0x3802,0x01],  # Y START
[0x3803,0xb2],  # Y START
[0x3804,0x08],  # X END
[0x3805,0xef],  # X END
[0x3806,0x05],  # Y END
[0x3807,0xf2],  # Y END
[0x3808,0x07],  # DVPHO = 1920
[0x3809,0x80],  # DVPHO = 1920
[0x380a,0x04],  # DVPVO = 1080
[0x380b,0x38],  # DVPVO = 1080
[0x380c,0x08],  # HTS,works = 2200
[0x380d,0x98],  # HTS,works = 2200
[0x380e,0x04],  # VTS,works = 1125
[0x380f,0x65],  # VTS,works = 1125
[0x3810,0x00],  # ISP X OFFSET
[0x3811,0x10],  # ISP X OFFSET
[0x3812,0x00],  # ISP Y OFFSET
[0x3813,0x04],  # ISP Y OFFSET
[0x3618,0x04], # Not documented
[0x3612,0x2b], # Not documented
[0x3708,0x64], # Not documented
[0x3709,0x12], # Not documented
[0x370c,0x00], # Not documented
[0x3a02,0x04], # AEC
[0x3a03,0x60], # AEC
[0x3a08,0x01], # AEC
[0x3a09,0x50], # AEC
[0x3a0a,0x01], # AEC
[0x3a0b,0x18], # AEC
[0x3a0e,0x03], # AEC
[0x3a0d,0x04], # AEC
[0x3a14,0x04], # AEC
[0x3a15,0x60], # AEC
[0x4001,0x02], # BLC
[0x4004,0x06], # BLC
[0x3000,0x00], # Functional Enables
[0x3001,0x00], # Functional Enables
[0x3002,0x00], # Functional Enables
[0x3004,0xff], # Clock Enables
[0x3005,0xff], # Clock Enables
[0x3006,0xff], # Clock Enables
[0x3007,0xff], # Clock Enables
[0x300e,0x58], # Enable DVP, power down MIPI
[0x302e,0x00], # Not documented
[0x4740,0x21], # Active High PCLK and active high HREF
[0x460b,0x35], # VFIFO
[0x460c,0x20], # VIFO [2] Control PCLK with register 0x3824
[0x3824,0x01], # DVP PCLK Divider (weird register)
[0x4300,0xF8], # Format Control (select RAW RG GB = 0x03)
[0x5001,0x01], # ISP Control [7] SDE, [5] Scale, [2] UV, [1] CME, [0] AWB
[0x501f,0x05], # Format Mux Control (0x05 = ISP RAW CIP)
[0x5000,0x03], # ISP Control [7] LENC, [5] GMA, [2] BLC, [1] WPC, [0] CIE
[0x3406,0x00], #Simple AWB
[0x5183,0x94], #Simple AWB
[0x5191,0xff], #Simple AWB
[0x5192,0x00], #Simple AWB
[0x5301,0x48], #CIP Sharpen MT Thresh2
[0x5302,0x18], #CIP Sharpen MT Offset1
[0x5303,0x0E], #CIP Sharpen MT Offset2
[0x5304,0x08], #CIP DNS Thresh1
[0x5305,0x48], #CIP DNS Thresh2
[0x5306,0x09], #CIP DNS Offset1
[0x5307,0x16], #CIP DNS Offset2
[0x5308,0x25], #CIP CTRL
[0x5309,0x08], #CIP Sharpen TH Thresh 1
[0x530a,0x48], #CIP Sharpen TH Thresh 2
[0x530b,0x04], #CIP Sharpen TH Offset 1
[0x530c,0x06], #CIP Sharpen TH Offset 2
[0x5480,0x01], # Gamma
[0x5481,0x08], # Gamma
[0x5482,0x14], # Gamma
[0x5483,0x28], # Gamma
[0x5484,0x51], # Gamma
[0x5485,0x65], # Gamma
[0x5486,0x71], # Gamma
[0x5487,0x7d], # Gamma
[0x5488,0x87], # Gamma
[0x5489,0x91], # Gamma
[0x548a,0x9a], # Gamma
[0x548b,0xaa], # Gamma
[0x548c,0xb8], # Gamma
[0x548d,0xcd], # Gamma
[0x548e,0xdd], # Gamma
[0x548f,0xea], # Gamma
[0x5490,0x1d], # Gamma
[0x5580,0x02], # Digital Effects
[0x5583,0x40], # Digital Effects
[0x5584,0x10], # Digital Effects
[0x5589,0x10], # Digital Effects
[0x558a,0x00], # Digital Effects
[0x558b,0xf8], # Digital Effects 
[0x5800,0x23], # LENC
[0x5801,0x14], # LENC
[0x5802,0x0f], # LENC
[0x5803,0x0f], # LENC
[0x5804,0x12], # LENC
[0x5805,0x26], # LENC
[0x5806,0x0c], # LENC
[0x5807,0x08], # LENC
[0x5808,0x05], # LENC
[0x5809,0x05], # LENC
[0x580a,0x08], # LENC
[0x580b,0x0d], # LENC
[0x580c,0x08], # LENC
[0x580d,0x03], # LENC
[0x580e,0x00], # LENC
[0x580f,0x00], # LENC
[0x5810,0x03], # LENC
[0x5811,0x09], # LENC
[0x5812,0x07], # LENC
[0x5813,0x03], # LENC
[0x5814,0x00], # LENC
[0x5815,0x01], # LENC
[0x5816,0x03], # LENC
[0x5817,0x08], # LENC
[0x5818,0x0d], # LENC
[0x5819,0x08], # LENC
[0x581a,0x05], # LENC
[0x581b,0x06], # LENC
[0x581c,0x08], # LENC
[0x581d,0x0e], # LENC
[0x581e,0x29], # LENC
[0x581f,0x17], # LENC
[0x5820,0x11], # LENC
[0x5821,0x11], # LENC
[0x5822,0x15], # LENC
[0x5823,0x28], # LENC
[0x5824,0x46], # LENC
[0x5825,0x26], # LENC
[0x5826,0x08], # LENC
[0x5827,0x26], # LENC
[0x5828,0x64], # LENC
[0x5829,0x26], # LENC
[0x582a,0x24], # LENC
[0x582b,0x22], # LENC
[0x582c,0x24], # LENC
[0x582d,0x24], # LENC
[0x582e,0x06], # LENC
[0x582f,0x22], # LENC
[0x5830,0x40], # LENC
[0x5831,0x42], # LENC
[0x5832,0x24], # LENC
[0x5833,0x26], # LENC
[0x5834,0x24], # LENC
[0x5835,0x22], # LENC
[0x5836,0x22], # LENC
[0x5837,0x26], # LENC
[0x5838,0x44], # LENC
[0x5839,0x24], # LENC
[0x583a,0x26], # LENC
[0x583b,0x28], # LENC
[0x583c,0x42], # LENC
[0x583d,0xce], # LENC
[0x5025,0x00], # Not documented
[0x3a0f,0x30], # AEC
[0x3a10,0x28], # AEC
[0x3a1b,0x30], # AEC
[0x3a1e,0x26], # AEC
[0x3a11,0x60], # AEC
[0x3a1f,0x14], # AEC
[0x4741,0x00], # --DVP Test Pattern Enable, 8 bit
[0x3008,0x02]  # Chip Power Up
)


def cam_init(listing):
    x = 0
    for i in listing:

        CAM_FIFO_WRITE(i[0],i[1])
        print("Wrote write command to FIFO: [" + str(hex(i[0])) + "] [" + str(hex(i[1])) + "]")
        time.sleep(1/1000)
        x = x + 1
    print(x)

    FPGA.CameraControl.InitSelect.write(1)
    FPGA.CameraControl.InitGo.write(1)
    time.sleep(100/1000)
    y = 0
    while 1:
        y = y + 1
        init_done = FPGA.CameraControl.InitDone.read()
        init_done = init_done & 1
        time.sleep(1000/1000)
        if(init_done == 1):
            break
        if(y == 50):
            print("No init done received")
            break
    print("Init Done")
       
    
#cam_init()
    
#cam_init()

