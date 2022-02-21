import serial
import time
import sys
import UART
from UART import register_read
from UART import register_write

import cam
from cam import cam_init
from cam import CAM_WRITE
from cam import CAM_READ
from cam import CAM_DWRITE
from cam import CAM_DREAD
from cam import CAM_FIFO_WRITE

#setup the base addresses for UART slaves
NUM_SLAVES = 2
VIRTUAL_PAGE_SIZE = 2**16 / NUM_SLAVES

cam_addr = 0*VIRTUAL_PAGE_SIZE
vid_addr = 1*VIRTUAL_PAGE_SIZE

