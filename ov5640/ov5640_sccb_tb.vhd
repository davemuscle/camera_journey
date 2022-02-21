library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.math_real.all;

entity ov5640_sccb_tb is 

end ov5640_sccb_tb;

architecture test of ov5640_sccb_tb is

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
	
begin

	
    sccb_inst : entity work.ov5640_sccb
	generic map(
		CLK_DIV_4x => 4,
		CLK_DIV_1ms => 2
	)
	port map(
    	clk => bclk_2x,
		reset => '0',
		pwdn_reset_start => start,
		cmd => cmd,
		cmd_en => cmd_en,

		dev_addr => dev_addr,
		base_addr => base_addr,
		
		wr_data => wr_data,
		rd_data => rd_data,

		cmd_busy  => cmd_busy,

		pwr_up_done => open,
		device_error => open,
		init_done => open,

		sda_o => sda_o,
		sda_i => sda_i,
		sda_t => sda_t,
		scl_o => scl_o,
		scl_i => scl_i,
		scl_t => scl_t

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
	
	
	--testbench stimulus
	process(bclk_2x)
	begin
		if(rising_edge(bclk_2x)) then

			clk_count <= clk_count + 1;
				
			if(clk_count = 20) then
				start <= '1';
			else
				start <= '0';
			end if;
			
			if(clk_count > 1000 and cmd_busy = '0') then
				cmd_en <= '1';
			else
				cmd_en <= '0';
			end if;

			cmd <= '1';
			dev_addr <= "0111100";
			base_addr <= x"5555";
			wr_data <= x"AA";

			
			
			
		end if;
	end process;

    process
    begin
  
	wait;
    
    end process;
    
end test;