library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

--Simple Sync FIFO that uses block ram
--FIFO size has to be power of 2 because of address math

entity sync_fifo is
	generic(
		gDEPTH : integer := 16;  --length of fifo
		gWIDTH : integer := 2;   --data width
		gOREGS : integer := 2;   --number of output regs
		gPF    : integer := 12;  --programmable full generic
		gPE    : integer := 4    --programmable empty generic

	);
	port(
		clk       : in std_logic;
		reset     : in std_logic;
        
		wr_en     : in std_logic;
		wr_data   : in std_logic_vector(gWIDTH-1 downto 0);

		rd_en     : in  std_logic;
		rd_data   : out std_logic_vector(gWIDTH-1 downto 0);
		
		ff : out std_logic := '0'; --fifo full
		fe : out std_logic := '0'; --fifo empty
		pf : out std_logic := '0'; --prog full
		pe : out std_logic := '0'; --prog empty
		
		ov : out std_logic := '0'; --overflow
		un : out std_logic := '0'  --underflow
		
	);
end sync_fifo;

architecture bhv of sync_fifo is 
    
	constant gDLOG2 : integer := integer(ceil(log2(real(gDEPTH))));
	
	signal fifo_cnt : integer range 0 to gDEPTH := 0;
	signal wr_ptr, rd_ptr : std_logic_vector(gDLOG2-1 downto 0) := (others => '0');
	
    signal rd_en_dly : std_logic := '0';
    signal rd_data_pulsed : std_logic_vector(gWIDTH-1 downto 0) := (others => '0');
    signal rd_data_muxed : std_logic_vector(gWIDTH-1 downto 0) := (others => '0');
    
begin

	process(clk)
	begin
		if(rising_edge(clk)) then
		
			--increment
			if(wr_en = '1') then
				if(fifo_cnt = gDEPTH) then
					ov <= '1';
					fifo_cnt <= fifo_cnt;
				else
					ov <= '0';
					fifo_cnt <= fifo_cnt + 1;
				end if;
				wr_ptr <= std_logic_vector(unsigned(wr_ptr)+1);
			end if;
		
			--decrement
			if(rd_en = '1') then
				if(fifo_cnt = 0) then
					un <= '1';
					fifo_cnt <= fifo_cnt;
				else
					un <= '0';
					fifo_cnt <= fifo_cnt - 1;
				end if;
				rd_ptr <= std_logic_vector(unsigned(rd_ptr)+1);
			end if;

			--no change
			if(wr_en = '1' and rd_en = '1') then
				fifo_cnt <= fifo_cnt;
			end if;
		
            if(reset = '1') then
                fifo_cnt <= 0;
                ov <= '0';
                un <= '0';
                wr_ptr <= (others => '0');
                rd_ptr <= (others => '0');
            end if;
        
		end if;
	end process;

	ff <= '1' when fifo_cnt = gDEPTH   else '0';
	fe <= '1' when fifo_cnt = 0        else '0';
	pf <= '1' when fifo_cnt > gPF      else '0';
	pe <= '1' when fifo_cnt < gPE      else '0';

	fifo_bram_inst : entity work.inferred_ram
	generic map(
		gDEPTH => gDLOG2,
		gWIDTH => gWIDTH,
		gOREGS => gOREGS
	)
	port map(
		a_clk   => clk,
        --a_reset => reset,
		a_wr    => wr_en,
		a_en    => '0',
		a_di    => wr_data,
		a_do    => open,
		a_addr  => wr_ptr,
		b_clk   => clk,
        --b_reset => reset,
		b_wr    => '0',
		b_en    => rd_en,
		b_di    => (others => '0'),
		b_do    => rd_data,
		b_addr  => rd_ptr
	);




end bhv;		

