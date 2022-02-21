library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

--Dave Muscle

--Verification HDL used for testbenches with video components
--Snoop the video stream and write image data into a text file
--Use an optional matlab script later to convert to .png or something

entity image_writer is
	generic(
        o_file      : string;
        DATA_WIDTH  : integer := 24;
		h_active    : integer := 1920;
		v_active    : integer := 1080
		
		);
	port(
	    clk      : in  std_logic;
        enable   : in  std_logic;
        sof      : in  std_logic;
        eol      : in  std_logic;
        data     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		valid    : in  std_logic;
        pic_err  : out std_logic := '0';
        line_err : out std_logic := '0';
        i_w      : out std_logic := '0'; --image written pulse
        i_w_cnt  : out integer := 0 --count of how many images written into file
        );
end image_writer;

architecture arch of image_writer is 
    
    file o_file_t : text open write_mode is o_file;

    signal i_w_t : std_logic := '0';
    signal i_w_cnt_t : integer := 0;
    
    signal h_cnt, v_cnt : integer range 0 to 16383 := 0;
    
    signal pixel_cnt : integer := 0;
    
begin	

    process(clk)
        variable out_line : line;
    begin
        if(rising_edge(clk)) then
            
            i_w_t <= '0';
            
            if(enable = '1' and valid = '1') then
                
                pixel_cnt <= pixel_cnt + 1;
                
                if(h_cnt = h_active-1) then
                    h_cnt <= 0;
                    if(v_cnt = v_active-1) then
                        v_cnt <= 0;
                        i_w_t <= '1';
                        i_w_cnt_t <= i_w_cnt_t + 1;
                    else
                        v_cnt <= v_cnt + 1;
                    end if;
                else
                    h_cnt <= h_cnt + 1;
                end if;
            
                if(sof = '1' and h_cnt /= 0 and v_cnt /= 0) then
                    pic_err <= '1';
                end if;
                
                if(eol = '1' and h_cnt /= h_active-1) then
                    line_err <= '1';
                end if;
                
                write(out_line, to_integer(unsigned(data)));
                writeline(o_file_t, out_line);
            
                if(sof = '1') then
                    h_cnt <= 1;
                    v_cnt <= 0;
                    i_w_t <= '0';
                end if;
            
            end if;
            
            if(i_w_t = '1') then
                i_w_t <= '0';
            end if;
            
            
        end if;
    end process;
    
    i_w <= i_w_t;
    i_w_cnt <= i_w_cnt_t;
    
end arch;
