-- Code your testbench here
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity ov5640_vstream_tb is 

end ov5640_vstream_tb;

architecture test of ov5640_vstream_tb is
    
	signal clk : std_logic := '0';

    signal vsync, href : std_logic := '0';
    
    signal data_in : std_logic_vector(7 downto 0) := (0 => '0', others => '0');
    signal data_out : std_logic_vector(7 downto 0) := (others => '0');
    
    signal valid, sof, eol : std_logic := '0';
    
    signal h_count, v_count : integer range 0 to 4095 := 0;
	
begin
	video_proc : entity work.ov5640_vstream
	generic map(
		HREF_POLARITY => '1',
        VSYNC_POLARITY => '0',
        h_active => 26,
        v_active => 7
	)
	port map(
		clk    => clk,
		reset => '0',
		vsync => vsync,
        href => href,
        data_in => data_in,
		
        data_out => data_out,
		valid => valid,
		sof   => sof,
		eol   => eol

	);

	clk_stim : process
	begin
        wait for 1 ns;
		clk <= not clk;
        wait for 1 ns;
		clk <= not clk;

	end process;
	
	process(clk)
    begin
        if(rising_edge(clk)) then
  
            data_in <= std_logic_vector(unsigned(data_in)+1);
  
            if(h_count = 31) then
                h_count <= 0;
                if(v_count = 9) then
                    v_count <= 0;
                    data_in <= (0 => '0', others => '0');
                else
                    v_count <= v_count + 1;
                end if;
            else
                h_count <= h_count + 1;
            end if;
            
            if(h_count < 26 and v_count < 7) then
                href <= '1';
                --active
            else
                href <= '0';
            end if;
            
            if(v_count = 8) then
                vsync <= '0';
            else
                vsync <= '1';
            end if;
            
            
            
        end if;
    end process;
    
    
    
    process
    begin   
    wait;
    
    end process;
    
end test;