library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

--UART core
--8 data bits, no parity, 1 stop bit

--FIFO_SIZE must be power of 2

entity uart is
	generic(
		CLKRATE   : integer := 50000000;
		BAUDRATE  : integer := 115200;
		DATA_SIZE : integer := 8;
		FIFO_SIZE : integer := 8

	);
	port(
		clk   : in std_logic;
		
		--uart pins
		rx : in  std_logic;
		tx : out std_logic;
		
		--rx fifo signals
		rx_valid   : out std_logic;
		rx_full    : out std_logic;
		rx_rd_en   : in  std_logic;
		rx_rd_data : out std_logic_vector(DATA_SIZE-1 downto 0);
		rx_fifo_ov : out std_logic := '0';
		rx_fifo_un : out std_logic := '0';
		
		--tx fifo signals
		tx_ready   : out std_logic;
		tx_empty   : out std_logic;
		tx_wr_en   : in  std_logic;
		tx_wr_data : in  std_logic_vector(DATA_SIZE-1 downto 0);
		tx_fifo_ov : out std_logic := '0';
		tx_fifo_un : out std_logic := '0'
		
		
		
	);
end uart;

architecture bhv of uart is 
	
	constant BAUDDIV  : integer   := integer(CLKRATE/BAUDRATE);
	signal   rx_baud_clk : std_logic := '0';
	signal   rx_baud_cnt : integer range 0 to BAUDDIV-1 := BAUDDIV/2;
    signal   rx_baud_clk_en : std_logic := '0';
    signal   rx_sample_clk : std_logic := '0';
    signal   rx_sample_reg : std_logic_vector(4 downto 0) := (others => '0');
    
	signal   tx_baud_clk : std_logic := '0';
	signal   tx_baud_cnt : integer range 0 to BAUDDIV-1 := 0;	
    signal   tx_baud_clk_en : std_logic := '0';
    
	type   rx_sm_t is (idle, receiving, stop);
	signal rx_sm : rx_sm_t := idle;
	

	
	signal rx_reg : std_logic := '0';
	signal rx_shft_cnt : integer range 0 to DATA_SIZE-1 := 0;
	signal rx_shft_reg : std_logic_vector(DATA_SIZE-1 downto 0) := (others => '0');
	signal rx_shft_reg_en : std_logic := '0';
	signal rx_shft_reg_done : std_logic := '0';
	signal rx_fifo_wr_happened : std_logic := '0';
	
	type   tx_sm_t is (idle, transmitting, stop);
	signal tx_sm : tx_sm_t := idle;
	
	signal tx_shft_reg : std_logic_vector(DATA_SIZE-1 downto 0) := (others => '0');
	signal tx_shft_cnt : integer range 0 to DATA_SIZE-1 := 0;
	signal tx_shft_reg_en : std_logic := '0';
	signal tx_shft_reg_done : std_logic := '0';
	
	--Rx FIFO Signals
	signal rx_fifo_wr_en, rx_fifo_rd_en : std_logic := '0';
	signal rx_fifo_wr_data, rx_fifo_rd_data : std_logic_vector(DATA_SIZE-1 downto 0) := (others => '0');
	signal rx_fifo_ff, rx_fifo_fe : std_logic := '0';
	
	--Tx FIFO Signals
	signal tx_fifo_wr_en, tx_fifo_rd_en : std_logic := '0';
	signal tx_fifo_wr_data, tx_fifo_rd_data : std_logic_vector(DATA_SIZE-1 downto 0) := (others => '0');
	signal tx_fifo_ff, tx_fifo_fe : std_logic := '0';
	signal tx_fifo_rd_happened : std_logic := '0';
	
	signal stop_cnt : integer range 0 to 4095 := 0;
    signal tx_stop_setup : std_logic := '0';
	
begin

	--Receiver Baud Rate Generator
	process(clk)
	begin
		if(rising_edge(clk)) then
            if(rx_baud_clk_en = '1') then
                if(rx_baud_cnt = BAUDDIV-1) then
                    rx_baud_cnt <= 0;
                    rx_baud_clk <= '1';
                else
                    rx_baud_cnt <= rx_baud_cnt + 1;
                    rx_baud_clk <= '0';
                end if;             
            else
                rx_baud_clk <= '0';
                rx_baud_cnt <= BAUDDIV/2;
            end if;
		end if;
	end process;
	
	--Rx State Machine
	process(clk)
	begin
		if(rising_edge(clk)) then
		
			if(rx_shft_reg_done = '1') then
				rx_fifo_wr_en <= '1';
			end if;
		
			if(rx_fifo_wr_en = '1') then
				rx_fifo_wr_en <= '0';
			end if;
		
            rx_reg <= rx;

            if(rx_shft_reg_en = '1' and rx_baud_clk = '1') then
                
                --lsb first
                rx_shft_reg <= rx & rx_shft_reg(DATA_SIZE-1 downto 1);

                
            end if;
            
            case rx_sm is
            when idle =>
            
                rx_shft_reg_done <= '0';
            
                --looking for a transition here was a bad idea, had framing errors
                if(rx = '0') then
                    
                    --start the rx baud rate generator
                    rx_baud_clk_en <= '1';
                
                end if;
    
                --wait for half the baud rate period (the counter is initialized to BAUDDIV/2)
                if(rx_baud_clk = '1' and rx = '0') then
                    rx_sm <= receiving;
                end if;
   
            when receiving =>
            
                --wait for the baud rate period
                if(rx_baud_clk = '1') then
                    --shift DATA_SIZE bits in
                    if(rx_shft_cnt = DATA_SIZE-1) then
                        
                        rx_sm <= stop;
                        rx_shft_cnt <= 0;
                    
                    else
                    
                        rx_shft_cnt <= rx_shft_cnt + 1;
                        
                    end if;
                end if;
                
            when stop =>
            
                --wait for the baud rate period
                if(rx_baud_clk = '1') then
                    --wait for a high bit
                    if(rx = '1') then
                        rx_baud_clk_en <= '0';
                        rx_shft_reg_done <= '1';
                        rx_sm <= idle;
                        
                    end if;
                end if;
            
            when others => end case;

		end if;
	end process;
	
	rx_shft_reg_en <= '1' when rx_sm = receiving else '0';
	
	--rx_fifo_wr_en <= rx_shft_reg_done;
	rx_fifo_wr_data <= rx_shft_reg;
	
	--receive data is valid when the rx fifo is not empty
	rx_valid <= not rx_fifo_fe;
	rx_full  <= rx_fifo_ff;
	
	rx_fifo_rd_en <= rx_rd_en;
	rx_rd_data <= rx_fifo_rd_data;

	--Transmitter Baud Rate Generator
	process(clk)
	begin
		if(rising_edge(clk)) then
            if(tx_baud_clk_en = '1') then
                if(tx_baud_cnt = BAUDDIV-1) then
                    tx_baud_cnt <= 0;
                    tx_baud_clk <= '1';
                else
                    tx_baud_cnt <= tx_baud_cnt + 1;
                    tx_baud_clk <= '0';
                end if;
            else
                tx_baud_cnt <= 0;
                tx_baud_clk <= '0';
            end if;
		end if;
	end process;
	
	--Tx State Machine
	process(clk)
	begin
		if(rising_edge(clk)) then
		
			if(tx_fifo_rd_en = '1') then
				tx_fifo_rd_en <= '0';
			end if;
			
            if(tx_shft_reg_en = '1' and tx_baud_clk = '1') then					
                --lsb first
                tx <= tx_shft_reg(0);
                tx_shft_reg <= '0' & tx_shft_reg(DATA_SIZE-1 downto 1);
            end if;
            
            case tx_sm is
            when idle =>
                
                --default line to high
                tx <= '1';
                
                --if the fifo is not empty, read from it
                if(tx_fifo_fe = '0' and tx_fifo_rd_en = '0' and tx_fifo_rd_happened = '0') then
                    tx_fifo_rd_en <= '1';
                    tx_fifo_rd_happened <= '1';
                    tx_baud_clk_en <= '1';
                end if;
                
                if(tx_baud_clk = '1') then
                
                    --if we have read from the fifo, trasmit the start bit and change states
                    if(tx_fifo_rd_happened = '1') then
                        tx_shft_reg <= tx_fifo_rd_data;
                        tx_fifo_rd_happened <= '0';
                        tx_sm <= transmitting;
                        tx <= '0';
                    end if;
                
                end if;

            
            when transmitting =>
            

                if(tx_baud_clk = '1') then
                    --shift bits out
                    if(tx_shft_cnt = DATA_SIZE-1) then
                        tx_shft_cnt <= 0;
                        tx_sm <= stop;
                    else
                        tx_shft_cnt <= tx_shft_cnt + 1;
                    
                    end if;
                end if;
            
            when stop =>
                
                
                
                if(tx_baud_clk = '1') then
                    --place 1 stop bit
                    tx <= '1';
                    tx_stop_setup <= '1';

                end if;
            
                if(tx_baud_clk = '1' and tx_stop_setup = '1') then
                    tx_sm <= idle;
                    tx_baud_clk_en <= '0';
                    tx_stop_setup <= '0';
                end if;
            
            when others => end case;
				
		end if;
	end process;
	
	tx_shft_reg_en <= '1' when tx_sm = transmitting else '0';
	
	--transmitter fifo is ready when it isn't full
	tx_ready <= not tx_fifo_ff;
	tx_empty <= tx_fifo_fe;
	tx_fifo_wr_en <= tx_wr_en;
	tx_fifo_wr_data <= tx_wr_data;
	
	--Rx FIFO
	rx_sync_fifo_inst : entity work.sync_fifo
	generic map(
		gDEPTH => FIFO_SIZE, 
		gWIDTH => DATA_SIZE, 
		gOREGS => 0        , 
		gPF    => 0        , 
		gPE    => 0
	)
	port map(
		clk     => clk,
        reset   => '0',
		wr_en   => rx_fifo_wr_en,
		wr_data => rx_fifo_wr_data,
		rd_en   => rx_fifo_rd_en,
		rd_data => rx_fifo_rd_data,
		ff      => rx_fifo_ff,
		fe      => rx_fifo_fe,
		pf      => open,
		pe      => open,
		ov      => rx_fifo_ov,
		un      => rx_fifo_un
	);	

	--Tx FIFO
	tx_sync_fifo_inst : entity work.sync_fifo
	generic map(
		gDEPTH => FIFO_SIZE, 
		gWIDTH => DATA_SIZE, 
		gOREGS => 0        , 
		gPF    => 0        , 
		gPE    => 0
	)
	port map(
		clk     => clk,
        reset   => '0',
		wr_en   => tx_fifo_wr_en,
		wr_data => tx_fifo_wr_data,
		rd_en   => tx_fifo_rd_en,
		rd_data => tx_fifo_rd_data,
		ff      => tx_fifo_ff,
		fe      => tx_fifo_fe,
		pf      => open,
		pe      => open,
		ov      => tx_fifo_ov,
		un      => tx_fifo_un
	);	

end bhv;		

