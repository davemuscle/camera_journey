EESchema Schematic File Version 4
LIBS:DualCameraPlugIn-cache
EELAYER 29 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 3 3
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L DualCameraPlugIn-rescue:DE10-Nano-GPIO1-DualCameraPlugIn U?
U 1 1 602D8BC2
P 2075 2825
AR Path="/602D8BC2" Ref="U?"  Part="1" 
AR Path="/60302037/602D8BC2" Ref="U?"  Part="1" 
AR Path="/60302416/602D8BC2" Ref="U7"  Part="1" 
F 0 "U7" H 2075 4040 50  0000 C CNN
F 1 "DE10-Nano-GPIO1" H 2075 3949 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x20_P2.54mm_Vertical" H 2075 4025 50  0001 C CNN
F 3 "" H 2075 4025 50  0001 C CNN
	1    2075 2825
	1    0    0    -1  
$EndComp
$Comp
L Device:C C?
U 1 1 602D8BC8
P 2150 7400
AR Path="/602D8BC8" Ref="C?"  Part="1" 
AR Path="/60302037/602D8BC8" Ref="C?"  Part="1" 
AR Path="/60302416/602D8BC8" Ref="C6"  Part="1" 
F 0 "C6" H 2200 7475 50  0000 L CNN
F 1 "0.1u" H 2200 7325 50  0000 L CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 2188 7250 50  0001 C CNN
F 3 "~" H 2150 7400 50  0001 C CNN
	1    2150 7400
	1    0    0    -1  
$EndComp
Wire Wire Line
	1875 7250 2150 7250
Wire Wire Line
	1875 7550 2150 7550
Text Notes 1425 1425 0    50   ~ 0
Dual Camera Setup - GPIO1 on DE10 Nano
$Comp
L DualCameraPlugIn-rescue:Waveshare_OV5640_DVP-DualCameraPlugIn U?
U 1 1 602D8BD1
P 2150 6300
AR Path="/602D8BD1" Ref="U?"  Part="1" 
AR Path="/60302037/602D8BD1" Ref="U?"  Part="1" 
AR Path="/60302416/602D8BD1" Ref="U9"  Part="1" 
F 0 "U9" H 2150 5525 50  0000 C CNN
F 1 "Waveshare_OV5640_DVP" H 2150 5625 50  0000 C CNN
F 2 "DualCameraPlugIn:WaveshareOV5640" H 2150 7000 50  0001 C CNN
F 3 "" H 2150 7000 50  0001 C CNN
	1    2150 6300
	-1   0    0    -1  
$EndComp
$Comp
L DualCameraPlugIn-rescue:DE10-Nano-GPIO0-DualCameraPlugIn U?
U 1 1 602D8BD7
P 5850 2850
AR Path="/602D8BD7" Ref="U?"  Part="1" 
AR Path="/60302037/602D8BD7" Ref="U?"  Part="1" 
AR Path="/60302416/602D8BD7" Ref="U10"  Part="1" 
F 0 "U10" H 5850 4065 50  0000 C CNN
F 1 "DE10-Nano-GPIO0" H 5850 3974 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x20_P2.54mm_Vertical" H 5850 4050 50  0001 C CNN
F 3 "" H 5850 4050 50  0001 C CNN
	1    5850 2850
	1    0    0    -1  
$EndComp
Text Notes 8075 1300 0    50   ~ 0
One board - Four Cameras
$Comp
L DualCameraPlugIn-rescue:Waveshare_OV5640_DVP-DualCameraPlugIn U?
U 1 1 602D8BDE
P 2150 4675
AR Path="/602D8BDE" Ref="U?"  Part="1" 
AR Path="/60302037/602D8BDE" Ref="U?"  Part="1" 
AR Path="/60302416/602D8BDE" Ref="U8"  Part="1" 
F 0 "U8" H 2150 3875 50  0000 C CNN
F 1 "Waveshare_OV5640_DVP" H 2150 3975 50  0000 C CNN
F 2 "DualCameraPlugIn:WaveshareOV5640" H 2150 5375 50  0001 C CNN
F 3 "" H 2150 5375 50  0001 C CNN
	1    2150 4675
	-1   0    0    -1  
$EndComp
Text Label 2525 2675 0    50   ~ 0
CAM1_A_SIOD
Text Label 1625 2475 2    50   ~ 0
CAM1_A_PCLK
Text Label 2525 2475 0    50   ~ 0
CAM1_A_XCLK
Text Label 1625 2275 2    50   ~ 0
CAM1_A_D9
Text Label 1625 2175 2    50   ~ 0
CAM1_A_D7
Text Label 1625 2075 2    50   ~ 0
CAM1_A_D5
Text Label 1625 1975 2    50   ~ 0
CAM1_A_D3
Text Label 2525 1975 0    50   ~ 0
CAM1_A_D2
Text Label 2525 2075 0    50   ~ 0
CAM1_A_D4
Text Label 2525 2175 0    50   ~ 0
CAM1_A_D6
Text Label 2525 2275 0    50   ~ 0
CAM1_A_D8
Text Label 1625 2575 2    50   ~ 0
CAM1_A_VSYNC
Text Label 2525 2575 0    50   ~ 0
CAM1_A_HREF
Text Label 2525 3475 0    50   ~ 0
CAM1_B_D9
Text Label 2525 3375 0    50   ~ 0
CAM1_B_D7
Text Label 2525 3175 0    50   ~ 0
CAM1_B_D5
Text Label 2525 3075 0    50   ~ 0
CAM1_B_D3
Text Label 2525 3675 0    50   ~ 0
CAM1_B_VSYNC
Text Label 1625 3075 2    50   ~ 0
CAM1_B_D2
Text Label 1625 3175 2    50   ~ 0
CAM1_B_D4
Text Label 1625 3375 2    50   ~ 0
CAM1_B_D6
Text Label 1625 3475 2    50   ~ 0
CAM1_B_D8
Text Label 1625 3675 2    50   ~ 0
CAM1_B_HREF
Text Label 2525 3775 0    50   ~ 0
CAM1_B_SIOC
Text Label 2525 2975 0    50   ~ 0
CAM1_B_RESET
Text Label 2525 3575 0    50   ~ 0
CAM1_B_PCLK
Text Label 1625 3775 2    50   ~ 0
CAM1_B_SIOD
Text Label 1625 2975 2    50   ~ 0
CAM1_B_PWDN
Text Label 1625 3575 2    50   ~ 0
CAM1_B_XCLK
Text Label 1700 4175 2    50   ~ 0
CAM1_A_SIOC
Text Label 1700 4075 2    50   ~ 0
CAM1_A_SIOD
Text Label 1700 4575 2    50   ~ 0
CAM1_A_RESET
Text Label 1700 4675 2    50   ~ 0
CAM1_A_PWDN
Text Label 2550 4075 0    50   ~ 0
CAM1_A_D2
Text Label 2550 4275 0    50   ~ 0
CAM1_A_D4
Text Label 2550 4475 0    50   ~ 0
CAM1_A_D6
Text Label 2550 4675 0    50   ~ 0
CAM1_A_D8
Text Label 2550 4775 0    50   ~ 0
CAM1_A_D9
Text Label 2550 4575 0    50   ~ 0
CAM1_A_D7
Text Label 2550 4375 0    50   ~ 0
CAM1_A_D5
Text Label 2550 4175 0    50   ~ 0
CAM1_A_D3
Text Label 2550 4925 0    50   ~ 0
CAM1_A_XCLK
Text Label 2550 5025 0    50   ~ 0
CAM1_A_HREF
Text Label 2550 5125 0    50   ~ 0
CAM1_A_VSYNC
Text Label 2550 5225 0    50   ~ 0
CAM1_A_PCLK
Text Label 2550 5700 0    50   ~ 0
CAM1_B_D2
Text Label 2550 5900 0    50   ~ 0
CAM1_B_D4
Text Label 2550 6100 0    50   ~ 0
CAM1_B_D6
Text Label 2550 6300 0    50   ~ 0
CAM1_B_D8
Text Label 2550 6400 0    50   ~ 0
CAM1_B_D9
Text Label 2550 6200 0    50   ~ 0
CAM1_B_D7
Text Label 2550 6000 0    50   ~ 0
CAM1_B_D5
Text Label 2550 5800 0    50   ~ 0
CAM1_B_D3
Text Label 2550 6550 0    50   ~ 0
CAM1_B_XCLK
Text Label 2550 6650 0    50   ~ 0
CAM1_B_HREF
Text Label 2550 6750 0    50   ~ 0
CAM1_B_VSYNC
Text Label 2550 6850 0    50   ~ 0
CAM1_B_PCLK
Text Label 1700 5800 2    50   ~ 0
CAM1_B_SIOC
Text Label 1700 5700 2    50   ~ 0
CAM1_B_SIOD
Text Label 1700 6200 2    50   ~ 0
CAM1_B_RESET
Text Label 1700 6300 2    50   ~ 0
CAM1_B_PWDN
Wire Wire Line
	5625 7300 5900 7300
$Comp
L Device:C C?
U 1 1 602D8C23
P 5900 7450
AR Path="/602D8C23" Ref="C?"  Part="1" 
AR Path="/60302037/602D8C23" Ref="C?"  Part="1" 
AR Path="/60302416/602D8C23" Ref="C8"  Part="1" 
F 0 "C8" H 5950 7525 50  0000 L CNN
F 1 "0.1u" H 5950 7375 50  0000 L CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 5938 7300 50  0001 C CNN
F 3 "~" H 5900 7450 50  0001 C CNN
	1    5900 7450
	1    0    0    -1  
$EndComp
Text Notes 5175 1325 0    50   ~ 0
Dual Camera Setup - GPIO0 on DE10 Nano
$Comp
L DualCameraPlugIn-rescue:Waveshare_OV5640_DVP-DualCameraPlugIn U?
U 1 1 602D8C2A
P 5925 6325
AR Path="/602D8C2A" Ref="U?"  Part="1" 
AR Path="/60302037/602D8C2A" Ref="U?"  Part="1" 
AR Path="/60302416/602D8C2A" Ref="U12"  Part="1" 
F 0 "U12" H 5925 5550 50  0000 C CNN
F 1 "Waveshare_OV5640_DVP" H 5925 5650 50  0000 C CNN
F 2 "DualCameraPlugIn:WaveshareOV5640" H 5925 7025 50  0001 C CNN
F 3 "" H 5925 7025 50  0001 C CNN
	1    5925 6325
	-1   0    0    -1  
$EndComp
$Comp
L DualCameraPlugIn-rescue:Waveshare_OV5640_DVP-DualCameraPlugIn U?
U 1 1 602D8C30
P 5925 4700
AR Path="/602D8C30" Ref="U?"  Part="1" 
AR Path="/60302037/602D8C30" Ref="U?"  Part="1" 
AR Path="/60302416/602D8C30" Ref="U11"  Part="1" 
F 0 "U11" H 5925 3900 50  0000 C CNN
F 1 "Waveshare_OV5640_DVP" H 5925 4000 50  0000 C CNN
F 2 "DualCameraPlugIn:WaveshareOV5640" H 5925 5400 50  0001 C CNN
F 3 "" H 5925 5400 50  0001 C CNN
	1    5925 4700
	-1   0    0    -1  
$EndComp
Text Label 5475 4200 2    50   ~ 0
CAM0_A_SIOC
Text Label 5475 4100 2    50   ~ 0
CAM0_A_SIOD
Text Label 5475 4600 2    50   ~ 0
CAM0_A_RESET
Text Label 5475 4700 2    50   ~ 0
CAM0_A_PWDN
Text Label 6325 4100 0    50   ~ 0
CAM0_A_D2
Text Label 6325 4300 0    50   ~ 0
CAM0_A_D4
Text Label 6325 4500 0    50   ~ 0
CAM0_A_D6
Text Label 6325 4700 0    50   ~ 0
CAM0_A_D8
Text Label 6325 4800 0    50   ~ 0
CAM0_A_D9
Text Label 6325 4600 0    50   ~ 0
CAM0_A_D7
Text Label 6325 4400 0    50   ~ 0
CAM0_A_D5
Text Label 6325 4200 0    50   ~ 0
CAM0_A_D3
Text Label 6325 4950 0    50   ~ 0
CAM0_A_XCLK
Text Label 6325 5050 0    50   ~ 0
CAM0_A_HREF
Text Label 6325 5150 0    50   ~ 0
CAM0_A_VSYNC
Text Label 6325 5250 0    50   ~ 0
CAM0_A_PCLK
Text Label 6325 5725 0    50   ~ 0
CAM0_B_D2
Text Label 6325 5925 0    50   ~ 0
CAM0_B_D4
Text Label 6325 6125 0    50   ~ 0
CAM0_B_D6
Text Label 6325 6325 0    50   ~ 0
CAM0_B_D8
Text Label 6325 6425 0    50   ~ 0
CAM0_B_D9
Text Label 6325 6225 0    50   ~ 0
CAM0_B_D7
Text Label 6325 6025 0    50   ~ 0
CAM0_B_D5
Text Label 6325 5825 0    50   ~ 0
CAM0_B_D3
Text Label 6325 6575 0    50   ~ 0
CAM0_B_XCLK
Text Label 6325 6675 0    50   ~ 0
CAM0_B_HREF
Text Label 6325 6775 0    50   ~ 0
CAM0_B_VSYNC
Text Label 6325 6875 0    50   ~ 0
CAM0_B_PCLK
Text Label 5475 5825 2    50   ~ 0
CAM0_B_SIOC
Text Label 5475 5725 2    50   ~ 0
CAM0_B_SIOD
Text Label 5475 6225 2    50   ~ 0
CAM0_B_RESET
Text Label 5475 6325 2    50   ~ 0
CAM0_B_PWDN
Text Label 1625 1875 2    50   ~ 0
CAM1_A_RESET
Text Label 1625 2675 2    50   ~ 0
CAM1_A_SIOC
Text Label 6300 3500 0    50   ~ 0
CAM0_B_D9
Text Label 6300 3400 0    50   ~ 0
CAM0_B_D7
Text Label 6300 3700 0    50   ~ 0
CAM0_B_VSYNC
Text Label 6300 3800 0    50   ~ 0
CAM0_B_SIOC
Text Label 6300 3600 0    50   ~ 0
CAM0_B_PCLK
Text Label 5400 3400 2    50   ~ 0
CAM0_B_D6
Text Label 5400 3500 2    50   ~ 0
CAM0_B_D8
Text Label 5400 3700 2    50   ~ 0
CAM0_B_HREF
Text Label 5400 3800 2    50   ~ 0
CAM0_B_SIOD
Text Label 5400 3600 2    50   ~ 0
CAM0_B_XCLK
Text Label 6300 2500 0    50   ~ 0
CAM0_A_PCLK
Text Label 6300 2300 0    50   ~ 0
CAM0_A_D9
Text Label 6300 2200 0    50   ~ 0
CAM0_A_D7
Text Label 6300 2600 0    50   ~ 0
CAM0_A_VSYNC
Text Label 6300 3200 0    50   ~ 0
CAM0_B_D5
Text Label 6300 3100 0    50   ~ 0
CAM0_B_D3
Text Label 6300 3000 0    50   ~ 0
CAM0_B_RESET
Text Label 6300 2700 0    50   ~ 0
CAM0_A_SIOC
Text Label 5400 2700 2    50   ~ 0
CAM0_A_SIOD
Text Label 5400 2500 2    50   ~ 0
CAM0_A_XCLK
Text Label 5400 2200 2    50   ~ 0
CAM0_A_D6
Text Label 5400 2300 2    50   ~ 0
CAM0_A_D8
Text Label 5400 2600 2    50   ~ 0
CAM0_A_HREF
Text Label 5400 3100 2    50   ~ 0
CAM0_B_D2
Text Label 5400 3200 2    50   ~ 0
CAM0_B_D4
Text Label 5400 3000 2    50   ~ 0
CAM0_B_PWDN
Text Label 6300 2100 0    50   ~ 0
CAM0_A_D5
Text Label 6300 2000 0    50   ~ 0
CAM0_A_D3
Text Label 6300 1900 0    50   ~ 0
CAM0_A_RESET
Text Label 5400 1900 2    50   ~ 0
CAM0_A_PWDN
Text Label 5400 2000 2    50   ~ 0
CAM0_A_D2
Text Label 5400 2100 2    50   ~ 0
CAM0_A_D4
$Comp
L Device:LED D?
U 1 1 602D8C78
P 3400 7225
AR Path="/60302037/602D8C78" Ref="D?"  Part="1" 
AR Path="/60302416/602D8C78" Ref="D3"  Part="1" 
F 0 "D3" V 3439 7108 50  0000 R CNN
F 1 "LED" V 3348 7108 50  0000 R CNN
F 2 "LED_SMD:LED_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 3400 7225 50  0001 C CNN
F 3 "~" H 3400 7225 50  0001 C CNN
	1    3400 7225
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R?
U 1 1 602D8C7E
P 3400 7525
AR Path="/60302037/602D8C7E" Ref="R?"  Part="1" 
AR Path="/60302416/602D8C7E" Ref="R3"  Part="1" 
F 0 "R3" H 3470 7571 50  0000 L CNN
F 1 "R" H 3470 7480 50  0000 L CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 3330 7525 50  0001 C CNN
F 3 "~" H 3400 7525 50  0001 C CNN
	1    3400 7525
	1    0    0    -1  
$EndComp
Wire Wire Line
	5625 7600 5900 7600
$Comp
L Device:C C?
U 1 1 602D8CA3
P 1875 7400
AR Path="/602D8CA3" Ref="C?"  Part="1" 
AR Path="/60302037/602D8CA3" Ref="C?"  Part="1" 
AR Path="/60302416/602D8CA3" Ref="C3"  Part="1" 
F 0 "C3" H 1900 7475 50  0000 L CNN
F 1 "0.1u" H 1900 7325 50  0000 L CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 1913 7250 50  0001 C CNN
F 3 "~" H 1875 7400 50  0001 C CNN
	1    1875 7400
	1    0    0    -1  
$EndComp
$Comp
L Device:C C?
U 1 1 602D8CB5
P 5625 7450
AR Path="/602D8CB5" Ref="C?"  Part="1" 
AR Path="/60302037/602D8CB5" Ref="C?"  Part="1" 
AR Path="/60302416/602D8CB5" Ref="C7"  Part="1" 
F 0 "C7" H 5650 7525 50  0000 L CNN
F 1 "0.1u" H 5650 7375 50  0000 L CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 5663 7300 50  0001 C CNN
F 3 "~" H 5625 7450 50  0001 C CNN
	1    5625 7450
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR02
U 1 1 602DAD56
P 1700 5125
F 0 "#PWR02" H 1700 4875 50  0001 C CNN
F 1 "GND" V 1705 4997 50  0000 R CNN
F 2 "" H 1700 5125 50  0001 C CNN
F 3 "" H 1700 5125 50  0001 C CNN
	1    1700 5125
	0    1    1    0   
$EndComp
$Comp
L power:GND #PWR08
U 1 1 602DBC34
P 2525 2375
F 0 "#PWR08" H 2525 2125 50  0001 C CNN
F 1 "GND" V 2530 2247 50  0000 R CNN
F 2 "" H 2525 2375 50  0001 C CNN
F 3 "" H 2525 2375 50  0001 C CNN
	1    2525 2375
	0    -1   -1   0   
$EndComp
$Comp
L power:GND #PWR09
U 1 1 602DD214
P 2525 3275
F 0 "#PWR09" H 2525 3025 50  0001 C CNN
F 1 "GND" V 2530 3147 50  0000 R CNN
F 2 "" H 2525 3275 50  0001 C CNN
F 3 "" H 2525 3275 50  0001 C CNN
	1    2525 3275
	0    -1   -1   0   
$EndComp
$Comp
L power:GND #PWR019
U 1 1 602DD640
P 6300 2400
F 0 "#PWR019" H 6300 2150 50  0001 C CNN
F 1 "GND" V 6305 2272 50  0000 R CNN
F 2 "" H 6300 2400 50  0001 C CNN
F 3 "" H 6300 2400 50  0001 C CNN
	1    6300 2400
	0    -1   -1   0   
$EndComp
$Comp
L power:GND #PWR020
U 1 1 602DD936
P 6300 3300
F 0 "#PWR020" H 6300 3050 50  0001 C CNN
F 1 "GND" V 6305 3172 50  0000 R CNN
F 2 "" H 6300 3300 50  0001 C CNN
F 3 "" H 6300 3300 50  0001 C CNN
	1    6300 3300
	0    -1   -1   0   
$EndComp
$Comp
L power:GND #PWR013
U 1 1 602DDD35
P 5475 5150
F 0 "#PWR013" H 5475 4900 50  0001 C CNN
F 1 "GND" V 5480 5022 50  0000 R CNN
F 2 "" H 5475 5150 50  0001 C CNN
F 3 "" H 5475 5150 50  0001 C CNN
	1    5475 5150
	0    1    1    0   
$EndComp
$Comp
L power:GND #PWR018
U 1 1 602DE9EA
P 5625 7600
F 0 "#PWR018" H 5625 7350 50  0001 C CNN
F 1 "GND" V 5630 7472 50  0000 R CNN
F 2 "" H 5625 7600 50  0001 C CNN
F 3 "" H 5625 7600 50  0001 C CNN
	1    5625 7600
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR011
U 1 1 602DF071
P 3400 7675
F 0 "#PWR011" H 3400 7425 50  0001 C CNN
F 1 "GND" V 3405 7547 50  0000 R CNN
F 2 "" H 3400 7675 50  0001 C CNN
F 3 "" H 3400 7675 50  0001 C CNN
	1    3400 7675
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR07
U 1 1 602DF2AB
P 1875 7550
F 0 "#PWR07" H 1875 7300 50  0001 C CNN
F 1 "GND" V 1880 7422 50  0000 R CNN
F 2 "" H 1875 7550 50  0001 C CNN
F 3 "" H 1875 7550 50  0001 C CNN
	1    1875 7550
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR04
U 1 1 602DF839
P 1700 6750
F 0 "#PWR04" H 1700 6500 50  0001 C CNN
F 1 "GND" V 1705 6622 50  0000 R CNN
F 2 "" H 1700 6750 50  0001 C CNN
F 3 "" H 1700 6750 50  0001 C CNN
	1    1700 6750
	0    1    1    0   
$EndComp
$Comp
L power:+3V3 #PWR03
U 1 1 602DF96A
P 1700 5225
F 0 "#PWR03" H 1700 5075 50  0001 C CNN
F 1 "+3V3" V 1715 5353 50  0000 L CNN
F 2 "" H 1700 5225 50  0001 C CNN
F 3 "" H 1700 5225 50  0001 C CNN
	1    1700 5225
	0    -1   -1   0   
$EndComp
$Comp
L power:+3V3 #PWR05
U 1 1 602E0FB3
P 1700 6850
F 0 "#PWR05" H 1700 6700 50  0001 C CNN
F 1 "+3V3" V 1715 6978 50  0000 L CNN
F 2 "" H 1700 6850 50  0001 C CNN
F 3 "" H 1700 6850 50  0001 C CNN
	1    1700 6850
	0    -1   -1   0   
$EndComp
$Comp
L power:+3V3 #PWR06
U 1 1 602E153C
P 1875 7250
F 0 "#PWR06" H 1875 7100 50  0001 C CNN
F 1 "+3V3" V 1890 7378 50  0000 L CNN
F 2 "" H 1875 7250 50  0001 C CNN
F 3 "" H 1875 7250 50  0001 C CNN
	1    1875 7250
	0    -1   -1   0   
$EndComp
$Comp
L power:+3V3 #PWR010
U 1 1 602E188E
P 3400 7075
F 0 "#PWR010" H 3400 6925 50  0001 C CNN
F 1 "+3V3" V 3415 7203 50  0000 L CNN
F 2 "" H 3400 7075 50  0001 C CNN
F 3 "" H 3400 7075 50  0001 C CNN
	1    3400 7075
	0    -1   -1   0   
$EndComp
$Comp
L power:+3V3 #PWR017
U 1 1 602E1E67
P 5625 7300
F 0 "#PWR017" H 5625 7150 50  0001 C CNN
F 1 "+3V3" V 5640 7428 50  0000 L CNN
F 2 "" H 5625 7300 50  0001 C CNN
F 3 "" H 5625 7300 50  0001 C CNN
	1    5625 7300
	0    -1   -1   0   
$EndComp
$Comp
L power:+3V3 #PWR016
U 1 1 602E223E
P 5475 6875
F 0 "#PWR016" H 5475 6725 50  0001 C CNN
F 1 "+3V3" V 5490 7003 50  0000 L CNN
F 2 "" H 5475 6875 50  0001 C CNN
F 3 "" H 5475 6875 50  0001 C CNN
	1    5475 6875
	0    -1   -1   0   
$EndComp
$Comp
L power:+3V3 #PWR014
U 1 1 602E23E3
P 5475 5250
F 0 "#PWR014" H 5475 5100 50  0001 C CNN
F 1 "+3V3" V 5490 5378 50  0000 L CNN
F 2 "" H 5475 5250 50  0001 C CNN
F 3 "" H 5475 5250 50  0001 C CNN
	1    5475 5250
	0    -1   -1   0   
$EndComp
$Comp
L power:+3V3 #PWR012
U 1 1 602E2732
P 5400 3300
F 0 "#PWR012" H 5400 3150 50  0001 C CNN
F 1 "+3V3" V 5415 3428 50  0000 L CNN
F 2 "" H 5400 3300 50  0001 C CNN
F 3 "" H 5400 3300 50  0001 C CNN
	1    5400 3300
	0    -1   -1   0   
$EndComp
$Comp
L power:+3V3 #PWR01
U 1 1 602E29B0
P 1625 3275
F 0 "#PWR01" H 1625 3125 50  0001 C CNN
F 1 "+3V3" V 1640 3403 50  0000 L CNN
F 2 "" H 1625 3275 50  0001 C CNN
F 3 "" H 1625 3275 50  0001 C CNN
	1    1625 3275
	0    -1   -1   0   
$EndComp
$Comp
L power:GND #PWR015
U 1 1 602E3BCD
P 5475 6775
F 0 "#PWR015" H 5475 6525 50  0001 C CNN
F 1 "GND" V 5480 6647 50  0000 R CNN
F 2 "" H 5475 6775 50  0001 C CNN
F 3 "" H 5475 6775 50  0001 C CNN
	1    5475 6775
	0    1    1    0   
$EndComp
Text Label 2525 2875 0    50   ~ 0
EX1
Text Label 1625 2875 2    50   ~ 0
EX2
Text Label 2525 2775 0    50   ~ 0
EX3
Text Label 1625 2775 2    50   ~ 0
EX4
Text Label 6300 2900 0    50   ~ 0
EX5
Text Label 5400 2900 2    50   ~ 0
EX6
Text Label 6300 2800 0    50   ~ 0
EX7
Text Label 5400 2800 2    50   ~ 0
EX8
$Comp
L power:+3V3 #PWR021
U 1 1 602EA853
P 8575 4350
F 0 "#PWR021" H 8575 4200 50  0001 C CNN
F 1 "+3V3" V 8590 4478 50  0000 L CNN
F 2 "" H 8575 4350 50  0001 C CNN
F 3 "" H 8575 4350 50  0001 C CNN
	1    8575 4350
	0    -1   -1   0   
$EndComp
$Comp
L power:+3V3 #PWR022
U 1 1 602EAC60
P 8575 4975
F 0 "#PWR022" H 8575 4825 50  0001 C CNN
F 1 "+3V3" V 8590 5103 50  0000 L CNN
F 2 "" H 8575 4975 50  0001 C CNN
F 3 "" H 8575 4975 50  0001 C CNN
	1    8575 4975
	0    -1   -1   0   
$EndComp
$Comp
L power:GND #PWR023
U 1 1 602EB11A
P 8575 4450
F 0 "#PWR023" H 8575 4200 50  0001 C CNN
F 1 "GND" V 8580 4322 50  0000 R CNN
F 2 "" H 8575 4450 50  0001 C CNN
F 3 "" H 8575 4450 50  0001 C CNN
	1    8575 4450
	0    1    1    0   
$EndComp
$Comp
L power:GND #PWR024
U 1 1 602EB5BA
P 8575 5075
F 0 "#PWR024" H 8575 4825 50  0001 C CNN
F 1 "GND" V 8580 4947 50  0000 R CNN
F 2 "" H 8575 5075 50  0001 C CNN
F 3 "" H 8575 5075 50  0001 C CNN
	1    8575 5075
	0    1    1    0   
$EndComp
Text Label 8575 5175 2    50   ~ 0
EX1
Text Label 8575 5275 2    50   ~ 0
EX2
Text Label 8575 5375 2    50   ~ 0
EX3
Text Label 8575 5475 2    50   ~ 0
EX4
Text Label 8575 4550 2    50   ~ 0
EX5
Text Label 8575 4650 2    50   ~ 0
EX6
Text Label 8575 4750 2    50   ~ 0
EX7
Text Label 8575 4850 2    50   ~ 0
EX8
Text Label 2525 1875 0    50   ~ 0
CAM1_A_PWDN
$Comp
L Connector_Generic:Conn_01x06 J1
U 1 1 60355FB8
P 8775 4550
F 0 "J1" H 8855 4542 50  0000 L CNN
F 1 "Conn_01x06" H 8855 4451 50  0000 L CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x06_P2.54mm_Vertical" H 8775 4550 50  0001 C CNN
F 3 "~" H 8775 4550 50  0001 C CNN
	1    8775 4550
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_01x06 J2
U 1 1 60359630
P 8775 5175
F 0 "J2" H 8855 5167 50  0000 L CNN
F 1 "Conn_01x06" H 8855 5076 50  0000 L CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x06_P2.54mm_Vertical" H 8775 5175 50  0001 C CNN
F 3 "~" H 8775 5175 50  0001 C CNN
	1    8775 5175
	1    0    0    -1  
$EndComp
$EndSCHEMATC
