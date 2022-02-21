library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

--Inferred block ROM with output pipeline registers
--Can initialize with a textfile of bitvectors

entity inferred_rom is
	generic(
		gDEPTH     : integer := 2;      --nextpow2 of BRAM length
		gWIDTH     : integer := 16;     --datawidth
		gOREGS     : integer := 2;      --number of input regs >= 1
		gINITFILE  : string             --string to init file
	);
	port(
		clk  : in  std_logic;
		en   : in  std_logic;
		do   : out std_logic_vector(gWIDTH-1 downto 0);
		addr : in  std_logic_vector(gDEPTH-1 downto 0)
	);
end inferred_rom;

architecture bhv of inferred_rom is 
    
	--ram type
    type rom_type is array ((2**gDEPTH)-1 downto 0) of bit_vector(gWIDTH-1 downto 0);

	--initializing RAM to text file or zeros
	impure function rom_init(filename : string) return rom_type is
	  file rom_file : text open read_mode is filename;
	  variable rom_line : line;
	  variable rom_value : bit_vector(gWIDTH-1 downto 0);
	  variable temp : rom_type;
	  variable zeros : rom_type := (others => (others => '0'));
	begin
		for rom_index in 0 to 2**gDEPTH - 1 loop
			readline(rom_file, rom_line);
			read(rom_line, rom_value);
			temp(rom_index) := (rom_value);
		end loop;
		return temp;
	end function;
	
	--shared variable for bram
	shared variable brom : rom_type := rom_init(filename => gINITFILE);
	
	--pipelining registers
	type oregs_t is array(0 to gOREGS) of std_logic_vector(gWIDTH-1 downto 0);
	signal oregs : oregs_t := (others => (others => '0'));
	
begin

    --port A
	process(clk)
	begin
		if(rising_edge(clk)) then	
        
			if(gOREGS /= 0) then
				for i in 1 to gOREGS loop
					a_oregs(i) <= a_oregs(i-1);
				end loop;
			end if;
            
		
			if(en = '1') then
				oregs(0) <= (to_StdLogicVector(brom(to_integer(unsigned(addr)))));
			end if;
			
		end if;
	end process;

	--assign the output
	do <= oregs(gOREGS);


end bhv;		

