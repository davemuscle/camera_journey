library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.math_real.all;

entity ov5640_controller_tb is 

end ov5640_controller_tb;

architecture test of ov5640_controller_tb is

	signal bclk_2x : std_logic := '0';
	signal clk_count : integer := 0;
	
	signal cmd : std_logic := '0';
	signal cmd_en : std_logic := '0';
	signal rnw : std_logic := '0';
	signal dev_addr : std_logic_vector(6 downto 0) := (others => '0');
	signal wr_data, rd_data : std_logic_vector(7 downto 0) := (others => '0');
	signal base_addr : std_Logic_vector(15 downto 0) := (others => '0');
	signal cmd_done, cmd_busy, ack_error : std_logic := '0';
	
	signal scl_o, scl_i, scl_t, sda_o, sda_i, sda_t : std_logic := '0';

	signal scl, sda : std_logic := '0';
	signal dly_test : std_logic_vector(6 downto 0) := (others => '0');
	
	signal start : std_logic := '0';
	
	signal cmd_list : integer := 0;
	
	signal pwr_up_done : std_logic := '0';
	signal pwr_up_start : std_logic := '0';
	signal cmd_en_dly : std_logic := '0';
	signal cmd_busy_vec : std_logic_vector(3 downto 0) := (others => '0');
    
    signal dbg_cmd_wr, dbg_cmd_rd : std_logic := '0';
        
begin

	
    ctrl_inst : entity work.ov5640_controller
	generic map(
		CLK_DIV_10ms => 4
	)
	port map(
    	clk => bclk_2x,

		start => start,
        
        dbg_cmd_sel => '0',
        dbg_fifo_en => open,
        dbg_fifo_addr => (others => '0'),
        dbg_fifo_wr_data => (others => '0'),
        dbg_fifo_empty => '0',
        
        dbg_cmd_rd => '0',
        dbg_cmd_wr => '0',
        dbg_cmd_addr => (others => '0'),
        dbg_cmd_wr_data => (others => '0'),
        dbg_cmd_rd_data => open,
        dbg_cmd_wr_busy => open,
        dbg_cmd_rd_busy => open,
        
		force_id_read => '0',
		pwr_up_start => pwr_up_start,
		pwr_up_done => pwr_up_done,
		
		device_id_good => open,
		init_done => open,
		
		cmd => cmd,
		cmd_en => cmd_en,
		cmd_busy  => cmd_busy,
        
		base_addr => base_addr,
		
		wr_data => wr_data,
		rd_data => rd_data
	);

	clk_stim : process
	begin
		bclk_2x <= '0';
		wait for 10 ns;
		bclk_2x <= '1';
		wait for 10 ns;
	end process;
	
	--pullup resistors, never drive to 1
	scl <= 'Z' when scl_t = '0' else '0';
	sda <= 'Z' when sda_t = '0' else '0';

	scl_i <= scl_o when scl_t = '1' else '1';
	sda_i <= sda_o when sda_t = '1' else '1';
	
	cmd_busy <= cmd_busy_vec(3);
	
	
	--testbench stimulus
	process(bclk_2x)
	begin
		if(rising_edge(bclk_2x)) then

			clk_count <= clk_count + 1;
				
			if(clk_count = 20) then
				pwr_up_done <= '1';		
			end if;
			
			cmd_busy_vec <= cmd_busy_vec(2 downto 0) & '0';
			
			cmd_en_dly <= cmd_en;
			if(cmd_en_dly = '0' and cmd_en = '1') then
				cmd_busy_vec <= (others => '1');
			end if;
			
			if(cmd = '1' and base_addr = x"300A") then
				rd_data <= x"56";
			end if;
			
			if(cmd = '1' and base_addr = x"300B") then
				rd_data <= x"40";
			end if;
			
		end if;
	end process;

    process
    begin
  
	wait;
    
    end process;
    
end test;