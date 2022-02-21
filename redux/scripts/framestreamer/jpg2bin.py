import os
import sys
from PIL import Image
import numpy
from math import *

#user parameters
im = Image.open('wedding_full.jpg')

width  = im.size[0]
height = im.size[1]

#Array of RGB values now
dat = numpy.asarray(im)

fp=open("output.bin","wb")

pix = [0]*3
for i in range(0,height):
    for j in range(0, width):
        pix[0]=dat[i][j][2]
        pix[1]=dat[i][j][1]
        pix[2]=dat[i][j][0]
        
        out=pix[2]*(2**16) + pix[1]*(2**8) + pix[0];
        
        fp.write(out)


print("Done")