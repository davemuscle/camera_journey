import serial
import time
import sys
import UART

from gen_fpga import FPGA_def
FPGA=FPGA_def()
x=0
y=0
max=600
for i in range(0,max):
    x = x + FPGA.CameraFreqA.read()
    time.sleep(1)
    
for i in range(0,max):
    y = y + FPGA.CameraFreqB.read()
    time.sleep(1)
    
x = x / max
y = y / max

print("Camera Frequency A: "+str(int(x)))
print("Camera Frequency B: "+str(int(y)))
