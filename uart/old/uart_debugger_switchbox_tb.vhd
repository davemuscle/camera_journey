library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.math_real.all;

use work.uart_debugger_pkg.all;

entity uart_debugger_switchbox_tb is 

end uart_debugger_switchbox_tb;


architecture test of uart_debugger_switchbox_tb is
	
	signal clk       : std_logic := '0';
	signal uart_en   : std_logic := '0';
	signal clk_count : integer   := 0;
	
	signal udb_master_data : udb_master := udb_master_init;
	signal udb_slave_data : udb_slave := udb_slave_init;
	
	constant clk_wait_cnt : integer := 60;


begin
    
	uart_sb_inst : entity work.uart_debugger_switchbox
    generic map(
        NUM_SLAVES => 2,
        NUM_SLAVES_LOG2 => 1
    
    )
	port map(

		udb_mm_i   => udb_master_data,
		udb_mm_o   => udb_slave_data,
        
        udb_sb_addr_o => open,
        udb_sb_data_o => open,
        udb_wr_reqs_o => open,
        udb_rd_reqs_o => open,
        
        udb_sb_data_i => (others => '0'),
        udb_wr_acks_i => (others => '0'),
        udb_rd_acks_i => (others => '0')
        
        
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

            --page zero
            udb_master_data.addr <= x"8000";
            udb_master_data.wr_req <= '1';
            

		end if;
	end process;

	
    process
    begin
		wait;
    end process;
    
end test;