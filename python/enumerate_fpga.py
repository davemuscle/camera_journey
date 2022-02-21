import os
import sys
import getopt
import re

REG_PARSE_STR_KEY = "@REG@"
REG_PARSE_DNE_KEY = "@DNE@"

args, vals = getopt.getopt(sys.argv[1:],"i:o:")

ifilepath = ""
ofilepath = ""

for arg,val in args:
    if(arg == "-i"):
        ifilepath = val
    elif(arg == "-o"):
        ofilepath = val

#Register Hash Key Structure:
#Address -> Designator (optional), Register Name, 
#           Bitfield Names, BitField Positons, BitField Descriptions (all arrays)
class register_class:
    designator         = ""
    name               = ""
    access             = ""
    bitfields          = [""]
    bitpositions_upper = [0]
    bitpositions_lower = [0]
    bitdescriptions    = [""]
    
regmap={}

fr = open(ifilepath, "r")

lines = fr.readlines()

#Filter only for comments, strip left and right whitespace
lines_temp = []
for line in lines:
    r = re.search("--",line)
    if(r):
        line = line.strip()
        line = line + "\r\n"
        line = line.replace("--","")
        lines_temp.append(line)
    else:
        continue
lines = lines_temp
print("--------------------------------------------------------")
print("--------------------------------------------------------")
print("--------------------------------------------------------")
#Filter between the start keys and the done keys
active = 0
type = 1
lines_temp = []
lines_num = []
for line in lines:
    #Default to assuming the line is a bitfield position
    type = 2
        
    #Check if the line matches with the start of a register description
    r = re.search(REG_PARSE_STR_KEY,line)
    if(r):
        print("Found register: " + line.rstrip())
        active = 1
        type = 0
        
    r = re.search(REG_PARSE_DNE_KEY,line)
    if(r):
        print("Found done")
        active = 0
        type = 3

        
    r = re.search("\@\[.*\]",line)
    if(r):
        print("Found Bitfield")
        type = 1
        
    if(active == 1):
        print("Appending line: " + line.rstrip())
        lines_temp.append(line)
        lines_num.append(type)
    elif(active == 0 and type == 3):
        print("Inserting dummy done marker")
        lines_temp.append("")
        lines_num.append(type)
    else:
        print("Removing line: " + line.rstrip())
    
lines = lines_temp;

print("--------------------------------------------------------")
print("--------------------------------------------------------")
print("--------------------------------------------------------")
for i in range(0, len(lines)):
    print(str(lines_num[i])+"\t"+lines[i].strip())

print("--------------------------------------------------------")
print("--------------------------------------------------------")
print("--------------------------------------------------------")
bitfields          = [""]
bitpositions_upper = [0]
bitpositions_lower = [0]
bitdescriptions    = [""]
bitnum             = 0
#Go through the filtered list and pick out the information to add to the hash table
for i in range(0,len(lines)):
    line = lines[i]
    type = lines_num[i]
    if(type == 0):
        #Start of register description
        r = re.findall('\[(.*?)\]',line)
        #Should capture 4 groups
        if(len(r) != 4):
            print("Weird parse for initial register line comment")
            exit()
        designator          = r[0].replace(REG_PARSE_STR_KEY,"").strip()
        address             = r[1].strip()
        name                = r[2].strip()
        access              = r[3].strip()
        print("Register Parsed, found these details:")
        print("\t"+designator)
        print("\t"+address)
        print("\t"+name)
        print("\t"+access)
        
    elif(type == 1):
        #Start of bitfield - name and position
        r = re.findall('(\[.*?\])',line)
        if(len(r) != 1):
            print("Weird parse for initial bitfield name")
            exit()
        #Get position
        upper = 0 
        lower = 0
        r = re.search('\[\d+:\d+]',line)
        if(r):
            #Multi-bit field
            r = re.search('\[(\d+):(\d+)\]',line)
            upper = r.group(1)
            lower = r.group(2)
        else:
            #Single-bit field
            r = re.search('\[(.*?)\]',line)
            upper = r.group(1)
            lower = r.group(1)
        #Get name
        bname = ""
        r = re.search('\](.*)',line)
        if(r):
            bname = r.group(1)
            bname = bname.strip()
        else:
            print("Weird parse for initial bitfield name")
            exit()
        print("Bitfield Parsed, found these details:")
        print("\t"+bname)
        print("\t"+upper)
        print("\t"+lower)
        
        if(int(upper) > 31):
            print("Bad upper bound: " + str(upper))
            exit()
        if(int(lower) < 0):
            print("Bad lower bound: " + str(lower))
            exit()
        if(int(lower) > int(upper)):
            print("Bad lower or upper bound: " + str(lower) + " > " + str(upper))
            exit()
            
        bitnum = bitnum + 1
        
        bitfields.append(bname)
        bitpositions_upper.append(upper)
        bitpositions_lower.append(lower)
        bitdescriptions.append("")
        
        
    elif(type == 2):
        bitdescriptions[bitnum] = bitdescriptions[bitnum] + line.strip() + "\r\n"
    elif(type == 3):
        
        bitfields.pop(0)
        bitpositions_upper.pop(0)
        bitpositions_lower.pop(0)
        bitdescriptions.pop(0)

        #Check if the key exists in the hash table
        if address in regmap:
            #Key exists, update key
            if(name != regmap[address].name):
                print("Same key, different name error for key " + address)
                print("New: " + name)
                print("Old: " + regmap[address].name)
                exit()
            if(designator != regmap[address].designator):
                print("Same key, different designator error for key " + address)
                print("New: " + designator)
                print("Old: " + regmap[address].designator)
                exit()
            if(access != regmap[address].access):
                print("Same key, different access error for key " + address)
                print("New: " + access)
                print("Old: " + regmap[address].access)
                exit()
            #Append table entries to key
            regmap[address].bitfields          = regmap[address].bitfields          + bitfields
            regmap[address].bitpositions_upper = regmap[address].bitpositions_upper + bitpositions_upper
            regmap[address].bitpositions_lower = regmap[address].bitpositions_lower + bitpositions_lower
            regmap[address].bitdescriptions    = regmap[address].bitdescriptions    + bitdescriptions
                
        else:
            #Key does not exist, create entry
            regmap[address] = register_class()
            regmap[address].designator         = designator
            regmap[address].name               = name
            regmap[address].access             = access
            regmap[address].bitfields          = bitfields
            regmap[address].bitpositions_upper = bitpositions_upper
            regmap[address].bitpositions_lower = bitpositions_lower
            regmap[address].bitdescriptions    = bitdescriptions
        

        
        bitfields          = [""]
        bitpositions_upper = [0]
        bitpositions_lower = [0]
        bitdescriptions    = [""]
        bitnum             = 0

print("--------------------------------------------------------")
print("--------------------------------------------------------")
print("--------------------------------------------------------")
print("--------------------------------------------------------")
print("--------------------------------------------------------")
print("--------------------------------------------------------")

#Sort the keys by numerical order instead of the order we added them in
regmap_sorted = {}
pre_sorted_register = register_class()

for i in sorted(regmap):

    #Also sort the bitfields by lower bit positions
    #Had to hack this code together, McDonalds making be very sleepy   
    temp = regmap[i].bitpositions_lower
    for ii in range(0,len(temp)):
        temp[ii] = int(temp[ii])    

    zipped = zip(temp,regmap[i].bitpositions_upper,regmap[i].bitfields,regmap[i].bitdescriptions)
    sorted_zipped = sorted(zipped)
    
    cnt = 0
    for x in sorted_zipped:
        temp[cnt] = x[0]
        regmap[i].bitpositions_upper[cnt] = x[1]
        regmap[i].bitfields[cnt] = x[2]
        regmap[i].bitdescriptions[cnt] = x[3]
        cnt = cnt + 1
    
    for ii in range(0,len(temp)):
        temp[ii] = str(temp[ii])
    
    regmap_sorted[i] = regmap[i]
    
regmap = regmap_sorted

for x in regmap:
    print("--------------------------------------------------------")
    print("Address: " + x)
    print(regmap[x].designator        )
    print(regmap[x].name              )
    print(regmap[x].access            )
    print(regmap[x].bitfields         )
    print(regmap[x].bitpositions_upper)
    print(regmap[x].bitpositions_lower)
    print(regmap[x].bitdescriptions   )
    print("--------------------------------------------------------")

fr.close()



#At this point we've parsed the HDL file and have obtained a hash table of the register map
#Write in user functions and imports
fw = open(ofilepath, "w")
fw.write("#Dave Muscle, 4/3/21\n")
fw.write("#Auto-generated FPGA register classes\n")
fw.write("\n")
fw.write("from UART import register_write\n")
fw.write("from UART import register_read \n")
fw.write("\n")
fw.write("def masked_write(addr, value, bits):      \n")
fw.write("\tt = register_read(addr)                 \n")
fw.write("\tbits_low = bits[0]                      \n")
fw.write("\tbits_upp = bits[1]                      \n")
fw.write("\tbits_diff = bits_upp - bits_low + 1     \n")
fw.write("\tvalue       = value & (2**(bits_diff)-1)\n")
fw.write("\tvalue_shift = value << bits_low         \n")
fw.write("\tdata_upp = t & ~(2**(bits_upp+1)-1)     \n")
fw.write("\tdata_low = t &  (2**(bits_low)-1)       \n")
fw.write("\tdata = data_upp + value_shift + data_low\n")
fw.write("\tregister_write(addr,data)               \n")
fw.write("\n")
fw.write("def masked_read(addr,bits):          \n")
fw.write("\tt = register_read(addr)            \n")
fw.write("\tbits_low  = bits[0]                \n")
fw.write("\tbits_upp  = bits[1]                \n")
fw.write("\tbits_diff = bits_upp - bits_low + 1\n")
fw.write("\tvalue = t >> bits_low              \n")
fw.write("\tmask = 2**(bits_diff)-1            \n")
fw.write("\tvalue = value & mask               \n")
fw.write("\treturn value                       \n")
fw.write("\n")
#fw.write("class FPGA_bit:\n")
#fw.write("\tdef write(self,addr,value,bits):\n")
#fw.write("\t\tmasked_write(addr,value,bits)\n")
#fw.write("\n")
#fw.write("\tdef read(self,addr,bits):\n")
#fw.write("\t\treturn(masked_read(addr,bits))\n")
#fw.write("\n")
for key in regmap:
    for i in range(0,len(regmap[key].bitfields)):
        bl = regmap[key].bitpositions_lower[i]
        bu = regmap[key].bitpositions_upper[i]        
        if(int(bl) == 0 and int(bu) == 31):
            continue        
        bitstring = "[" + bl + "," + bu + "]"
        fw.write("class "+regmap[key].designator+"_"+regmap[key].bitfields[i]+"_bits:\n")
        fw.write("\tdef write(self,value):\n")
        fw.write("\t\tmasked_write("+key+",value,"+bitstring+")\n")
        fw.write("\tdef read(self):\n")
        fw.write("\t\treturn(masked_read("+key+","+bitstring+"))\n")
        fw.write("\n")
        

#Write in register classes
for key in regmap:
    fw.write("class " + regmap[key].designator + "_register:\n")
    fw.write("\n")
    #Write in the bitfields for the register
    for i in range(0,len(regmap[key].bitfields)):
        bl = regmap[key].bitpositions_lower[i]
        bu = regmap[key].bitpositions_upper[i]
        
        #Skip if the bitfield is the entire register
        if(int(bl) == 0 and int(bu) == 31):
            continue
        bitstring = "[" + bl + "," + bu + "]"
        
        #fw.write("\t" + regmap[key].bitfields[i] + "_bits = [" + bl + "," + bu + "]\n")        
        #fw.write("\t@property\n")
        #fw.write("\tdef " + regmap[key].bitfields[i] + "(self):\n")
        #fw.write("\t\treturn(masked_read(" + key + "," + bitstring + "))\n")
        #fw.write("\t@" + regmap[key].bitfields[i] + ".setter\n")
        #fw.write("\tdef " + regmap[key].bitfields[i] + "(self,value):\n")
        #fw.write("\t\tmasked_write(" + key + ",value," + bitstring + ")\n")
        #fw.write("\t\n")
        
        #fw.write("\t"+regmap[key].bitfields[i]+"\n")
        
        fw.write("\t"+regmap[key].bitfields[i]+"="+regmap[key].designator+"_"+regmap[key].bitfields[i]+"_bits()\n")
        
        
    #Write in the "all" entry for the register
    #fw.write("\t@property\n")
    #fw.write("\tdef all(self):\n")
    #fw.write("\t\treturn(register_read(" + key + "))\n")
    #fw.write("\t@all.setter\n")
    #fw.write("\tdef all(self,value):\n")
    #fw.write("\t\tregister_write(" + key + "," + "value" + ")\n")
    #fw.write("\n")

    fw.write("\tdef write(self,value):\n")
    fw.write("\t\tregister_write("+key+",value)\n")
    fw.write("\tdef read(self):\n")
    fw.write("\t\treturn(register_read("+key+"))\n")
    #Write in the "help" entry for the register
    #fw.write("\t@property\n")
    fw.write("\tdef help(self):\n")
    for i in range(0,len(regmap[key].bitfields)):
        field = regmap[key].bitfields[i]
        desc = regmap[key].bitdescriptions[i]

        bl = regmap[key].bitpositions_lower[i]
        bu = regmap[key].bitpositions_upper[i]
 
        if(int(bu) == int(bl)):
            line = "\"\\t["+bu+"]: " + field + "\")\n"
        else:
            line = "\"\\t["+bu+":"+bl+"]: " + field + "\")\n"
   
        fw.write("\t\tprint(" + line)
        
        for line in desc.splitlines():
            line = line.strip()
            line = line.replace("\"", "\\\"")
            fw.write("\t\tprint(\"\\t\\t" + line.strip() + "\")\n")

    fw.write("\n")

#Write in the main FPGA class
fw.write("class FPGA_def:\n")
fw.write("\n")
for key in regmap:
    fw.write("\t" + regmap[key].designator + " = " + regmap[key].designator + "_register()\n")
    
fw.write("\n")
#fw.write("\t@property\n")
fw.write("\tdef help(self):\n")

longest_length = 0
#Get longest string length
for key in regmap:
    if(len(regmap[key].designator) > longest_length):
        longest_length = len(regmap[key].designator)

#Write in the help command for the main FPGA class
for key in regmap:
    line_addr = "Addr: " + key
    line_desi = regmap[key].designator
    line_acce = regmap[key].access
    line_name = regmap[key].name
    
   
    line = line_addr + " | " + line_desi
    numspaces = longest_length - len(line_desi) + 1
    for i in range(0,numspaces):
        line = line + " "
    line = line + "| " + line_acce + " "
    line = line + "| " + line_name
        
    
    fw.write("\t\tprint(\"\\t"+line + "\")\n")

fw.close()

print("Done")
