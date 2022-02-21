-- Code your testbench here
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is 

end testbench;

architecture test of testbench is
    
	signal clk : std_logic := '0';
	signal reset, valid_in, eol_in, sof_in : std_logic := '0';
	signal data_in, data_out : std_logic_vector(3 downto 0) := (others => '0');
	signal hsync, vsync, de, sync_error : std_logic := '0';
 
	signal pixel_in_cnt : integer := 0;
	
	constant h_active     : integer := 8;
	constant h_frontporch : integer := 1;
	constant h_syncwidth  : integer := 2;
	constant h_backporch  : integer := 1;
	constant h_total      : integer := 12;
	
	constant v_active     : integer := 4;
	constant v_frontporch : integer := 1;
	constant v_syncwidth  : integer := 2;
	constant v_backporch  : integer := 1;
	constant v_total      : integer := 8; 
	
	signal h_count_tb, v_count_tb : integer := 0;
	
begin
	demo: entity work.vstream2vga
	generic map(
		DATA_WIDTH   => 4,
		SYNC_POL     => '1',
	    h_active 	 => h_active 	,
	    h_frontporch => h_frontporch,
	    h_syncwidth  => h_syncwidth ,
	    h_backporch  => h_backporch ,
	    h_total      => h_total     ,
	    v_active     => v_active    ,
	    v_frontporch => v_frontporch,
	    v_syncwidth  => v_syncwidth ,
	    v_backporch  => v_backporch ,
	    v_total		 => v_total		
	)
	port map(
		clk => clk,
		reset => '0',
		
		data_in => data_in,
		valid_in => valid_in,
		sof_in   => sof_in,
		eol_in => eol_in,
		
		data_out => data_out,
		hsync => hsync,
		vsync => vsync,
		de    => de,
		sync_error => sync_error

	);
 
	process(clk)
	begin
		if(rising_edge(clk)) then
		
			if(h_count_tb = h_total-1) then
				h_count_tb <= 0;
				if(v_count_tb = v_total-1) then
					v_count_tb <= 0;
				else
					v_count_tb <= v_count_tb + 1;
				end if;
			else
				h_count_tb <= h_count_tb + 1;
			end if;
			
			if(h_count_tb < h_active and v_count_tb < v_active) then
				valid_in <= '1';
			else
				valid_in <= '0';
			end if;
			
			if(h_count_tb = h_active-1 and v_count_tb < v_active) then
				eol_in <= '1';
			else
				eol_in <= '0';
			end if;
			
			if(h_count_tb = 0 and v_count_tb = 0) then
				pixel_in_cnt <= 1;
				sof_in <= '1';
			else
				sof_in <= '0';
				pixel_in_cnt <= pixel_in_cnt + 1;
			end if;
			
			if(pixel_in_cnt = 12) then
				pixel_in_cnt <= 1;
			end if;
			
		end if;
	end process;

	data_in <= std_logic_vector(to_unsigned(pixel_in_cnt,4));
	
	clk_stim : process
	begin
		clk <= not clk;
		wait for 1 ns;
		clk <= not clk;
		wait for 1 ns;
	end process;
	
	
    process
    begin   
    wait;
    
    end process;
    
end test;