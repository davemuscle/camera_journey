library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.math_real.all;

entity adv7513_i2c_if_tb is 

end adv7513_i2c_if_tb;

architecture test of adv7513_i2c_if_tb is

	signal clk : std_logic := '0';
	signal clk_count : integer := 0;
	
	signal cmd : std_logic := '0';
	signal cmd_en : std_logic := '0';
	signal rnw : std_logic := '0';
	signal dev_addr : std_logic_vector(6 downto 0) := (others => '0');
	signal base_addr, wr_data, rd_data : std_logic_vector(7 downto 0) := (others => '0');
	signal cmd_done, cmd_busy, ack_error : std_logic := '0';
	signal reset : std_logic := '0';
	signal scl_o, scl_i, scl_t, sda_o, sda_i, sda_t : std_logic := '0';
	signal hpd_detect : std_logic := '0';
	
	signal scl, sda : std_logic := '0';
	signal dly_test : std_logic_vector(6 downto 0) := (others => '0');
	
	signal start : std_logic := '0';
	
	signal cmd_busy_cnt : integer range 0 to 15 := 0;
	
	signal init_done, init_busy : std_logic := '0';
	
	
	
begin

	reset <= not hpd_detect;
	
    adv7513_i2c_if_inst : entity work.adv7513_i2c_if
	generic map(
		HPD_CHECKRATE => 200,
		SIM => 1
	)
	port map(
    	clk => clk,
		reset => '0',
		
		--controller status
		start      => start,
		init_error => open,
		init_done  => init_done,
		init_busy  => init_busy,
		hpd_detect => hpd_detect,

		--i2c driver signals
		cmd       => cmd,
		cmd_en    => cmd_en,
		cmd_busy  => cmd_busy,
		ack_error => ack_error,
		
		base_addr => base_addr,
		wr_data   => wr_data,
		rd_data   => rd_data

	);


    i2c_driver_inst : entity work.i2c_driver
	generic map(
		CLK_DIV => 4
	)
	port map(
    	clk => clk,
		reset => '0',
		
		cmd => cmd,
		cmd_en => cmd_en,

		dev_addr => dev_addr,
		base_addr => base_addr,
		
		wr_data => wr_data,
		rd_data => rd_data,

		cmd_busy  => cmd_busy,
		ack_error => ack_error,

		sda_o => sda_o,
		sda_i => sda_i,
		sda_t => sda_t,
		scl_o => scl_o,
		scl_i => scl_i,
		scl_t => scl_t

	);

	dev_addr <= "0111001";

	--pullup resistors, never drive to 1
	scl <= 'Z' when scl_t = '0' else '0';
	sda <= 'Z' when sda_t = '0' else '0';

	scl_i <= scl_o when scl_t = '1' else '1';
	sda_i <= sda_o when sda_t = '1' else '1';

	clk_stim : process
	begin
		clk <= '0';
		wait for 10 ns;
		clk <= '1';
		wait for 10 ns;
	end process;
	
	
	--testbench stimulus
	process(clk)
	begin
		if(rising_edge(clk)) then

			clk_count <= clk_count + 1;
			if(clk_count = 20) then
				rnw <= '1';
			
			end if;
			
			if(rnw = '1') then
				if(init_done = '0' and init_busy = '0') then
					start <= '1';
				else
					start <= '0';
				end if;

			end if;
		end if;
	end process;

    process
    begin
  
	wait;
    
    end process;
    
end test;