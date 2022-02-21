library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.math_real.all;

entity async_fifo_tb is 

end async_fifo_tb;

architecture test of async_fifo_tb is

	signal rd_clk_count : integer := 0;
	signal wr_clk_count : integer := 0;
	
	constant gDEPTH : integer := 32;
	constant gWIDTH : integer := 8;
	constant gDLOG2 : integer := 5;
	
	signal wr_clk  : std_logic := '0';
	signal wr_en   : std_logic := '0';
	signal wr_data : std_logic_vector(gWIDTH-1 downto 0) := (others => '0');

	signal rd_clk  : std_logic := '0';
	signal rd_en   : std_logic := '0';
	signal rd_data : std_logic_vector(gWIDTH-1 downto 0) := (others => '0');
	signal ff,fe,pf,pe,ov,un : std_logic := '0';
	
	signal load_en, read_en : std_logic := '0';
begin


	async_fifo_inst : entity work.async_fifo
	generic map(
		gDEPTH => gDEPTH, 
		--gDLOG2 => gDLOG2, 
		gWIDTH => gWIDTH, 
		gOREGS => 0     
	)
	port map(
		wr_clk  => wr_clk, 
		wr_en   => wr_en,
		wr_data => wr_data,
		rd_clk  => rd_clk,
		rd_en   => rd_en,
		rd_data => rd_data,
		reset   => '0',
		ff => ff,
		fe => fe,
		ov => ov,
		un => un
	);
	
	rdclk_stim : process
	begin
		rd_clk <= '0';
		wait for 27 ns;
		rd_clk <= '1';
		wait for 27 ns;
	end process;

	wrclk_stim : process
	begin
		wr_clk <= '0';
		wait for 17.2 ns;
		wr_clk <= '1';
		wait for 17.2 ns;
	end process;

	
	--write into the fifo whenever it is not full
	process(wr_clk)
	begin
		if(rising_edge(wr_clk)) then
			
			wr_clk_count <= wr_clk_count + 1;
			if(wr_clk_count = 100) then
				wr_clk_count <= 100;
			end if;
		
			if(wr_clk_count = 10) then
				load_en <= '1';
			end if;
		
			if(pf = '0' and load_en = '1') then
				wr_en <= '1';
				wr_data <= std_logic_vector(unsigned(wr_data)+1);
			else
				wr_en <= '0';
			end if;
			
		end if;
	end process;

	process(rd_clk)
	begin
		if(rising_edge(rd_clk)) then
			if(pe = '0') then
				rd_en <= '1';
			else
				rd_en <= '0';
			end if;
		end if;
	end process;

    process
    begin
		wait;
    end process;
    
end test;