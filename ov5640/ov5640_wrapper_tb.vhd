library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.math_real.all;

use work.uart_debugger_pkg.all;

entity ov5640_wrapper_tb is 

end ov5640_wrapper_tb;

use work.uart_debugger_pkg.all;

architecture test of ov5640_wrapper_tb is

	signal clk  : std_logic := '0';
	signal clk_count : integer := 0;
	
    signal cam_sda, cam_scl : std_logic := '1';
	
    signal udb_mm_master : udb_master := udb_master_init;
    signal udb_mm_slave  : udb_slave := udb_slave_init;
    
begin

	
    wrapper_inst : entity work.ov5640_wrapper
	generic map(
		I2C_CLK_DIV => 4,
        CLK_DIV_1ms => 2,
        REGFILE_SIZE => x"0008",
        SIM => true
	)
	port map(
    	clk => clk,

        udb_mm_i => udb_mm_master,
        udb_mm_o => udb_mm_slave,

		cam_sda => cam_sda,
        cam_scl => cam_scl,
        
        cam_xclk => open,
        cam_reset => open,
        cam_pwdn => open

	);

	clk_stim : process
	begin
		clk <= '0';
		wait for 10 ns;
		clk <= '1';
		wait for 10 ns;
	end process;
	
    process(clk)
    begin
       if(rising_edge(clk)) then
        clk_count <= clk_count + 1;
        
        if(udb_mm_slave.wr_ack = '1') then
            udb_mm_master.wr_req <= '0';
        end if;
        
            if(clk_count = 10000) then
                udb_mm_master.wr_req <= '1';
                udb_mm_master.addr <= x"0002";
                udb_mm_master.wr_data <= x"005555AA";
            end if;
        
            if(clk_count = 11000) then
                udb_mm_master.wr_req <= '1';
                udb_mm_master.addr <= x"0003";
                udb_mm_master.wr_data <= x"00373737";
            end if;
        
            if(clk_count = 12000) then
                udb_mm_master.wr_req <= '1';
                udb_mm_master.addr <= x"0004";
                udb_mm_master.wr_data <= x"00123455";
            end if;
        
            if(clk_count = 12020) then
                udb_mm_master.wr_req <= '1';
                udb_mm_master.addr <= x"0004";
                udb_mm_master.wr_data <= x"005678AA";
            end if;        
        
             if(clk_count = 12040) then
                udb_mm_master.wr_req <= '1';
                udb_mm_master.addr <= x"0004";
                udb_mm_master.wr_data <= x"009ABC55";
            end if;           
        
            if(clk_count = 12060) then
                udb_mm_master.wr_req <= '1';
                udb_mm_master.addr <= x"0001";
                udb_mm_master.wr_data <= (others => '0');
            end if;
        
            if(clk_count = 14000) then
                udb_mm_master.wr_req <= '1';
                udb_mm_master.addr <= x"0004";
                udb_mm_master.wr_data <= x"00FACE12";
            end if;
        
            if(clk_count = 14020) then
                udb_mm_master.wr_req <= '1';
                udb_mm_master.addr <= x"0004";
                udb_mm_master.wr_data <= x"00BEEF34";
            end if;        
        
             if(clk_count = 14040) then
                udb_mm_master.wr_req <= '1';
                udb_mm_master.addr <= x"0004";
                udb_mm_master.wr_data <= x"00ACED56";
            end if;           
        
            if(clk_count = 14060) then
                udb_mm_master.wr_req <= '1';
                udb_mm_master.addr <= x"0001";
                udb_mm_master.wr_data <= (others => '0');
            end if;
   
            if(clk_count = 16000) then
                udb_mm_master.wr_req <= '1';
                udb_mm_master.addr <= x"0000";
                udb_mm_master.wr_data <= (others => '0');
            end if;
   
        
       end if;
    end process;
    
	--pullup resistors, never drive to 1
	--scl <= 'Z' when scl_t = '0' else '0';
	--sda <= 'Z' when sda_t = '0' else '0';

	--scl_i <= scl_o when scl_t = '1' else '1';
	--sda_i <= sda_o when sda_t = '1' else '1';
	
	

    process
    begin
  
	wait;
    
    end process;
    
end test;