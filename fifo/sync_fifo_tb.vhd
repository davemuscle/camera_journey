library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.math_real.all;

entity sync_fifo_tb is 

end sync_fifo_tb;

architecture test of sync_fifo_tb is

	signal rd_clk_count : integer := 0;
	signal wr_clk_count : integer := 0;
	
	constant gDEPTH : integer := 32;
	constant gWIDTH : integer := 8;
	constant gDLOG2 : integer := 5;
	
	signal clk  : std_logic := '0';
	signal wr_en   : std_logic := '0';
	signal wr_data : std_logic_vector(gWIDTH-1 downto 0) := (others => '0');

	signal rd_en   : std_logic := '0';
	signal rd_data : std_logic_vector(gWIDTH-1 downto 0) := (others => '0');
	signal ff,fe,pf,pe,ov,un : std_logic := '0';
	
	signal load_en, read_en : std_logic := '0';

	
begin


	sync_fifo_inst : entity work.sync_fifo
	generic map(
		gDEPTH => gDEPTH, 
		gWIDTH => gWIDTH, 
		gOREGS => 0     , 
		gPF    => 24    , 
		gPE    => 8
	)
	port map(
		clk => clk,
		wr_en   => wr_en,
		wr_data => wr_data,
		rd_en   => rd_en,
		rd_data => rd_data,
		ff => ff,
		fe => fe,
		pf => pf,
		pe => pe,
		
		ov => ov,
		un => un
	);
	
	clk_stim : process
	begin
		clk <= '0';
		wait for 20 ns;
		clk <= '1';
		wait for 20 ns;
	end process;
	
	--write into the fifo whenever it is not full
	process(clk)
	begin
		if(rising_edge(clk)) then
			
			wr_clk_count <= wr_clk_count + 1;
			if(wr_clk_count = 100) then
				wr_clk_count <= 100;
			end if;
		
			-- if(wr_clk_count = 10) then
				-- load_en <= '1';
			-- end if;

			if(load_en = '1') then
				--wr_en <= '1';
				wr_data <= std_logic_vector(unsigned(wr_data)+1);
			else
				--wr_en <= '0';
			end if;
		
			
			-- if(read_en = '1') then
				-- rd_en <= '1';
			-- else
				-- rd_en <= '0';
			-- end if;
			
			
		end if;
	end process;

	process(ff,fe)
	begin
		if(ff = '1') then
			load_en <= '0';
			read_en <= '1';
		end if;
		
		if(fe = '1') then
			load_en <= '1';
			read_en <= '0';
		end if;
		
	end process;
	
	wr_en <= load_en;
	rd_en <= read_en;

    process
    begin
		wait;
    end process;
    
end test;