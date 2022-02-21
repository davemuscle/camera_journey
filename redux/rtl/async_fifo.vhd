library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
--Simple Async FIFO that uses block ram

entity async_fifo is
	generic(
		gDEPTH : integer := 16;  --length of fifo
		gWIDTH : integer := 2;   --data width
		gOREGS : integer := 2   --number of input regs

	);
	port(
		wr_clk    : in std_logic;	
		wr_en     : in std_logic;
		wr_data   : in std_logic_vector(gWIDTH-1 downto 0);
		
		rd_clk    : in  std_logic;
		rd_en     : in  std_logic;
		rd_data   : out std_logic_vector(gWIDTH-1 downto 0);
		
		reset    : in std_logic; --asynchronous
		
		ff : out std_logic := '0'; --fifo full
		fe : out std_logic := '0'; --fifo empty
		
		ov : out std_logic := '0'; --overflow
		un : out std_logic := '0'  --underflow
		
	);
end async_fifo;

architecture bhv of async_fifo is 
    
	constant gDLOG2 : integer := integer(ceil(log2(real(gDEPTH))));
	
	--reset dfs
	signal reset_wr_meta, reset_wr_sync : std_logic := '0';
	signal reset_rd_meta, reset_rd_sync : std_logic := '0';
	
	--full and empty logic
	signal full, empty : std_logic := '0';
	
	--binary pointers, fifo addresses. an extra bit is there for full comparison
	signal wr_ptr, rd_ptr : std_logic_vector(gDLOG2 downto 0) := (others => '0');
	
	--gray coded pointers
	signal wr_ptr_gry, rd_ptr_gry : std_logic_vector(gDLOG2 downto 0) := (others => '0');
	
	--sync'd gray code pointers
	signal wr_ptr_gry_meta, wr_ptr_gry_sync : std_logic_vector(gDLOG2 downto 0) := (others => '0');
	signal rd_ptr_gry_meta, rd_ptr_gry_sync : std_logic_vector(gDLOG2 downto 0) := (others => '0');
	
	--sync'd binary pointers
	signal wr_ptr_sync, rd_ptr_sync : std_logic_vector(gDLOG2 downto 0) := (others => '0');

	
begin

	--modify the wr_ptr on incoming writes if the fifo is not full
	process(wr_clk)
	begin
		if(rising_edge(wr_clk)) then
			
			ov <= '0';
			
			if(wr_en = '1' and full = '0') then
			
				wr_ptr <= std_logic_vector(unsigned(wr_ptr)+1);

			elsif(wr_en = '1' and full = '1') then
				ov <= '1';
			end if;
                
            --gray code conversion for the wr_ptr
            wr_ptr_gry(gDLOG2-0) <= wr_ptr(gDLOG2-0);
            wr_ptr_gry(gDLOG2-1 downto 0) <= wr_ptr(gDLOG2-0 downto 1) xor wr_ptr(gDLOG2-1 downto 0);
			
			--sync the reset signa
			reset_wr_meta <= reset;
			reset_wr_sync <= reset_wr_meta;
			
			--sync the rd ptr in the wr domain
			rd_ptr_gry_meta <= rd_ptr_gry;
			rd_ptr_gry_sync <= rd_ptr_gry_meta;

            --binary conversion for the synced rd ptr
            rd_ptr_sync(gDLOG2-0) <= rd_ptr_gry_sync(gDLOG2-0);
            rd_ptr_sync(gDLOG2-1 downto 0) <= rd_ptr_sync(gDLOG2-0 downto 1) xor rd_ptr_gry_sync(gDLOG2-1 downto 0);
        
			
			--putting reset logic after all the other logic
			if(reset_wr_sync = '1') then
				ov <= '0';
				wr_ptr <= (others => '0');
                wr_ptr_gry <= (others => '0');
                rd_ptr_gry_meta <= (others => '0');
                rd_ptr_gry_sync <= (others => '0');
                rd_ptr_sync <= (others => '0');
			end if;
			
		end if;
	end process;
	
	--modify the rd_ptr on requested reads
	process(rd_clk)
	begin
		if(rising_edge(rd_clk)) then
		
			un <= '0';
		
			if(rd_en = '1' and empty = '0') then

				rd_ptr <= std_logic_vector(unsigned(rd_ptr)+1);

			elsif(rd_en = '1' and empty = '1') then
				un <= '1';
			end if;
			
            --gray code conversion for the rd_ptr
            rd_ptr_gry(gDLOG2-0) <= rd_ptr(gDLOG2-0);
            rd_ptr_gry(gDLOG2-1 downto 0) <= rd_ptr(gDLOG2-0 downto 1) xor rd_ptr(gDLOG2-1 downto 0);
            
			--sync the reset signal
			reset_rd_meta <= reset;
			reset_rd_sync <= reset_rd_meta;
			
			--sync the wr cnt to the rd clk domain
			wr_ptr_gry_meta <= wr_ptr_gry;
			wr_ptr_gry_sync <= wr_ptr_gry_meta;
        
            --binary conversion for the synced wr ptr
            wr_ptr_sync(gDLOG2-0) <= wr_ptr_gry_sync(gDLOG2-0);
            wr_ptr_sync(gDLOG2-1 downto 0) <= wr_ptr_sync(gDLOG2-0 downto 1) xor wr_ptr_gry_sync(gDLOG2-1 downto 0);
            
			--puting reset logic after all other logic
			if(reset_rd_sync = '1') then
				un <= '0';
				rd_ptr <= (others => '0');
                rd_ptr_gry <= (others => '0');
                wr_ptr_gry_meta <= (others => '0');
                wr_ptr_gry_sync <= (others => '0');
                wr_ptr_sync <= (others => '0');
			end if;
		end if;
	end process; 
	
	--flag assignments
	full  <= '1' when ((wr_ptr(gDLOG2) /= rd_ptr_sync(gDLOG2)) and (wr_ptr(gDLOG2-1 downto 0) = rd_ptr_sync(gDLOG2-1 downto 0))) else '0';
	empty <= '1' when (wr_ptr_sync = rd_ptr) else '0';
	
	fifo_bram_inst : entity work.inferred_ram
	generic map(
		gDEPTH => gDLOG2,
		gWIDTH => gWIDTH,
		gOREGS => gOREGS
	)
	port map(
		a_clk  => wr_clk,
		a_wr   => wr_en,
		a_en   => '0',
		a_di   => wr_data,
		a_do   => open,
		a_addr => wr_ptr(gDLOG2-1 downto 0),
		b_clk  => rd_clk,
		b_wr   => '0',
		b_en   => rd_en,
		b_di   => (others => '0'),
		b_do   => rd_data,
		b_addr => rd_ptr(gDLOG2-1 downto 0)
	);




end bhv;		

