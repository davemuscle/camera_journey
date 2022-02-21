library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Can read or write single bytes to a slave device
--Single Master

--CMD = 0, Write to one control register:
--   Start signal
--   Slave address byte (R/W bit = low)
--   Base address byte
--   Data byte to base address
--   Stop signal

--CMD = 1, Read from one control register:
--   Start signal
--   Slave address byte (R/W bit = low)
--   Base address byte
--   Start signal
--   Slave address byte (R/W bit = high)
--   Data byte from base address
--   Stop signal

entity i2c_driver is
	generic(
		CLK_DIV : integer
	);
	port(
		--double the desired scl clock
		--data should be on this clock domain
    	clk : in std_logic; --double the desired scl clock
		
		--reset the state machine, active high
		reset : in std_logic;

		--i2c ports
		cmd    : in std_logic; -- only two commands for now
		cmd_en : in std_logic; --1 = read the new cmd, data and execute

		dev_addr  : in std_logic_vector(6 downto 0); --physical device address
		base_addr : in std_logic_vector(7 downto 0); --base address within device to pick rd or wr
		
		--write data
		wr_data : in std_logic_vector(7 downto 0);
		
		--read data
		rd_data : out std_logic_vector(7 downto 0) := (others => '0');
		
		--status signals, ack_error is a pulse
		cmd_busy  : out std_logic := '0';
		ack_error : out std_logic := '0';
		
		--i2c phy pins
		sda_o : out std_logic := '0';
		sda_i : in  std_logic;
		sda_t : out std_logic := '0';
		scl_o : out std_logic := '0';
		scl_i : in  std_logic;
		scl_t : out std_logic := '0'
	);
end i2c_driver;

architecture arch of i2c_driver is 
	
	type state_type is (idle, 
						start,
						load_byte,
							send_byte_0,
							send_byte_1,
							send_byte_2,
							send_byte_3,
							send_byte_4,
							read_byte_0,
							read_byte_1,
							read_byte_2,
							read_byte_3,
							read_byte_4,
						read_byte,
						stop, stop_post,
						done,
						wait_for_released_sda
						);
	signal sm_state : state_type := idle;
	
	type cmd_state_type is (send_dev_addr,
							send_base_addr,
							send_data_byte,
							read_data_byte);
							
	signal cmd_state : cmd_state_type := send_dev_addr;
	
	signal cmd_locked : std_logic := '0';
	signal cmd_reg : std_logic := '0';
	signal dev_addr_reg : std_logic_vector(6 downto 0) := (others => '0');
	signal base_addr_reg, wr_data_reg : std_logic_vector(7 downto 0) := (others => '0');
	
	signal byte2push : std_logic_vector(7 downto 0) := (others => '0');
	signal push2byte : std_logic_vector(7 downto 0) := (others => '0');
	
	signal start_sda_done : std_logic := '0';
	signal stop_scl_done : std_logic := '0';
	
	signal send_byte_sent : std_logic := '0';
	signal send_byte_cnt : integer range 0 to 7 := 0;
	
	signal ready2read, activeread : std_logic := '0';
	
	signal sda_released : std_logic := '0';
	
	signal tick_cnt : integer range 0 to CLK_DIV-1 := 0;
	signal tick : std_logic := '0';
	
begin

	--lock these to zero
	--when the tristate enable is high, this is how the i2c lines are pulled to zero
	--otherwise, when the enable is low, the i2c lines are released
	sda_o <= '0';
	scl_o <= '0';
	
	cmd_busy <= cmd_locked;
	
	--generate slow timing
	process(clk)
	begin
		if(rising_edge(clk)) then
			
			--pulse the timing tick for one cycle of the input clock
			if(tick_cnt = CLK_DIV-1) then
				tick <= '1';
				tick_cnt <= 0;
			else
				tick <= '0';
				tick_cnt <= tick_cnt + 1;
			end if;
		end if;
	end process;
	
	--main state machine
	process(clk)
	begin
		if(rising_edge(clk)) then
		

			ack_error <= '0';
			rd_data <= push2byte;
		
			if(tick = '1') then
			

			
			if(reset = '1') then
				sm_state <= idle;
			else
				case sm_state is 
				--idle state, (default), waiting
				when idle =>
				
					--check if a command is ready
					if(cmd_en = '1') then
						--register in the good stuff
						cmd_reg <= cmd;
						dev_addr_reg <= dev_addr;
						base_addr_reg <= base_addr;
						wr_data_reg <= wr_data;
						cmd_locked <= '1';
					end if;
				
					--check if the bus is available
					if(scl_i = '1' and sda_i = '1' and cmd_locked = '1') then

						--transition to start state
						sm_state <= start;						
					end if;
					
				--send the start bit
				when start =>
					
					--if we're in this state, then the bus is ours
					--grab the bus by enabling the tristate and setting to zero	
					if(start_sda_done = '0') then
						--pull sda low first
						sda_t <= '1';
						start_sda_done <= '1';
					else
						--pull scl low second
						scl_t <= '1';
						start_sda_done <= '0';
						
						--transition into next state, no matter which command we send the dev addr first
						cmd_state <= send_dev_addr;
						sm_state <= load_byte;
					end if;

					
				when load_byte =>
					
					--pull clock line low
					--if coming out of the start state this is redundant
					--if coming out of a previous loadbyte, this is necessary
					scl_t <= '1';

					--decode the cmd state to determine what to load into the shift reg
					--this should synth to a nice mux
					case cmd_state is
					when send_dev_addr =>
						--load the device address and the rnw signal into a shift reg
						if(cmd_reg = '1' and ready2read = '1') then
							byte2push <= dev_addr_reg & '1';
						else
							byte2push <= dev_addr_reg & '0';
						end if;
						sm_state <= send_byte_0;
						
					when send_base_addr =>
						--load the base address
						byte2push <= base_addr_reg;
						sm_state <= send_byte_0;
						
					when send_data_byte =>
						--load the data byte
						byte2push <= wr_data_reg;
						sm_state <= send_byte_0;
						
					when read_data_byte =>
						
						--release data line, this will send a NACK to the slave at the end of the byte
						sda_t <= '0';
						sda_released <= '1';
						
						--release the data line before going into the state
						if(sda_released = '0') then
							sm_state <= send_byte_0;
							sda_released <= '0';
						end if;
					when others => end case;
					
				--send a bit from the data byte
				when send_byte_0 =>
	
	
					if(activeread = '0') then
						--shift the dev addr reg left
						byte2push <= byte2push(byte2push'length-2 downto 0) & '0';
						
						--send the bit to the sda line
						--logical not because for setting the line to 1 we disable the tristate
						sda_t <= not byte2push(byte2push'length-1);
					
					else
						--shift in the data msb first
						push2byte <= push2byte(push2byte'length-2 downto 0) & sda_i;
						
					
					end if;
					
					--count how many bits we've sent
					if(send_byte_cnt = 7) then 
						send_byte_cnt <= 0;
						send_byte_sent <= '1';
					else
						send_byte_cnt <= send_byte_cnt + 1;
						send_byte_sent <= '0';
					end if;
					
					sm_state <= send_byte_1;
					
					
				when send_byte_1 =>
				
					--release the clock line
					scl_t <= '0';
					
					sm_state <= send_byte_2;
				
				when send_byte_2 =>
				
					--check if the slave is holding the clock line low
					if(scl_i = '1') then
						--if the line is released (1), then pull it low
						scl_t <= '1';
						if(send_byte_sent = '1') then
							sm_state <= send_byte_3;
						else
							sm_state <= send_byte_0;
						end if;
					end if;
					
				when send_byte_3 =>
				
					--release the data line for the ack on the next clock
					sda_t <= '0';
					sm_state <= send_byte_4;
					
				when send_byte_4 =>
						--check if the line is low for the ack
						if(sda_i = '1') then
							--pulse the ack error for just a clock cycle
							ack_error <= '1';
						end if;
						
						--release the clock line for the ack
						scl_t <= '0';
						
						--at this point, both the clock line and the data line are released

						--decode the cmd_state to determine where to go next
						case cmd_state is 		
						when send_dev_addr =>
							--if we just sent the device address, check if we are reading or writing
							if(cmd_reg = '0') then
								--if writing, send the base address
								cmd_state <= send_base_addr;
								sm_state <= load_byte;
							else
								if(ready2read = '1') then
									--if ready2read = 1, then we have sent the device address with read = 1
									--we have already sent the base address before the repeated start
									cmd_state <= read_data_byte;
									sm_state <= load_byte;
									activeread <= '1';
								else
									--otherwise, we just send the base address
									cmd_state <= send_base_addr;
									sm_state <= load_byte;
								end if;
							end if;

							
						when send_base_addr =>
							--if we just sent the base address, we have to make a choice

							if(cmd_reg = '0') then
								--if writing, send a byte
								sm_state <= load_byte;
								cmd_state <= send_data_byte;
							else
								--if reading, send a repeated start and the device address again
								sm_state <= wait_for_released_sda;
								cmd_state <= send_dev_addr;
								--setup this optional signal for the rnw bit
								ready2read <= '1';
							end if;
							
						when send_data_byte =>
							--if we just wrote the data byte in, we're done
							cmd_state <= send_dev_addr;
							sm_state <= stop;
							
						when read_data_byte =>
							--if we just read the data byte, we're done
							cmd_state <= send_dev_addr;
							sm_state <= stop;
							ready2read <= '0';
							activeread <= '0';
						when others => end case;
				when stop =>
					

					if(sda_i = '0') then
						--wait here until the sda is released by the slave
						if(scl_i = '0') then
							scl_t <= '0';
						else
							scl_t <= '1';
						end if;
					else

						if(scl_i = '0') then
							sda_t <= '1';
							sm_state <= stop_post;
						else
							scl_t <= '1';
						end if;
						
					end if;
					
				when stop_post =>
					
					--sda is low by master
					--scl is low
					
					--bring scl high first
					if(scl_i = '0') then
						scl_t <= '0';
					else
						sda_t <= '0';
						sm_state <= done;
					end if;

					
				when done =>
					sm_state <= idle;
					cmd_locked <= '0';
					
				when wait_for_released_sda =>
			
					if(scl_i = '0') then
						scl_t <= '0';
					else
						scl_t <= '1';
					end if;

					if(sda_i = '1') then
						sm_state <= start;
						scl_t <= '0';
					end if;
					
				when others => end case;
				
			
			end if;
			end if;
		
		end if;
	end process;
	
end arch;