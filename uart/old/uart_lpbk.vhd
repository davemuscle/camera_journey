library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Top Level for testing SOC memory with video data
entity uart_lpbk is
	port(
		clk_board : in std_logic;
		tx        : out std_logic;
		rx        : in std_logic;
		rx_dbg    : out std_logic;
		tx_dbg    : out std_logic;
		led0 : out std_logic := '0';
		led1 : out std_logic := '0';
		led2 : out std_logic := '0';
		led3 : out std_logic := '0'
	);
end uart_lpbk;

architecture arch of uart_lpbk is 

	signal uart1_rx_valid : std_logic := '0';
	signal uart1_rd_en    : std_logic := '0';
	signal uart1_rd_data  : std_logic_vector(7 downto 0) := (others => '0');
	signal uart1_tx_ready : std_logic := '0';
	signal uart1_wr_en    : std_logic := '0';
	signal uart1_wr_data  : std_logic_vector(7 downto 0) := x"00";
	
	signal rd_en_dly : std_logic := '0';
	
	
	
	signal tx_fifo_ov, tx_fifo_un, rx_fifo_ov, rx_fifo_un : std_logic := '0';
	
	signal tx_t : std_logic := '0';

begin

	rx_dbg <= rx;
	tx <= tx_t;
	tx_dbg <= tx_t;

	uart_inst : entity work.uart
	generic map(
		CLKRATE  => 50000000,
		BAUDRATE =>   115200,
		DATA_SIZE => 8,
		FIFO_SIZE => 8
	)
	port map(
		clk        => clk_board,
		rx         => rx,
		tx         => tx_t,
		rx_valid   => uart1_rx_valid,
		rx_full    => open,
		rx_rd_en   => uart1_rd_en,
		rx_rd_data => uart1_rd_data,
		rx_fifo_ov => rx_fifo_ov,
		rx_fifo_un => rx_fifo_un,
		tx_ready   => uart1_tx_ready,
		tx_empty   => open,
		tx_wr_en   => uart1_wr_en,
		tx_wr_data => uart1_wr_data,
		tx_fifo_ov => tx_fifo_ov,
		tx_fifo_un => tx_fifo_un
	);
	
	uart1_wr_data <= uart1_rd_data;
	
	process(clk_board)
	begin
		if(rising_edge(clk_board)) then
			
			if(uart1_rx_valid = '1') then
				uart1_rd_en <= '1';
			end if;
			
			if(uart1_rd_en = '1') then
				uart1_rd_en <= '0';
			end if;
			
			rd_en_dly <= uart1_rd_en;
			
			if(rd_en_dly = '1') then
				uart1_wr_en <= '1';
			end if;
			
			if(uart1_wr_en = '1') then
				uart1_wr_en <= '0';
			end if;

			-- if(uart1_tx_ready = '1') then
				-- uart1_wr_en <= '1';
				-- uart1_wr_data <= x"35";
			-- end if;
			
			-- if(uart1_wr_en = '1') then
				-- uart1_wr_en <= '0';
			-- end if;

            if(rd_en_dly = '1' and uart1_rd_data /= x"55") then
                led0 <= '1';
            end if;

			-- if(tx_fifo_un = '1') then
				-- led0 <= '1';
			-- end if;
			
			if(tx_fifo_ov = '1') then
				led1 <= '1';
			end if;
			
			if(rx_fifo_un = '1') then
				led2 <= '1';
			end if;
			
			if(rx_fifo_ov = '1') then
				led3 <= '1';
			end if;
	
		end if;
	end process;
	

	
end arch;