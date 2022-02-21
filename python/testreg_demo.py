import getch
from time import sleep


def FPGA_read(addr):
    print("UART Register Read " + str(hex(addr)))
    #return 0x37373737
    #return 0xFFFFFFFF
    return 0x00000000
    
def FPGA_write(addr,data):
    print("UART Register Write " + str(hex(addr)) + " : " + str(hex(data)))

def masked_write(addr, value, bits):
    t = FPGA_read(addr)
    
    bits_low = bits[0]
    bits_upp = bits[1]
    bits_diff = bits_upp - bits_low + 1
    
    value       = value & (2**(bits_diff)-1)
    value_shift = value << bits_low
    
    data_upp = t & ~(2**(bits_upp+1)-1)
    data_low = t &  (2**(bits_low)-1)

    data = data_upp + value_shift + data_low

    FPGA_write(addr,data)

def masked_read(addr,bits):
    
    t = FPGA_read(addr)
    
    bits_low  = bits[0]
    bits_upp  = bits[1]
    bits_diff = bits_upp - bits_low + 1
    
    value = t >> bits_low
    mask = 2**(bits_diff)-1
    value = value & mask
    
    return value

class Bit():
    
    def write(self,value):
        print("UART bit write")
    def read(self):
        print("UART bit read")
    

class Register():

    def write(self,value):
        print("UART reg write")
    
    def testread(self):
        print("UART reg read")
   
    reset = Bit()
    
class FPGA_def:

    cam = Register()
    
    
#FPGA = FPGA_def()

#print("Enter character:")
#char = getch.getch()
#print("Hey")
#print(char)

#while True:
#    char = getch.getch()
#    if(char == "1"):
#        print("Hey")
#        break
#    sleep(1)

#FPGA.mama.all = 1
#FPGA.mama.papa = 1
#x = FPGA.mama.all
#y = FPGA.mama.papa
#FPGA.mama.all = 1
#FPGA.mama.papa = 1
#x = FPGA.mama.all
#y = FPGA.mama.papa
