library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.math_real.all;

entity uart_tb is 

end uart_tb;

architecture test of uart_tb is
	
	signal clk : std_logic := '0';
	signal uart_en : std_logic := '0';
	signal clk_count : integer := 0;
	
	signal uart_wire1, uart_wire2 : std_logic := '0';
	
	signal uart1_rx_valid : std_logic := '0';
	signal uart1_rd_en    : std_logic := '0';
	signal uart1_rd_data  : std_logic_vector(7 downto 0) := (others => '0');
	signal uart1_tx_ready : std_logic := '0';
	signal uart1_wr_en    : std_logic := '0';
	signal uart1_wr_data  : std_logic_vector(7 downto 0) := x"55";

	signal uart2_rx_valid : std_logic := '0';
	signal uart2_rd_en    : std_logic := '0';
	signal uart2_rd_data  : std_logic_vector(7 downto 0) := (others => '0');
	signal uart2_tx_ready : std_logic := '0';
	signal uart2_wr_en    : std_logic := '0';
	signal uart2_wr_data  : std_logic_vector(7 downto 0) := x"37";

begin

	--design, UART1 sends to UART2 0x55 and 0xAA alternating
	--        UART2 sends to UART1 0x37 and 0x73 alternating
	
	uart1_inst : entity work.uart
	generic map(
		CLKRATE  => 50000000,
		BAUDRATE =>   115200,
		DATA_SIZE => 8,
		FIFO_SIZE => 8
	)
	port map(
		clk => clk,
		rx    => uart_wire1,
		tx    => uart_wire2,
		rx_valid   => uart1_rx_valid,
		rx_full    => open,
		rx_rd_en   => uart1_rd_en,
		rx_rd_data => uart1_rd_data,
		rx_fifo_ov => open,
		rx_fifo_un => open,
		tx_ready   => uart1_tx_ready,
		tx_empty   => open,
		tx_wr_en   => uart1_wr_en,
		tx_wr_data => uart1_wr_data,
		tx_fifo_ov => open,
		tx_fifo_un => open
	);
	
	uart2_inst : entity work.uart
	generic map(
		CLKRATE  => 50000000,
		BAUDRATE =>   115200,
		DATA_SIZE => 8,
		FIFO_SIZE => 8
	)
	port map(
		clk => clk,
		rx => uart_wire2,
		tx => uart_wire1,
		rx_valid   => uart2_rx_valid,
		rx_full    => open,
		rx_rd_en   => uart2_rd_en,
		rx_rd_data => uart2_rd_data,
		rx_fifo_ov => open,
		rx_fifo_un => open,
		tx_ready   => uart2_tx_ready,
		tx_empty   => open,
		tx_wr_en   => uart2_wr_en,
		tx_wr_data => uart2_wr_data,
		tx_fifo_ov => open,
		tx_fifo_un => open
	);
	
	--50 MHz clock
	clk_stim: process
	begin
		wait for 20 ns;
		clk <= not clk;
		wait for 20 ns;
		clk <= not clk;
	end process;
	

	--tb stim
	process(clk)
	begin
		if(rising_edge(clk)) then
		
			if(clk_count = 10) then
				clk_count <= 10;
				uart_en <= '1';
			else
				clk_count <= clk_count + 1;
				uart_en <= '0';
			end if;
		
			if(uart_en = '1') then
			
				-- --write to uart1
				-- if(uart1_wr_en = '1') then
					
					-- if(uart1_wr_data = x"55") then
						-- uart1_wr_data <= x"AA";
					-- else
						-- uart1_wr_data <= x"55";
					-- end if;

				-- end if;
			
				-- --write to uart2
				-- if(uart2_wr_en = '1') then
					
					-- if(uart2_wr_data = x"37") then
						-- uart2_wr_data <= x"73";
					-- else
						-- uart2_wr_data <= x"37";
					-- end if;
				
				-- end if;
			
				if(uart1_tx_ready = '1') then
					uart1_wr_en <= '1';
					uart1_wr_data <= x"55";
					
				end if;
			
				if(uart1_wr_en = '1') then
					uart1_wr_en <= '0';
				end if;
			
				if(uart2_rx_valid = '1') then
					uart2_rd_en <= '1';
				end if;
				
				if(uart2_rd_en = '1') then
					uart2_rd_en <= '0';
				end if;
			
			end if;
		
		
		
		end if;
	end process;

	-- uart1_wr_en <= uart1_tx_ready and uart_en;
	-- uart2_wr_en <= uart2_tx_ready and uart_en;
	-- uart1_rd_en <= uart1_rx_valid and uart_en;
	-- uart2_rd_en <= uart2_rx_valid and uart_en;
	
    process
    begin
		wait;
    end process;
    
end test;