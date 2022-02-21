import serial
import time
import sys
import UART
from UART import register_read
from UART import register_write

def main():
    
    # while(1):
        # register_write(0x0001, 0x01)
        # time.sleep(1/10)
        # register_write(0x0000, 0x02)
        # time.sleep(1/10)
        # register_write(0x0000, 0x04)
        # time.sleep(1/10)
        # register_write(0x0000, 0x08)
        # time.sleep(1/10)
        # register_write(0x0000, 0x10)
        # time.sleep(1/10)
        # register_write(0x0000, 0x20)
        # time.sleep(1/10)
        # register_write(0x0000, 0x40)
        # time.sleep(1/10)
        # register_write(0x0000, 0x80)
        # time.sleep(1/10)
        
# Scratchpad:
    register_read(0x8000)
    register_read(0x8001)
    register_read(0x8002)
    register_read(0x8003)
        
    register_write(0x8000,0x1)
    register_write(0x8001,0x2)
    register_write(0x8002,0x3)
    register_write(0x8003,0x4)
        
    register_read(0x8000)
    register_read(0x8001)
    register_read(0x8002)
    register_read(0x8003)      
   
    register_read(0x0000)
    register_read(0x0001)
    register_read(0x0002)
    register_read(0x0003) 
    
    register_read(0x8004)
    register_read(0x0004)
    
    register_write(0x0000, 0x01)
    
   
        

main()