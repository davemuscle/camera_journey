# Back-end UART functions for connecting to UART core in FPGA
# Requires just two pins and a working COM port.

# Functions:
#    register_write(addr,data)
#    data = register_read(addr)

import serial
import time
import sys
import os
SerialPort = serial.Serial('COM3', baudrate=115200, bytesize=8, parity='N', stopbits=1,timeout=1)

flag_code   = 0x7E
escape_code = 0x7D
xor_code    = 0x20
write_code  = 0x37;
read_code   = 0x38;

# Python<->FPGA Messaging Format
# [Start]
# [Write or read code]
# [Addr Byte 1]
# [Addr Byte 0]
# [Data Byte 3]
# [Data Byte 2]
# [Data Byte 1]
# [Data Byte 0]

#Usage: pack_write(0x1234, 0x12345678)
#Returns stream of bytes to send over serial port to FPGA

def pack_serial(code, addr, data):

    addr_byte0 = addr       & 0xFF;
    addr_byte1 = addr >>  8 & 0xFF;
    data_byte0 = data       & 0xFF;
    data_byte1 = data >>  8 & 0xFF;
    data_byte2 = data >> 16 & 0xFF;
    data_byte3 = data >> 24 & 0xFF;
    
    frame_array = [flag_code]
    frame_data = [code, addr_byte1, addr_byte0, data_byte3, data_byte2, data_byte1, data_byte0]
    for chunk in frame_data:
        if(chunk == flag_code or chunk == escape_code):
            chunk = chunk ^ xor_code
            frame_array.append(escape_code)
        frame_array.append(chunk)
        
    return frame_array

def serial_frame_transmit(code, addr, data):
    frame = pack_serial(code, addr, data)
    #print("Transmit:")
    #for i in frame:
    #    print(hex(i))
    SerialPort.write(bytes(frame))
    
  
def unpack_serial(frame_array):
    code = frame_array[1]
    addr = (frame_array[2] <<  8) + (frame_array[3] <<  0)
    data = (frame_array[4] << 24) + \
           (frame_array[5] << 16) + \
           (frame_array[6] <<  8) + \
           (frame_array[7] <<  0)
                      
    ret_array = [code, addr, data]
    
    return ret_array
        
def serial_frame_return():

    start_detected = 0
    escape_detected = 0
    byte_count = 0
    frame_array = []
    #print("Receive:")
    while 1:

        rec = SerialPort.read()
        rec = int.from_bytes(rec, "big")
        #print(hex(rec))
        if(rec == flag_code):
            start_detected = 1
            byte_count = 0
            
        if(start_detected == 1):
            if(rec == escape_code):
                escape_detected = 1;
            else:
                if(escape_detected == 1):
                    rec = rec ^ xor_code
                    escape_detected = 0
                    frame_array.append(rec)
                    byte_count = byte_count + 1
                else:
                    frame_array.append(rec)
                    byte_count = byte_count + 1
        else:
            print("Disgusting Serial Read Error")
            return [0,0,0]
        if(byte_count == 8):
            #print("Read Done")
            return unpack_serial(frame_array)
    
def register_write(addr, data):

    serial_frame_transmit(write_code, addr, data)
    ret_array = serial_frame_return()
    
    fail = 0
    
    if(ret_array[0] != write_code):
        fail = 1
    if(ret_array[1] != addr):
        fail = 1
    if(ret_array[2] != data):
        fail = 1
    
    if(fail == 1):
        print("UART register write failed")
    
def register_read(addr):

    data = 0

    serial_frame_transmit(read_code, addr, data)
    ret_array = serial_frame_return()
    
    fail = 0
    
    if(ret_array[0] != read_code):
        fail = 1
    if(ret_array[1] != addr):
        fail = 1
        
    if(fail == 1):
        print("UART register read failed")

    return ret_array[2]
