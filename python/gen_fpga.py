#Dave Muscle, 4/3/21
#Auto-generated FPGA register classes

#from UART import register_write
#from UART import register_read 

def register_write(addr,data):
    return 1
    
def register_read(addr):
    return 1


def masked_write(addr, value, bits):      
	t = register_read(addr)                 
	bits_low = bits[0]                      
	bits_upp = bits[1]                      
	bits_diff = bits_upp - bits_low + 1     
	value       = value & (2**(bits_diff)-1)
	value_shift = value << bits_low         
	data_upp = t & ~(2**(bits_upp+1)-1)     
	data_low = t &  (2**(bits_low)-1)       
	data = data_upp + value_shift + data_low
	register_write(addr,data)               

def masked_read(addr,bits):          
	t = register_read(addr)            
	bits_low  = bits[0]                
	bits_upp  = bits[1]                
	bits_diff = bits_upp - bits_low + 1
	value = t >> bits_low              
	mask = 2**(bits_diff)-1            
	value = value & mask               
	return value                       

class CameraControl_InitGo_bits:
	def write(self,value):
		masked_write(0x0002,value,[0,1])
	def read(self):
		return(masked_read(0x0002,[0,1]))

class CameraControl_InitSelect_bits:
	def write(self,value):
		masked_write(0x0002,value,[2,3])
	def read(self):
		return(masked_read(0x0002,[2,3]))

class CameraControl_ForceID_bits:
	def write(self,value):
		masked_write(0x0002,value,[4,5])
	def read(self):
		return(masked_read(0x0002,[4,5]))

class CameraControl_EnableWrite_bits:
	def write(self,value):
		masked_write(0x0002,value,[6,7])
	def read(self):
		return(masked_read(0x0002,[6,7]))

class CameraControl_EnableWriteFIFO_bits:
	def write(self,value):
		masked_write(0x0002,value,[8,9])
	def read(self):
		return(masked_read(0x0002,[8,9]))

class CameraControl_EnableRead_bits:
	def write(self,value):
		masked_write(0x0002,value,[10,11])
	def read(self):
		return(masked_read(0x0002,[10,11]))

class CameraControl_InitDone_bits:
	def write(self,value):
		masked_write(0x0002,value,[12,13])
	def read(self):
		return(masked_read(0x0002,[12,13]))

class CameraControl_BootDone_bits:
	def write(self,value):
		masked_write(0x0002,value,[14,15])
	def read(self):
		return(masked_read(0x0002,[14,15]))

class CameraControl_CmdBusy_bits:
	def write(self,value):
		masked_write(0x0002,value,[16,17])
	def read(self):
		return(masked_read(0x0002,[16,17]))

class CameraControl_PwrUpDone_bits:
	def write(self,value):
		masked_write(0x0002,value,[18,19])
	def read(self):
		return(masked_read(0x0002,[18,19]))

class CameraData_DataWriteCameraA_bits:
	def write(self,value):
		masked_write(0x0003,value,[0,7])
	def read(self):
		return(masked_read(0x0003,[0,7]))

class CameraData_DataReadCameraA_bits:
	def write(self,value):
		masked_write(0x0003,value,[8,15])
	def read(self):
		return(masked_read(0x0003,[8,15]))

class CameraData_DataWriteCameraB_bits:
	def write(self,value):
		masked_write(0x0003,value,[16,23])
	def read(self):
		return(masked_read(0x0003,[16,23]))

class CameraData_DataReadCameraB_bits:
	def write(self,value):
		masked_write(0x0003,value,[24,31])
	def read(self):
		return(masked_read(0x0003,[24,31]))

class CameraAddress_AddressCameraA_bits:
	def write(self,value):
		masked_write(0x0004,value,[0,15])
	def read(self):
		return(masked_read(0x0004,[0,15]))

class VideoPipe_Reset_bits:
	def write(self,value):
		masked_write(0x0005,value,[0,0])
	def read(self):
		return(masked_read(0x0005,[0,0]))

class VideoPipe_CameraMux_bits:
	def write(self,value):
		masked_write(0x0005,value,[1,1])
	def read(self):
		return(masked_read(0x0005,[1,1]))

class VideoPipe_FrameBufferMux_bits:
	def write(self,value):
		masked_write(0x0005,value,[2,2])
	def read(self):
		return(masked_read(0x0005,[2,2]))

class VideoPipe_DemosaicMux_bits:
	def write(self,value):
		masked_write(0x0005,value,[3,3])
	def read(self):
		return(masked_read(0x0005,[3,3]))

class VideoPipe_DemosaicPattern_bits:
	def write(self,value):
		masked_write(0x0005,value,[4,5])
	def read(self):
		return(masked_read(0x0005,[4,5]))

class VideoPipe_DemosiacBypass_bits:
	def write(self,value):
		masked_write(0x0005,value,[6,6])
	def read(self):
		return(masked_read(0x0005,[6,6]))

class VideoPipe_CameraSelect_bits:
	def write(self,value):
		masked_write(0x0005,value,[7,7])
	def read(self):
		return(masked_read(0x0005,[7,7]))

class FrameBufferControl_UfifoOv_bits:
	def write(self,value):
		masked_write(0x0006,value,[0,0])
	def read(self):
		return(masked_read(0x0006,[0,0]))

class FrameBufferControl_UfifoUn_bits:
	def write(self,value):
		masked_write(0x0006,value,[1,1])
	def read(self):
		return(masked_read(0x0006,[1,1]))

class FrameBufferControl_DfifoOv_bits:
	def write(self,value):
		masked_write(0x0006,value,[2,2])
	def read(self):
		return(masked_read(0x0006,[2,2]))

class FrameBufferControl_DfifoUn_bits:
	def write(self,value):
		masked_write(0x0006,value,[3,3])
	def read(self):
		return(masked_read(0x0006,[3,3]))

class FrameBufferControl_LoadError_bits:
	def write(self,value):
		masked_write(0x0006,value,[4,4])
	def read(self):
		return(masked_read(0x0006,[4,4]))

class FrameBufferControl_RequestError_bits:
	def write(self,value):
		masked_write(0x0006,value,[5,5])
	def read(self):
		return(masked_read(0x0006,[5,5]))

class FrameBufferControl_TimeoutError_bits:
	def write(self,value):
		masked_write(0x0006,value,[6,6])
	def read(self):
		return(masked_read(0x0006,[6,6]))

class FrameBufferControl_FxLatch_bits:
	def write(self,value):
		masked_write(0x0006,value,[7,7])
	def read(self):
		return(masked_read(0x0006,[7,7]))

class FrameBufferControl_DatamoverReadTime_bits:
	def write(self,value):
		masked_write(0x0006,value,[8,19])
	def read(self):
		return(masked_read(0x0006,[8,19]))

class FrameBufferControl_DatamoverWriteTime_bits:
	def write(self,value):
		masked_write(0x0006,value,[20,31])
	def read(self):
		return(masked_read(0x0006,[20,31]))

class FrameBufferVert_Bypass_bits:
	def write(self,value):
		masked_write(0x0007,value,[0,0])
	def read(self):
		return(masked_read(0x0007,[0,0]))

class FrameBufferVert_SplitScreen_bits:
	def write(self,value):
		masked_write(0x0007,value,[1,1])
	def read(self):
		return(masked_read(0x0007,[1,1]))

class FrameBufferVert_SplitScreenType_bits:
	def write(self,value):
		masked_write(0x0007,value,[2,7])
	def read(self):
		return(masked_read(0x0007,[2,7]))

class FrameBufferVert_Flip_bits:
	def write(self,value):
		masked_write(0x0007,value,[8,8])
	def read(self):
		return(masked_read(0x0007,[8,8]))

class FrameBufferVert_Mirror_bits:
	def write(self,value):
		masked_write(0x0007,value,[9,9])
	def read(self):
		return(masked_read(0x0007,[9,9]))

class FrameBufferVert_Scroll_bits:
	def write(self,value):
		masked_write(0x0007,value,[10,10])
	def read(self):
		return(masked_read(0x0007,[10,10]))

class FrameBufferVert_ScrollOffset_bits:
	def write(self,value):
		masked_write(0x0007,value,[11,22])
	def read(self):
		return(masked_read(0x0007,[11,22]))

class FrameBufferHorz_Bypass_bits:
	def write(self,value):
		masked_write(0x0008,value,[0,0])
	def read(self):
		return(masked_read(0x0008,[0,0]))

class FrameBufferHorz_SplitScreen_bits:
	def write(self,value):
		masked_write(0x0008,value,[1,1])
	def read(self):
		return(masked_read(0x0008,[1,1]))

class FrameBufferHorz_SplitScreenType_bits:
	def write(self,value):
		masked_write(0x0008,value,[2,7])
	def read(self):
		return(masked_read(0x0008,[2,7]))

class FrameBufferHorz_Flip_bits:
	def write(self,value):
		masked_write(0x0008,value,[8,8])
	def read(self):
		return(masked_read(0x0008,[8,8]))

class FrameBufferHorz_Mirror_bits:
	def write(self,value):
		masked_write(0x0008,value,[9,9])
	def read(self):
		return(masked_read(0x0008,[9,9]))

class FrameBufferHorz_Scroll_bits:
	def write(self,value):
		masked_write(0x0008,value,[10,10])
	def read(self):
		return(masked_read(0x0008,[10,10]))

class FrameBufferHorz_ScrollOffset_bits:
	def write(self,value):
		masked_write(0x0008,value,[11,22])
	def read(self):
		return(masked_read(0x0008,[11,22]))

class ID_register:

	def write(self,value):
		register_write(0x0000,value)
	def read(self):
		return(register_read(0x0000))
	def help(self):
		print("\t[31:0]: FPGA_ID")
		print("\t\tRead only FPGA identification, always set to 0xDEADBEEF")

class Scratchpad_register:

	def write(self,value):
		register_write(0x0001,value)
	def read(self):
		return(register_read(0x0001))
	def help(self):
		print("\t[31:0]: Scratchpad")
		print("\t\tScratchpad data for testing reads and writes")

class CameraControl_register:

	InitGo=CameraControl_InitGo_bits()
	InitSelect=CameraControl_InitSelect_bits()
	ForceID=CameraControl_ForceID_bits()
	EnableWrite=CameraControl_EnableWrite_bits()
	EnableWriteFIFO=CameraControl_EnableWriteFIFO_bits()
	EnableRead=CameraControl_EnableRead_bits()
	InitDone=CameraControl_InitDone_bits()
	BootDone=CameraControl_BootDone_bits()
	CmdBusy=CameraControl_CmdBusy_bits()
	PwrUpDone=CameraControl_PwrUpDone_bits()
	def write(self,value):
		register_write(0x0002,value)
	def read(self):
		return(register_read(0x0002))
	def help(self):
		print("\t[1:0]: InitGo")
		print("\t\tAssert a rising edge to initalize the camera")
		print("\t\tCleared by the FPGA")
		print("\t\tLSB is for CameraA")
		print("\t\tMSB is for CameraB")
		print("\t[3:2]: InitSelect")
		print("\t\t0 to initialize camera from boot ROM")
		print("\t\t1 to initialize camera from FIFO")
		print("\t\tLSB is for CameraA")
		print("\t\tMSB is for CameraB")
		print("\t[5:4]: ForceID")
		print("\t\tAssert to force continually reading the device ID over I2C")
		print("\t\tLSB is for CameraA")
		print("\t\tMSB is for CameraB")
		print("\t[7:6]: EnableWrite")
		print("\t\tRising edge to assert a write command over SCCB interface")
		print("\t\tCleared by the FPGA")
		print("\t\tLSB is for CameraA")
		print("\t\tMSB is for CameraB")
		print("\t[9:8]: EnableWriteFIFO")
		print("\t\tRising edge to add the write command to FIFO init sequence")
		print("\t\tCleared by the FPGA")
		print("\t\tLSB is for CameraA")
		print("\t\tMSB is for CameraB")
		print("\t[11:10]: EnableRead")
		print("\t\tRising edge to assert read command over SCCB interface")
		print("\t\tCleared by the FPGA")
		print("\t\tLSB is for CameraA")
		print("\t\tMSB is for CameraB")
		print("\t[13:12]: InitDone")
		print("\t\tSet by the FPGA after the camera has been initialized")
		print("\t\tWrites have no effect")
		print("\t[15:14]: BootDone")
		print("\t\tSet by the FPGA shortly after a power up timer")
		print("\t\tWrites have no effect")
		print("\t[17:16]: CmdBusy")
		print("\t\tBit to show the camera state machine is processing a command")
		print("\t\tWrites have no effect")
		print("\t[19:18]: PwrUpDone")
		print("\t\tSet by the FPGA SCCB interface after the camera has been powered on")
		print("\t\tWrites have no effect")

class CameraData_register:

	DataWriteCameraA=CameraData_DataWriteCameraA_bits()
	DataReadCameraA=CameraData_DataReadCameraA_bits()
	DataWriteCameraB=CameraData_DataWriteCameraB_bits()
	DataReadCameraB=CameraData_DataReadCameraB_bits()
	def write(self,value):
		register_write(0x0003,value)
	def read(self):
		return(register_read(0x0003))
	def help(self):
		print("\t[7:0]: DataWriteCameraA")
		print("\t\tData sent to the OV5640 over the SCCB interface")
		print("\t[15:8]: DataReadCameraA")
		print("\t\tData sent from the OV5640 over the SCCB interface")
		print("\t[23:16]: DataWriteCameraB")
		print("\t\tData sent to the OV5640 over the SCCB interface")
		print("\t[31:24]: DataReadCameraB")
		print("\t\tData sent from the OV5640 over the SCCB interface")

class CameraAddress_register:

	AddressCameraA=CameraAddress_AddressCameraA_bits()
	def write(self,value):
		register_write(0x0004,value)
	def read(self):
		return(register_read(0x0004))
	def help(self):
		print("\t[15:0]: AddressCameraA")
		print("\t\tAddress sent to the OV5640 over the SCCB interface")
		print("\t[31:0]: AddressCameraB")
		print("\t\tAddress sent to the OV5640 over the SCCB interface")

class VideoPipe_register:

	Reset=VideoPipe_Reset_bits()
	CameraMux=VideoPipe_CameraMux_bits()
	FrameBufferMux=VideoPipe_FrameBufferMux_bits()
	DemosaicMux=VideoPipe_DemosaicMux_bits()
	DemosaicPattern=VideoPipe_DemosaicPattern_bits()
	DemosiacBypass=VideoPipe_DemosiacBypass_bits()
	CameraSelect=VideoPipe_CameraSelect_bits()
	def write(self,value):
		register_write(0x0005,value)
	def read(self):
		return(register_read(0x0005))
	def help(self):
		print("\t[0]: Reset")
		print("\t\tActive high reset for video components")
		print("\t[1]: CameraMux")
		print("\t\t0 - Send Camera Data into Framebuffer")
		print("\t\t1 - Send Test Pattern into Framebuffer")
		print("\t[2]: FrameBufferMux")
		print("\t\t0 - Send FrameBuffer Data into Demosaic")
		print("\t\t1 - Send Test Pattern into Demosaic")
		print("\t[3]: DemosaicMux")
		print("\t\t0 - Send Demosaic Data Downstream")
		print("\t\t1 - Send Test Pattern Downstream")
		print("\t[5:4]: DemosaicPattern")
		print("\t\tMode 0:        Mode 1:      Mode 2:      Mode 3:")
		print("\t\t|  B G . . |   | G B . . |  | G R . . |  | R G . . |")
		print("\t\t|  G R . . |   | R G . . |  | B G . . |  | G B . . |")
		print("\t[6]: DemosiacBypass")
		print("\t\tActive high to pass through the debayer buffering + math")
		print("\t[7]: CameraSelect")
		print("\t\t0 for CameraA")
		print("\t\t1 for CameraB")

class FrameBufferControl_register:

	UfifoOv=FrameBufferControl_UfifoOv_bits()
	UfifoUn=FrameBufferControl_UfifoUn_bits()
	DfifoOv=FrameBufferControl_DfifoOv_bits()
	DfifoUn=FrameBufferControl_DfifoUn_bits()
	LoadError=FrameBufferControl_LoadError_bits()
	RequestError=FrameBufferControl_RequestError_bits()
	TimeoutError=FrameBufferControl_TimeoutError_bits()
	FxLatch=FrameBufferControl_FxLatch_bits()
	DatamoverReadTime=FrameBufferControl_DatamoverReadTime_bits()
	DatamoverWriteTime=FrameBufferControl_DatamoverWriteTime_bits()
	def write(self,value):
		register_write(0x0006,value)
	def read(self):
		return(register_read(0x0006))
	def help(self):
		print("\t[0]: UfifoOv")
		print("\t\tUpstream Async FIFO Overflow Sticky Bit (1 = bad)")
		print("\t[1]: UfifoUn")
		print("\t\tUpstream Async FIFO Underflow Sticky Bit (1 = bad)")
		print("\t[2]: DfifoOv")
		print("\t\tDownstream Async FIFO Overflow Sticky Bit (1 = bad)")
		print("\t[3]: DfifoUn")
		print("\t\tDownstream Async FIFO Underflow Sticky Bit (1 = bad)")
		print("\t[4]: LoadError")
		print("\t\tArbiter Load Error Sticky Bit (1 = bad)")
		print("\t[5]: RequestError")
		print("\t\tArbiter Request Error Sticky Bit (1 = bad)")
		print("\t[6]: TimeoutError")
		print("\t\tArbiter Timeout Error Sticky Bit (1 = bad)")
		print("\t[7]: FxLatch")
		print("\t\tLatch in the parameters for the horizontal and vertical addressing modes")
		print("\t\tReads will return zeros")
		print("\t[19:8]: DatamoverReadTime")
		print("\t\tNumber of clocks it took the datamover to perform a line read")
		print("\t\tProne to metastability so take averages")
		print("\t[31:20]: DatamoverWriteTime")
		print("\t\tNumber of clocks it took the datamover to perform a line write")
		print("\t\tProne to metastability so take averages")

class FrameBufferVert_register:

	Bypass=FrameBufferVert_Bypass_bits()
	SplitScreen=FrameBufferVert_SplitScreen_bits()
	SplitScreenType=FrameBufferVert_SplitScreenType_bits()
	Flip=FrameBufferVert_Flip_bits()
	Mirror=FrameBufferVert_Mirror_bits()
	Scroll=FrameBufferVert_Scroll_bits()
	ScrollOffset=FrameBufferVert_ScrollOffset_bits()
	def write(self,value):
		register_write(0x0007,value)
	def read(self):
		return(register_read(0x0007))
	def help(self):
		print("\t[0]: Bypass")
		print("\t\tOverrides any vertical or horizontal addressing effects")
		print("\t[1]: SplitScreen")
		print("\t\tEnables splitscreen mode")
		print("\t[7:2]: SplitScreenType")
		print("\t\tSet to how many screens to split into minus 1")
		print("\t\tEg: 0 for 1 screen, 1 for 2 screens (max 64)")
		print("\t[8]: Flip")
		print("\t\tEnables flipped addressing")
		print("\t[9]: Mirror")
		print("\t\tEnables a mirror effect when in splitscreen mode")
		print("\t[10]: Scroll")
		print("\t\tEnables an addressing offset \"scroll\" effect")
		print("\t[22:11]: ScrollOffset")
		print("\t\tHow far to scroll in terms of lines (vertical) or pixels (horizontal)")

class FrameBufferHorz_register:

	Bypass=FrameBufferHorz_Bypass_bits()
	SplitScreen=FrameBufferHorz_SplitScreen_bits()
	SplitScreenType=FrameBufferHorz_SplitScreenType_bits()
	Flip=FrameBufferHorz_Flip_bits()
	Mirror=FrameBufferHorz_Mirror_bits()
	Scroll=FrameBufferHorz_Scroll_bits()
	ScrollOffset=FrameBufferHorz_ScrollOffset_bits()
	def write(self,value):
		register_write(0x0008,value)
	def read(self):
		return(register_read(0x0008))
	def help(self):
		print("\t[0]: Bypass")
		print("\t\tOverrides any vertical or horizontal addressing effects")
		print("\t[1]: SplitScreen")
		print("\t\tEnables splitscreen mode")
		print("\t[7:2]: SplitScreenType")
		print("\t\tSet to how many screens to split into minus 1")
		print("\t\tEg: 0 for 1 screen, 1 for 2 screens (max 64)")
		print("\t[8]: Flip")
		print("\t\tEnables flipped addressing")
		print("\t[9]: Mirror")
		print("\t\tEnables a mirror effect when in splitscreen mode")
		print("\t[10]: Scroll")
		print("\t\tEnables an addressing offset \"scroll\" effect")
		print("\t[22:11]: ScrollOffset")
		print("\t\tHow far to scroll in terms of lines (vertical) or pixels (horizontal)")

class CameraFreqA_register:

	def write(self,value):
		register_write(0x0009,value)
	def read(self):
		return(register_read(0x0009))
	def help(self):
		print("\t[31:0]: FreqA")
		print("\t\tCamera A PCLK Frequency")

class CameraFreqB_register:

	def write(self,value):
		register_write(0x000A,value)
	def read(self):
		return(register_read(0x000A))
	def help(self):
		print("\t[31:0]: FreqB")
		print("\t\tCamera B PCLK Frequency")

class FPGA_def:

	ID = ID_register()
	Scratchpad = Scratchpad_register()
	CameraControl = CameraControl_register()
	CameraData = CameraData_register()
	CameraAddress = CameraAddress_register()
	VideoPipe = VideoPipe_register()
	FrameBufferControl = FrameBufferControl_register()
	FrameBufferVert = FrameBufferVert_register()
	FrameBufferHorz = FrameBufferHorz_register()
	CameraFreqA = CameraFreqA_register()
	CameraFreqB = CameraFreqB_register()

	def help(self):
		print("\tAddr: 0x0000 | ID                 | RO | FPGA ID")
		print("\tAddr: 0x0001 | Scratchpad         | RW | Scratchpad")
		print("\tAddr: 0x0002 | CameraControl      | RW | Camera Control and Status")
		print("\tAddr: 0x0003 | CameraData         | RW | Camera Command Data")
		print("\tAddr: 0x0004 | CameraAddress      | RW | Camera Command Adderss")
		print("\tAddr: 0x0005 | VideoPipe          | RW | VideoPipe Control")
		print("\tAddr: 0x0006 | FrameBufferControl | RW | FrameBuffer Control and Status")
		print("\tAddr: 0x0007 | FrameBufferVert    | RW | FrameBuffer Vertical Fx")
		print("\tAddr: 0x0008 | FrameBufferHorz    | RW | FrameBuffer Horizontal Fx")
		print("\tAddr: 0x0009 | CameraFreqA        | RO | Camera A Pixel Clock Frequency")
		print("\tAddr: 0x000A | CameraFreqB        | RO | Camera B Pixel Clock Frequency")
