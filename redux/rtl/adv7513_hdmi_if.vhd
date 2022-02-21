library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Structural controller that initializes the ADV7513 for the DE10-Nano board
--When a monitor is plugged in, the chip is initialized
--After initialized, you can send VGA signals to the ADV7513 and get a screen output

--Potential improvement could be using the interrupt pin

entity adv7513_hdmi_if is
	generic(
		DEV_ADDR      : std_logic_vector(6 downto 0) := "0111001";
		HPD_CHECKRATE : integer := 50000000; --50 MHz input clock for 1s checkrate
		I2C_CLK_DIV   : integer := 500       --50 MHz / 500 for 100 kHz i2c clock
		);
	port(
    	clk : in std_logic;

		--i2c pins
		sda : inout std_logic;
		scl : inout std_logic;
		
		--status signals
		hpd_detect_o : out std_logic;
		init_done_o : out std_logic;
		init_busy_o : out std_logic
        );
end adv7513_hdmi_if;

architecture str of adv7513_hdmi_if is 

	signal scl_o, scl_i, scl_t, sda_o, sda_i, sda_t : std_logic := '0';

	signal cmd, cmd_en : std_logic := '0';
	signal wr_data, rd_data, base_addr : std_logic_vector(7 downto 0) := (others => '0');
	
	signal cmd_busy : std_logic;
	signal cmd_done : std_logic;
	
	signal start, init_done, init_busy, hpd_detect : std_logic := '0';

	
begin
	
	hpd_detect_o <= hpd_detect;
	init_done_o  <= init_done;
	init_busy_o  <= init_busy;
	
	--initialize the ADV7513 if a monitor is plugged in, the core isn't busy, and the chip has been reset
	process(init_busy, init_done, hpd_detect)
	begin
		if(init_busy = '0' and init_done = '0' and hpd_detect = '1') then
			start <= '1';
		else
			start <= '0';
		end if;
	end process;
	
	--controller to send i2c commands to adv7513
    adv7513_i2c_if_inst : entity work.adv7513_i2c_if
	generic map(
		HPD_CHECKRATE => HPD_CHECKRATE,
		SIM => 0
	)
	port map(
    	clk   => clk,
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
		ack_error => '0',
		
		base_addr => base_addr,
		wr_data   => wr_data,
		rd_data   => rd_data

	);
	
	--i2c master, tested on ADV7513 for reads and writes
    i2c_driver_inst : entity work.i2c_driver
	generic map(
		CLK_DIV => I2C_CLK_DIV
	)
	port map(
    	clk   => clk,
		reset => '0',
		
		cmd    => cmd,
		cmd_en => cmd_en,

		dev_addr  => DEV_ADDR,
		base_addr => base_addr,
		
		wr_data => wr_data,
		rd_data => rd_data,

		cmd_busy  => cmd_busy,
		ack_error => open,

		sda_o => sda_o,
		sda_i => sda_i,
		sda_t => sda_t,
		scl_o => scl_o,
		scl_i => scl_i,
		scl_t => scl_t

	);
	
	--i2c tristate buffer
	scl <= 'Z' when scl_t = '0' else scl_o;
	sda <= 'Z' when sda_t = '0' else sda_o;
	scl_i <= scl;
	sda_i <= sda;

	
end str;