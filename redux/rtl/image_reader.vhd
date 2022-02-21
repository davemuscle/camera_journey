library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

--Dave Muscle

--Testbench Only
--Sequentially read 24 bit data (as integers)

entity image_reader is
	port(
	    clk      : in  std_logic;
        i_file   : in  string;
        enable   : in  std_logic;
        sync     : in  std_logic;
        rgb      : out std_logic_vector(23 downto 0) := (others => '0')
        );
end image_reader;

architecture arch of image_reader is 
    
    file img_file : text;
    signal sync_dly : std_logic := '0';

    type img_file_t is file of integer;
    
    signal file_opened : std_logic := '0';

begin	

    process(clk)
        file data_in : text;
        variable file_status : file_open_status;

        variable img_line : line;
        variable img_value : integer;
    begin
        if(rising_edge(clk)) then

            if(sync = '1') then
                --close file if it is open
                if(file_opened = '1') then
                    file_close(data_in);
                end if;
                --open it
                file_open(file_status,data_in,i_file,read_mode);
                file_opened <= '1';
            end if;

            --get data from image if SIM is true
            if(enable = '1') then            
                readline(data_in, img_line);
                read(img_line, img_value);
                rgb <= std_logic_vector(to_unsigned(img_value,24));
            else
                rgb <= (others => '0');
            end if;

            --Is leaving the file open on sim close okay? Hopefully!

        end if;
    end process;
    
 
    
end arch;
