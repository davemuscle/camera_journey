library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.math_real.all;


entity uart_debugger_tb is 

end uart_debugger_tb;


architecture test of uart_debugger_tb is
	
	signal clk       : std_logic := '0';
	signal uart_en   : std_logic := '0';
	signal clk_count : integer   := 0;
	
	signal uart_wire1, uart_wire2 : std_logic := '0';

	signal uart2_rx_valid : std_logic := '0';
	signal uart2_rd_en    : std_logic := '0';
	signal uart2_rd_data  : std_logic_vector(7 downto 0) := (others => '0');
	signal uart2_tx_ready : std_logic := '0';
	signal uart2_wr_en    : std_logic := '0';
	signal uart2_wr_data  : std_logic_vector(7 downto 0) := x"00";

	constant clk_wait_cnt : integer := 60;
	
	signal xfer_1 : std_logic_vector(63 downto 0) := (others => '0');
    
    signal rm_wr_en, rm_rd_en, rm_rd_valid : std_logic := '0';
    signal rm_addr : std_logic_vector(15 downto 0) := (others => '0');
    signal rm_wr_data, rm_rd_data : std_logic_vector(31 downto 0) := (others => '0');
    
    signal scratchpad : std_logic_vector(31 downto 0) := x"735537AA";
    signal reg : std_logic_vector(7 downto 0) := (others => '0');
    signal id : std_logic_vector(31 downto 0) := x"BEBE1234";
    
begin
    
	process(clk)
	begin
		if(rising_edge(clk)) then
			
            --Write to registers
            if(rm_wr_en = '1') then
            
                if(rm_addr = x"0000") then
                    scratchpad <= rm_wr_data;
                elsif(rm_addr = x"0002") then
                    reg <= rm_wr_data(7 downto 0);
                end if;
            
            
            end if;
            
            rm_rd_valid <= '0';
            
            if(rm_rd_en = '1') then
                
                if(rm_addr = x"0000") then
                    rm_rd_data <= scratchpad;
                elsif(rm_addr = x"0001") then
                    rm_rd_data <= id;
                else
                    rm_rd_data <= x"000000" & reg;
                end if;
                
                rm_rd_valid <= '1';

            end if;
    
		end if;
	end process;    

    
	uart_db_inst : entity work.uart_debugger
    generic map(
		CLKRATE  => 50000000,
		BAUDRATE => 50000000/8,
		DATA_SIZE => 8,
		FIFO_SIZE => 16
    )
	port map(
		clk        => clk,
        
        rx => uart_wire1,
        tx => uart_wire2,
        
        uart_fifo_status => open,
        
		rm_wr_en => rm_wr_en,
        rm_rd_en => rm_rd_en,
        rm_rd_valid => rm_rd_valid,
        rm_addr => rm_addr,
        rm_wr_data => rm_wr_data,
        rm_rd_data => rm_rd_data
	);
		
	uart2_inst : entity work.uart
	generic map(
		CLKRATE  => 50000000,
		BAUDRATE => 50000000/8,
		DATA_SIZE => 8,
		FIFO_SIZE => 16
	)
	port map(
		clk => clk,
		rx => uart_wire2,
		tx => uart_wire1,
		rx_valid   => uart2_rx_valid,
		rx_full    => open,
		rx_rd_en   => uart2_rx_valid,
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
		
			clk_count <= clk_count + 1;
			if(clk_count = 2**31 - 1) then
				clk_count <= 0;
			end if;

			uart2_wr_en <= '0';
			uart2_wr_data <= (others => '0');

			case clk_count is 

            --Read Address 1 (read only ID)
			when 1*clk_wait_cnt =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"7E";
			when 1*clk_wait_cnt + 1 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"38";
			when 1*clk_wait_cnt + 2 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";
			when 1*clk_wait_cnt + 3 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"01";
			when 1*clk_wait_cnt + 4 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";
			when 1*clk_wait_cnt + 5 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";
			when 1*clk_wait_cnt + 6 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";
			when 1*clk_wait_cnt + 7 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";

            --Read 0x0
			when 20*clk_wait_cnt =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"7E";
			when 20*clk_wait_cnt + 1 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"38";
			when 20*clk_wait_cnt + 2 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";
			when 20*clk_wait_cnt + 3 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";
			when 20*clk_wait_cnt + 4 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";
			when 20*clk_wait_cnt + 5 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";
			when 20*clk_wait_cnt + 6 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";
			when 20*clk_wait_cnt + 7 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";

            --Write 0x55AA7E55 to 0x0
			when 40*clk_wait_cnt =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"7E";
			when 40*clk_wait_cnt + 1 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"37";
			when 40*clk_wait_cnt + 2 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";
			when 40*clk_wait_cnt + 3 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";
			when 40*clk_wait_cnt + 4 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"55";
			when 40*clk_wait_cnt + 5 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"AA";
			when 40*clk_wait_cnt + 6 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"7D";
			when 40*clk_wait_cnt + 7 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"5E";
			when 40*clk_wait_cnt + 8 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"55";

            --Read 0x0
			when 60*clk_wait_cnt =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"7E";
			when 60*clk_wait_cnt + 1 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"38";
			when 60*clk_wait_cnt + 2 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";
			when 60*clk_wait_cnt + 3 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";
			when 60*clk_wait_cnt + 4 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";
			when 60*clk_wait_cnt + 5 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";
			when 60*clk_wait_cnt + 6 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";
			when 60*clk_wait_cnt + 7 =>
				uart2_wr_en <= '1';
				uart2_wr_data <= x"00";


			when others => end case;
		
		end if;
	end process;

	
    process
    begin
		wait;
    end process;
    
end test;