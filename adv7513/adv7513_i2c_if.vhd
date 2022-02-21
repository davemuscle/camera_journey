library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Dave Muscle
--10/25/20

--Controller to send and receive i2c commands to ADV7513 on Cyclone5 Board
--Use with an i2c master that has already been verified for read/writes to the ADV7513

entity adv7513_i2c_if is
	generic(
		HPD_CHECKRATE : integer;
		SIM           : integer
	);
	port(
    	clk   : in std_logic;
		reset : in std_logic; --active high
		
		--controller status
		start      : in  std_logic;
		init_error : out std_logic := '0';
		init_done  : out std_logic := '0';
		init_busy  : out std_logic := '0';
		
		--monitor status
		hpd_detect : out std_logic := '0';

		--i2c driver signals
		cmd       : out std_logic := '0';
		cmd_en    : out std_logic := '0';
		cmd_busy  : in  std_logic;
		ack_error : in  std_logic;
		
		base_addr : out std_logic_vector(7 downto 0) := (others => '0');
		wr_data   : out std_logic_vector(7 downto 0) := (others => '0');
		rd_data   : in  std_logic_vector(7 downto 0)
		
		
        );
end adv7513_i2c_if;

architecture arch of adv7513_i2c_if is 

	type state_type is (idle, fetch, send, busy, check, done, monitor_cmd_setup, monitor_cmd_read);
	signal state : state_type := idle;
	
	signal hpd_cnt : integer range 0 to HPD_CHECKRATE-1 := 0;
	signal hpd_check_go : std_logic := '0';

	signal monitor_plugged_in : std_logic := '0';
	
	signal ack_error_lock : std_logic := '0';

	signal hpd_prev : std_logic := '0';
	
	constant init_wr_seq_len : integer := 13;
	
	type cmd_array_t is array(0 to init_wr_seq_len-1) of std_logic_vector(15 downto 0); 

	-- --[15:8] = base address, [7:0] = byte value
	-- --this needs to infer as a rom
	constant init_wr_seq : cmd_array_t := (
		0  => x"4110", --[6] = 0 for chip power up								
		1  => x"9803", --fixed registers given by AD
		2  => x"9AE0",
		3  => x"9C30",
		4  => x"9D01", 
		5  => x"A2A4",
		6  => x"A3A4",
		7  => x"E0D0",
		8  => x"F900",
		
		--video formatting
		9  => x"1500", --[3:0] = 0 -> 4:4:4 RGB Separate Syncs Input Format
		10 => x"1630", --[7] = 0 -> 4:4:4 output format
			           --[4:3] = 3 -> 8 bit input colors
		11 => x"1702", --[6:5] = 0 -> High sync polarities
			           --[1] = 1 -> 16:9 input aspect ratio
		12 => x"AF06"  --[2] = 1 -> fixed value
					   --[1] = 1 -> HDMI mode
	); --dummy end

	constant HPD_REG : std_logic_vector(7 downto 0) := x"42";
	constant HPD_BIT : integer := 6;
	
	signal cmd_num : integer range 0 to init_wr_seq'length-1 := 0;
	signal cmd_rom_rd : std_logic_vector(15 downto 0) := (others => '0');
	
begin

	--monitor the hot plug detect even after the main initialization is done
	--only check after we reach the count specified by the generic
	process(clk)
	begin
		if(rising_edge(clk)) then
			if(hpd_cnt = HPD_CHECKRATE-1) then
				hpd_cnt <= 0;
				hpd_check_go <= '1';
			else
				hpd_cnt <= hpd_cnt + 1;
				hpd_check_go <= '0';
			end if;
		end if;
	end process;

	GEN_HPD_DETECT_SIM: if SIM = 1 generate
		hpd_detect <= '1'; --monitor is always plugged in for simulations
	end generate GEN_HPD_DETECT_SIM;
	
	GEN_HPD_DETECT_NOSIM: if SIM = 0 generate
		--hot plug detect signal -- used to start the initialization process
		hpd_detect <= monitor_plugged_in;
	end generate GEN_HPD_DETECT_NOSIM;

	--main state machine
	process(clk)
	begin
		if(rising_edge(clk)) then
			
			--16 bit rom holds the base addr and write data for the commands
			--any reads are just hardcoded into the sm
			base_addr <= cmd_rom_rd(15 downto 8);
			wr_data   <= cmd_rom_rd( 7 downto 0);
				
			--lock in the ack error
			if(ack_error = '1') then
				ack_error_lock <= '1';
			end if;
			
			hpd_prev <= monitor_plugged_in;
			--reset the init done signal if the monitor is unplugged
			if(monitor_plugged_in = '0' and hpd_prev = '1') then
				init_done <= '0';
			end if;
			
			--state machine
			if(reset = '1') then
				--reset outputs and internal states
				init_error <= '0';
				init_done <= '0';
				init_busy <= '0';
				cmd <= '0';
				cmd_en <= '0';
				state <= idle;

			else
			
				case state is 
				--idle state
				when idle =>
					--if it's time to check the HPD signal and nothing else is happening, check it
					if(hpd_check_go = '1' and cmd_busy = '0') then
						state <= monitor_cmd_setup;
					end if;
					
					cmd_num <= 0;
					cmd_en <= '0';
					
					init_busy <= '0';
					
					--if the start signal is high, begin the initialization
					if(start = '1') then
						state <= fetch;
						init_done <= '0';
						init_busy <= '1';
					end if;
				
				--fetch the command and address from a ROM
				--single cycle read
				when fetch =>
					--read from ROM
					cmd_rom_rd <= init_wr_seq(cmd_num);
					state <= send;
					
				--the command/address has been setup, throw the enable signal
				when send =>
				
					--wait for the cmd_busy to be low
					if(cmd_busy = '0') then
						--setup the cmd enable
						cmd <= '0'; --0 for writes
						cmd_en <= '1';
						state <= busy;
					end if;
					
				--wait for the i2c driver to grab the command, busy will be high
				when busy =>
				
					--wait for the cmd_busy to be high
					if(cmd_busy = '1') then
						
						--pull the cmd enable low
						cmd_en <= '0';
						state <= check;
						
					end if;
					
				when check =>
				
					--wait for the cmd to finish, ie: cmd_busy low
					if(cmd_busy = '0') then
						
						if(ack_error_lock = '1') then
							ack_error_lock <= '0';
							init_error <= '1';
						end if;
						
						if(cmd_num = init_wr_seq'length-1) then
							cmd_num <= 0;
							state <= done;
						else
							cmd_num <= cmd_num + 1;
							state <= fetch;
						end if;
						
					end if;
					
				when done =>
					state <= idle;
					init_done <= '1';

				--setup the command for reading the HPD signal
				when monitor_cmd_setup =>
				
					--read register of ADV7513 that has HPD signal
					base_addr <= HPD_REG;
					cmd <= '1'; --cmd = 1 for a read
					cmd_en <= '1';
					
					--when the i2c driver has read the command, throw the enable off
					if(cmd_busy = '1') then
						cmd_en <= '0';
						state <= monitor_cmd_read;
					end if;
					
				--wait for the monitor command to finish and read the HPD signal
				when monitor_cmd_read =>
				
					--wait for the cmd_busy to be low
					if(cmd_busy = '0') then
						monitor_plugged_in <= rd_data(HPD_BIT); --0 = no monitor, 1 = monitor plugged in
						state <= idle;
					end if;
					
				when others => end case;
			
			end if;
		
		end if;
	end process;

	
end arch;