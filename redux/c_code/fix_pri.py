#!/usr/bin/python

import os
import sys

#Priortiy, Staic Weight, Sum of Weights
#Col0 - max of 3 bits
#Col1 - max of 5 bits
#Col2 - max of 8 bits

vals=[0]*10
vals[0]=(7,10,10)
vals[1]=(7,10, 0)
vals[2]=(0, 0, 0)
vals[3]=(0, 0, 0)
vals[4]=(0, 0, 0)
vals[5]=(0, 0, 0)
vals[6]=(0, 1, 0)
vals[7]=(0, 4,20)
vals[8]=(0, 1, 0)
vals[9]=(0, 4, 0)

pri_reg=0
for i in range(0,10):
  #Shift by 0, then by 3, then by 6
  pri_reg=pri_reg+vals[i][0]*(2**(i*3))

wei_reg=0
for i in range(0,10):
  #Shift by 0, then by 5, then by 10
  wei_reg=wei_reg+vals[i][1]*(2**(i*5))

sum_reg=0
for i in range(0,8):
  #Shift by 0, then by 8, then by 16
  sum_reg=sum_reg+vals[i][2]*(2**(i*8))

wei_reg1=wei_reg & 0xFFFFFFFF;
wei_reg2=wei_reg / (2**32);

reg0=pri_reg
reg1=wei_reg & 0xFFFFFFFF

slice0=(wei_reg/(2**32)) & 0x3FFFF
slice1=sum_reg & 0x3FFF
reg2=slice1*(2**18) + slice0
reg3=sum_reg / (2**14) & 0xFFFFFFFF
reg4=sum_reg / (2**(14+32)) & 0xFFFFFFFF

print("Full Regs:")
print(str(hex(pri_reg)))
print(str(hex(wei_reg)))
print(str(hex(sum_reg)))
print("\n")

print("Sliced Regs:")
#print(str(hex(reg0)))
#print(str(hex(reg1)))
#print(str(hex(reg2)))
#print(str(hex(reg3)))
#print(str(hex(reg4)))

x0=format(reg0,"08x")
x1=format(reg1,"08x")
x2=format(reg2,"08x")
x3=format(reg3,"08x")
x4=format(reg4,"08x")

print(x0)
print(x1)
print(x2)
print(x3)
print(x4)
print("")
cmd0="devmem 0xFFC250AC 32 0x"+x0
cmd1="devmem 0xFFC250B0 32 0x"+x1
cmd2="devmem 0xFFC250B4 32 0x"+x2
cmd3="devmem 0xFFC250B8 32 0x"+x3
cmd4="devmem 0xFFC250BC 32 0x"+x4
cmd5="devmem 0xFFC2505C 32 0x00000006"

print("Formatted commands:")
print(cmd0)
print(cmd1)
print(cmd2)
print(cmd3)
print(cmd4)
print(cmd5)

print("\nRunning Commands:")
os.system(cmd0)
os.system(cmd1)
os.system(cmd2)
os.system(cmd3)
os.system(cmd4)
os.system(cmd5)
print("Done")
