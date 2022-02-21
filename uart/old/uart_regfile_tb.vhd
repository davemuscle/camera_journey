library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.math_real.all;

use work.uart_debugger_pkg.all;

entity uart_regfile_tb is 

end uart_regfile_tb;


architecture test of uart_regfile_tb is
	
	signal clk       : std_logic := '0';
	signal uart_en   : std_logic := '0';
	signal clk_count : integer   := 0;
	
	signal udb_master_data : udb_master := udb_master_init;
	signal udb_slave_data : udb_slave := udb_slave_init;
	
	constant clk_wait_cnt : integer := 60;


begin
    
	uart_rf_inst : entity work.uart_regfile
    generic map(
        REGFILE_ADDR_SIZE => x"000004",
        USE_BRAM          => FALSE,
        REG_WIDTH         => 32
    
    )
	port map(
		clk        => clk,
		udb_mm_i   => udb_master_data,
		udb_mm_o   => udb_slave_data,
        
        user_logic_wr_en => '0',
        user_logic_rd_en => '0',
        user_logic_addr => (others => '0'),
        user_logic_wr_data => (others => '0'),
        user_logic_rd_data => open,
        user_logic_tick => open
        
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

            case clk_count is
            when 10 => 
                udb_master_data.wr_data <= x"55AA55AA";
                udb_master_data.addr    <= x"000001";
                udb_master_data.wr_req  <= '1';
            when 20 =>
                udb_master_data.wr_req <= '0';
                udb_master_data.rd_req <= '1';
            when 30 =>
                udb_master_data.rd_req <= '0';
            when others => end case;

		end if;
	end process;

	
    process
    begin
		wait;
    end process;
    
end test;