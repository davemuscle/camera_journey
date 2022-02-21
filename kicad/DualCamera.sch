EESchema Schematic File Version 4
LIBS:DualCameraPlugIn-cache
EELAYER 29 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 2 3
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
U 1 1 6031593C
P 4900 2400
AR Path="/6031593C" Ref="U?"  Part="1" 
AR Path="/60302037/6031593C" Ref="U1"  Part="1" 
F 0 "U1" H 4900 3615 50  0000 C CNN
F 1 "DE10-Nano-GPIO1" H 4900 3524 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x20_P2.54mm_Vertical" H 4900 3600 50  0001 C CNN
F 3 "" H 4900 3600 50  0001 C CNN
	1    4900 2400
	1    0    0    -1  
$EndComp
$Comp
L Device:C C?
U 1 1 60315999
P 4975 6975
AR Path="/60315999" Ref="C?"  Part="1" 
AR Path="/60302037/60315999" Ref="C2"  Part="1" 
F 0 "C2" H 5025 7050 50  0000 L CNN
F 1 "0.1u" H 5025 6900 50  0000 L CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 5013 6825 50  0001 C CNN
F 3 "~" H 4975 6975 50  0001 C CNN
	1    4975 6975
	1    0    0    -1  
$EndComp
Wire Wire Line
	4700 6825 4975 6825
Wire Wire Line
	4700 7125 4975 7125
Text Notes 3950 925  0    50   ~ 0
Dual Camera Setup - GPIO1 on DE10 Nano
$Comp
L DualCameraPlugIn-rescue:Waveshare_OV5640_DVP-DualCameraPlugIn U?
U 1 1 603159EF
P 4975 5875
AR Path="/603159EF" Ref="U?"  Part="1" 
AR Path="/60302037/603159EF" Ref="U3"  Part="1" 
F 0 "U3" H 4975 5100 50  0000 C CNN
F 1 "Waveshare_OV5640_DVP" H 4975 5200 50  0000 C CNN
F 2 "DualCameraPlugIn:WaveshareOV5640" H 4975 6575 50  0001 C CNN
F 3 "" H 4975 6575 50  0001 C CNN
	1    4975 5875
	-1   0    0    -1  
$EndComp
$Comp
L DualCameraPlugIn-rescue:Waveshare_OV5640_DVP-DualCameraPlugIn U?
U 1 1 60315920
P 4975 4250
AR Path="/60315920" Ref="U?"  Part="1" 
AR Path="/60302037/60315920" Ref="U2"  Part="1" 
F 0 "U2" H 4975 3450 50  0000 C CNN
F 1 "Waveshare_OV5640_DVP" H 4975 3550 50  0000 C CNN
F 2 "DualCameraPlugIn:WaveshareOV5640" H 4975 4950 50  0001 C CNN
F 3 "" H 4975 4950 50  0001 C CNN
	1    4975 4250
	-1   0    0    -1  
$EndComp
Text Label 4450 2250 2    50   ~ 0
CAM1_A_SIOD
Text Label 4450 1450 2    50   ~ 0
CAM1_A_PWDN
Text Label 5350 2050 0    50   ~ 0
CAM1_A_PCLK
Text Label 4450 2050 2    50   ~ 0
CAM1_A_XCLK
Text Label 5350 1850 0    50   ~ 0
CAM1_A_D9
Text Label 5350 1750 0    50   ~ 0
CAM1_A_D7
Text Label 5350 1650 0    50   ~ 0
CAM1_A_D5
Text Label 5350 1550 0    50   ~ 0
CAM1_A_D3
Text Label 4450 1550 2    50   ~ 0
CAM1_A_D2
Text Label 4450 1650 2    50   ~ 0
CAM1_A_D4
Text Label 4450 1750 2    50   ~ 0
CAM1_A_D6
Text Label 4450 1850 2    50   ~ 0
CAM1_A_D8
Text Label 5350 2150 0    50   ~ 0
CAM1_A_VSYNC
Text Label 4450 2150 2    50   ~ 0
CAM1_A_HREF
Text Label 5350 3050 0    50   ~ 0
CAM1_B_D9
Text Label 5350 2950 0    50   ~ 0
CAM1_B_D7
Text Label 5350 2750 0    50   ~ 0
CAM1_B_D5
Text Label 5350 2650 0    50   ~ 0
CAM1_B_D3
Text Label 5350 3250 0    50   ~ 0
CAM1_B_VSYNC
Text Label 4450 2650 2    50   ~ 0
CAM1_B_D2
Text Label 4450 2750 2    50   ~ 0
CAM1_B_D4
Text Label 4450 2950 2    50   ~ 0
CAM1_B_D6
Text Label 4450 3050 2    50   ~ 0
CAM1_B_D8
Text Label 4450 3250 2    50   ~ 0
CAM1_B_HREF
Text Label 5350 3350 0    50   ~ 0
CAM1_B_SIOC
Text Label 5350 2550 0    50   ~ 0
CAM1_B_RESET
Text Label 5350 3150 0    50   ~ 0
CAM1_B_PCLK
Text Label 4450 3350 2    50   ~ 0
CAM1_B_SIOD
Text Label 4450 2550 2    50   ~ 0
CAM1_B_PWDN
Text Label 4450 3150 2    50   ~ 0
CAM1_B_XCLK
Text Label 4525 3750 2    50   ~ 0
CAM1_A_SIOC
Text Label 4525 3650 2    50   ~ 0
CAM1_A_SIOD
Text Label 4525 4150 2    50   ~ 0
CAM1_A_RESET
Text Label 4525 4250 2    50   ~ 0
CAM1_A_PWDN
Text Label 5375 3650 0    50   ~ 0
CAM1_A_D2
Text Label 5375 3850 0    50   ~ 0
CAM1_A_D4
Text Label 5375 4050 0    50   ~ 0
CAM1_A_D6
Text Label 5375 4250 0    50   ~ 0
CAM1_A_D8
Text Label 5375 4350 0    50   ~ 0
CAM1_A_D9
Text Label 5375 4150 0    50   ~ 0
CAM1_A_D7
Text Label 5375 3950 0    50   ~ 0
CAM1_A_D5
Text Label 5375 3750 0    50   ~ 0
CAM1_A_D3
Text Label 5375 4500 0    50   ~ 0
CAM1_A_XCLK
Text Label 5375 4600 0    50   ~ 0
CAM1_A_HREF
Text Label 5375 4700 0    50   ~ 0
CAM1_A_VSYNC
Text Label 5375 4800 0    50   ~ 0
CAM1_A_PCLK
Text Label 5375 5275 0    50   ~ 0
CAM1_B_D2
Text Label 5375 5475 0    50   ~ 0
CAM1_B_D4
Text Label 5375 5675 0    50   ~ 0
CAM1_B_D6
Text Label 5375 5875 0    50   ~ 0
CAM1_B_D8
Text Label 5375 5975 0    50   ~ 0
CAM1_B_D9
Text Label 5375 5775 0    50   ~ 0
CAM1_B_D7
Text Label 5375 5575 0    50   ~ 0
CAM1_B_D5
Text Label 5375 5375 0    50   ~ 0
CAM1_B_D3
Text Label 5375 6125 0    50   ~ 0
CAM1_B_XCLK
Text Label 5375 6225 0    50   ~ 0
CAM1_B_HREF
Text Label 5375 6325 0    50   ~ 0
CAM1_B_VSYNC
Text Label 5375 6425 0    50   ~ 0
CAM1_B_PCLK
Text Label 4525 5375 2    50   ~ 0
CAM1_B_SIOC
Text Label 4525 5275 2    50   ~ 0
CAM1_B_SIOD
Text Label 4525 5775 2    50   ~ 0
CAM1_B_RESET
Text Label 4525 5875 2    50   ~ 0
CAM1_B_PWDN
Text Label 5350 1450 0    50   ~ 0
CAM1_A_RESET
Text Label 5350 2250 0    50   ~ 0
CAM1_A_SIOC
$Comp
L Device:LED D1
U 1 1 608B3F78
P 6225 6800
F 0 "D1" V 6264 6683 50  0000 R CNN
F 1 "LED" V 6173 6683 50  0000 R CNN
F 2 "LED_SMD:LED_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 6225 6800 50  0001 C CNN
F 3 "~" H 6225 6800 50  0001 C CNN
	1    6225 6800
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R1
U 1 1 608B508E
P 6225 7100
F 0 "R1" H 6295 7146 50  0000 L CNN
F 1 "R" H 6295 7055 50  0000 L CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 6155 7100 50  0001 C CNN
F 3 "~" H 6225 7100 50  0001 C CNN
	1    6225 7100
	1    0    0    -1  
$EndComp
$Comp
L DualCameraPlugIn:3V3_CAM1-DualCameraPlugIn #PWR0102
U 1 1 6028C80A
P 4450 2850
F 0 "#PWR0102" H 4450 2700 50  0001 C CNN
F 1 "3V3_CAM1-DualCameraPlugIn" V 4465 2977 50  0000 L CNN
F 2 "" H 4450 2850 50  0001 C CNN
F 3 "" H 4450 2850 50  0001 C CNN
	1    4450 2850
	0    -1   -1   0   
$EndComp
$Comp
L DualCameraPlugIn:3V3_CAM1-DualCameraPlugIn #PWR0103
U 1 1 6028D5EA
P 4525 4800
F 0 "#PWR0103" H 4525 4650 50  0001 C CNN
F 1 "3V3_CAM1-DualCameraPlugIn" V 4540 4927 50  0000 L CNN
F 2 "" H 4525 4800 50  0001 C CNN
F 3 "" H 4525 4800 50  0001 C CNN
	1    4525 4800
	0    -1   -1   0   
$EndComp
$Comp
L DualCameraPlugIn:3V3_CAM1-DualCameraPlugIn #PWR0104
U 1 1 6028E424
P 4525 6425
F 0 "#PWR0104" H 4525 6275 50  0001 C CNN
F 1 "3V3_CAM1-DualCameraPlugIn" V 4540 6552 50  0000 L CNN
F 2 "" H 4525 6425 50  0001 C CNN
F 3 "" H 4525 6425 50  0001 C CNN
	1    4525 6425
	0    -1   -1   0   
$EndComp
$Comp
L Device:C C?
U 1 1 60315993
P 4700 6975
AR Path="/60315993" Ref="C?"  Part="1" 
AR Path="/60302037/60315993" Ref="C1"  Part="1" 
F 0 "C1" H 4725 7050 50  0000 L CNN
F 1 "0.1u" H 4725 6900 50  0000 L CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 4738 6825 50  0001 C CNN
F 3 "~" H 4700 6975 50  0001 C CNN
	1    4700 6975
	1    0    0    -1  
$EndComp
$Comp
L DualCameraPlugIn:3V3_CAM1-DualCameraPlugIn #PWR0105
U 1 1 6028FC61
P 4700 6825
F 0 "#PWR0105" H 4700 6675 50  0001 C CNN
F 1 "3V3_CAM1-DualCameraPlugIn" V 4715 6952 50  0000 L CNN
F 2 "" H 4700 6825 50  0001 C CNN
F 3 "" H 4700 6825 50  0001 C CNN
	1    4700 6825
	0    -1   -1   0   
$EndComp
$Comp
L DualCameraPlugIn:3V3_CAM1-DualCameraPlugIn #PWR0106
U 1 1 60290FCA
P 6225 6650
F 0 "#PWR0106" H 6225 6500 50  0001 C CNN
F 1 "3V3_CAM1-DualCameraPlugIn" V 6240 6777 50  0000 L CNN
F 2 "" H 6225 6650 50  0001 C CNN
F 3 "" H 6225 6650 50  0001 C CNN
	1    6225 6650
	1    0    0    -1  
$EndComp
$Comp
L DualCameraPlugIn:GND_CAM1-DualCameraPlugIn #PWR0108
U 1 1 6029AE4E
P 5350 1950
F 0 "#PWR0108" H 5350 1700 50  0001 C CNN
F 1 "GND_CAM1-DualCameraPlugIn" V 5350 1275 50  0000 C CNN
F 2 "" H 5350 1950 50  0001 C CNN
F 3 "" H 5350 1950 50  0001 C CNN
	1    5350 1950
	0    -1   -1   0   
$EndComp
$Comp
L DualCameraPlugIn:GND_CAM1-DualCameraPlugIn #PWR0109
U 1 1 6029B7CC
P 5350 2850
F 0 "#PWR0109" H 5350 2600 50  0001 C CNN
F 1 "GND_CAM1-DualCameraPlugIn" V 5350 2175 50  0000 C CNN
F 2 "" H 5350 2850 50  0001 C CNN
F 3 "" H 5350 2850 50  0001 C CNN
	1    5350 2850
	0    -1   -1   0   
$EndComp
$Comp
L DualCameraPlugIn:GND_CAM1-DualCameraPlugIn #PWR0110
U 1 1 602B8D19
P 4525 4700
F 0 "#PWR0110" H 4525 4450 50  0001 C CNN
F 1 "GND_CAM1-DualCameraPlugIn" V 4525 4025 50  0000 C CNN
F 2 "" H 4525 4700 50  0001 C CNN
F 3 "" H 4525 4700 50  0001 C CNN
	1    4525 4700
	0    1    1    0   
$EndComp
$Comp
L DualCameraPlugIn:GND_CAM1-DualCameraPlugIn #PWR0111
U 1 1 602B955E
P 4525 6325
F 0 "#PWR0111" H 4525 6075 50  0001 C CNN
F 1 "GND_CAM1-DualCameraPlugIn" V 4525 5650 50  0000 C CNN
F 2 "" H 4525 6325 50  0001 C CNN
F 3 "" H 4525 6325 50  0001 C CNN
	1    4525 6325
	0    1    1    0   
$EndComp
$Comp
L DualCameraPlugIn:GND_CAM1-DualCameraPlugIn #PWR0112
U 1 1 602B9DBA
P 4700 7125
F 0 "#PWR0112" H 4700 6875 50  0001 C CNN
F 1 "GND_CAM1-DualCameraPlugIn" V 4700 6450 50  0000 C CNN
F 2 "" H 4700 7125 50  0001 C CNN
F 3 "" H 4700 7125 50  0001 C CNN
	1    4700 7125
	0    1    1    0   
$EndComp
$Comp
L DualCameraPlugIn:GND_CAM1-DualCameraPlugIn #PWR0113
U 1 1 602BA4DB
P 6225 7250
F 0 "#PWR0113" H 6225 7000 50  0001 C CNN
F 1 "GND_CAM1-DualCameraPlugIn" V 6225 6575 50  0000 C CNN
F 2 "" H 6225 7250 50  0001 C CNN
F 3 "" H 6225 7250 50  0001 C CNN
	1    6225 7250
	0    1    1    0   
$EndComp
Connection ~ 4700 6825
Connection ~ 4700 7125
$EndSCHEMATC
