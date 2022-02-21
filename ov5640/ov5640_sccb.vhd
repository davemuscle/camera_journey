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

entity ov5640_sccb is
	generic(
		CLK_DIV_4x  : integer;--divisor for i2c clk, 4x desired clk rate
		CLK_DIV_1ms : integer --divisor for 1 ms tick
	);
	port(

    	clk : in std_logic; --double the desired scl clock

		pwdn_reset_start : in std_logic;
		pwdn_o : out std_logic;
		reset_o : out std_logic;
		pwr_up_done : out std_logic := '0';
		
		--i2c ports
		cmd    : in std_logic; -- only two commands for now
		cmd_en : in std_logic; -- 1 = read the new cmd, data and execute
		cmd_busy  : out std_logic := '0';
        
		dev_addr  : in std_logic_vector(6 downto 0); --physical device address
		base_addr : in std_logic_vector(15 downto 0); --base address within device to pick rd or wr
		
		--write data
		wr_data : in std_logic_vector(7 downto 0);
		
		--read data
		rd_data : out std_logic_vector(7 downto 0) := (others => '0');
		
		--i2c phy pins
		sda_o : out std_logic := '0';
		sda_i : in  std_logic;
		sda_t : out std_logic := '0';
		scl_o : out std_logic := '0';
		scl_i : in  std_logic;
		scl_t : out std_logic := '0'
	);
end ov5640_sccb;

architecture arch of ov5640_sccb is 

	signal tick_cnt : integer range 0 to CLK_DIV_4x-1 := 0;
	signal tick : std_logic := '0';

	signal ms_tick_cnt : integer range 0 to CLK_DIV_1ms-1 := 0;
	signal ms_tick : std_logic := '0';

	signal scl_value : std_logic := '0';
	signal scl_state : std_logic_vector(3 downto 0) := (0 => '1', others => '0');
	
	signal cmd_locked : std_logic := '0';
	signal cmd_reg : std_logic := '0';
	
	signal phase3_write_data : std_logic_vector(32+4-1 downto 0) := (others => '0');
	signal phase2_write_data : std_logic_vector(24+3-1 downto 0) := (others => '0');
	signal phase2_read_data  : std_logic_vector(16+2-1 downto 0) := (others => '0');
	
	signal pwdn_reset_start_dly : std_logic := '0';
	
	signal pwdn_reset_done : std_logic := '0';
	signal pwdn_reset_active : std_logic := '0';
	signal pwdn_reset_state : std_logic_vector(3 downto 0) := (0 => '1', others => '0');
	
	constant pwdn_activation_level : std_logic := '1';
	constant reset_activation_level : std_logic := '0';
	
	constant pwdn_ms_count_max : integer := 100;
	constant reset_ms_count_max : integer := 100;
	signal pwdn_cnt : integer := 0;
	signal reset_cnt : integer := 0;
	
	signal pwdn_ext, reset_ext : std_logic := '0';
	
	type sm_state_type is (idle, start, stop, phase3tx, phase2tx_1, phase2tx_2, done);
	signal sm_state, prev_state, dly_state : sm_state_type := idle;
	
	signal phase3tx_cnt, phase2tx_cnt : integer range 0 to 63 := 0;
	
	signal stop_sda_released : std_logic_vector(1 downto 0) := "00";
	
begin

	--lock these to zero
	--when the tristate enable is high, this is how the i2c lines are pulled to zero
	--otherwise, when the enable is low, the i2c lines are released
	sda_o <= '0';
	scl_o <= '0';
	
	cmd_busy <= cmd_locked;
	
	pwdn_o <= pwdn_ext;
	reset_o <= reset_ext;
	
	--generate slow timing
	process(clk)
	begin
		if(rising_edge(clk)) then

			--tickrate is 4x the scl rate, or 1/4 the input clk rate
			if(tick_cnt = CLK_DIV_4x-1) then
				tick <= '1';
				tick_cnt <= 0;
			else
				tick <= '0';
				tick_cnt <= tick_cnt + 1;
			end if;
			
			--tickrate for counting ms
			if(ms_tick_cnt = CLK_DIV_1ms-1) then
				ms_tick <= '1';
				ms_tick_cnt <= 0;
			else
				ms_tick <= '0';
				ms_tick_cnt <= ms_tick_cnt + 1;
			end if;
			
			--generate serial clock
			if(tick = '1') then
				--rotate this vector around
				scl_state <= scl_state(2 downto 0) & scl_state(3);
				case scl_state is 
					when "0001" => 
					when "0010" => scl_t <= '0';
					when "0100" =>
					when others => scl_t <= '1';
				end case;
			end if;
			
			--generate reset and pwdn signals
			pwdn_reset_start_dly <= pwdn_reset_start;
			
			if(pwdn_reset_start_dly = '0' and pwdn_reset_start = '1') then
				pwdn_reset_active <= '1';
				pwdn_reset_done <= '0';
                pwdn_reset_state <= "0001";
			end if;
			
			if(ms_tick = '1') then
				if(pwdn_reset_active = '1') then
					case pwdn_reset_state is
					when "0001" => 
						pwdn_ext <= pwdn_activation_level;
						if(pwdn_cnt = pwdn_ms_count_max-1) then
							pwdn_reset_state <= "0010";
							pwdn_cnt <= 0;
						else
							pwdn_cnt <= pwdn_cnt + 1;
						end if;
					when "0010" =>
						pwdn_ext <= not pwdn_activation_level;
						if(pwdn_cnt = pwdn_ms_count_max-1) then
							pwdn_reset_state <= "0100";
							pwdn_cnt <= 0;
						else
							pwdn_cnt <= pwdn_cnt + 1;
						end if;
					when "0100" =>
						reset_ext <= reset_activation_level;
						if(reset_cnt = reset_ms_count_max-1) then
							pwdn_reset_state <= "1000";
							reset_cnt <= 0;
						else
							reset_cnt <= reset_cnt + 1;
						end if;
					when others =>
						reset_ext <= not reset_activation_level;
						if(reset_cnt = reset_ms_count_max-1) then
							pwdn_reset_state <= "0001";
							reset_cnt <= 0;
							pwdn_reset_active <= '0';
							pwdn_reset_done <= '1';
						else
							reset_cnt <= reset_cnt + 1;
						end if;
					end case;
				end if;
			end if;
		end if;
	end process;
	
	pwr_up_done <= pwdn_reset_done;
	
	--main state machine, responsible for changing the sda pin
	process(clk)
	begin
		if(rising_edge(clk)) then
	
			
		
			if(tick = '1') then
			
				case sm_state is
				when idle =>
					if(cmd_en = '1') then
						cmd_reg <= cmd;
						cmd_locked <= '1';
						
						sm_state <= start;
						prev_state <= idle;
						phase3_write_data <= dev_addr & '0' & '1' 
						                   & base_addr(15 downto 8) & '1'
										   & base_addr(7 downto 0) & '1'
										   & wr_data & '1';
					    phase2_write_data <= dev_addr & '0' & '1'
						                   & base_addr(15 downto 8) & '1'
										   & base_addr(7 downto 0) & '1';
					    phase2_read_data  <= dev_addr & '1' & '1'
										   & x"FF" & '1';
						
					end if;
				when start =>
					if(scl_state = "0100") then
						sda_t <= '1'; --sda goes low while scl high
						prev_state <= start;
						dly_state <= prev_state;
						if(cmd_reg = '0') then
							sm_state <= phase3tx;
						else
							if(dly_state = phase2tx_1) then
								sm_state <= phase2tx_2;
							else
								sm_state <= phase2tx_1;
							end if;
						end if;
					end if;
					
				when phase3tx =>
				
					if(scl_state = "0001") then
					
						phase3_write_data <= phase3_write_data(phase3_write_data'length-2 downto 0) & '0';
						
						--setup data
						if(phase3tx_cnt = phase3_write_data'length-1) then
							--done
							sm_state <= stop;
							prev_state <= phase3tx;
							dly_state <= prev_state;
							phase3tx_cnt <= 0;
						else
							phase3tx_cnt <= phase3tx_cnt + 1;
						end if;
						
						if(phase3_write_data(phase3_write_data'length-1) = '1') then
							sda_t <= '0';
						else
							sda_t <= '1';
						end if;
						
					end if;
					
				when phase2tx_1 =>
				
					if(scl_state = "0001") then
						phase2_write_data <= phase2_write_data(phase2_write_data'length-2 downto 0) & '0';
					
						--setup data
						if(phase2tx_cnt = phase2_write_data'length-1) then
							--done
							sm_state <= stop;
							prev_state <= phase2tx_1;
							dly_state <= prev_state;
							phase2tx_cnt <= 0;
						else
							phase2tx_cnt <= phase2tx_cnt + 1;
						end if;
						
						if(phase2_write_data(phase2_write_data'length-1) = '1') then
							sda_t <= '0';
						else
							sda_t <= '1';
						end if;
						
					end if;
					
				when phase2tx_2 =>
				
					if(scl_state = "0001") then
					
						phase2_read_data <= phase2_read_data(phase2_read_data'length-2 downto 0) & sda_i;

					
						--setup data
						if(phase2tx_cnt = phase2_read_data'length-1) then
							--done
							sm_state <= stop;
							prev_state <= phase2tx_2;
							dly_state <= prev_state;
							phase2tx_cnt <= 0;
						else
							phase2tx_cnt <= phase2tx_cnt + 1;
						end if;
						
						if(phase2_read_data(phase2_read_data'length-1) = '1') then
							sda_t <= '0';
						else
							sda_t <= '1';
						end if;
						
					end if;
					
				when stop =>
				
					if(scl_state = "0100") then
					
						sda_t <= '0';
						stop_sda_released(0) <= '1';
					end if;
					
					if(scl_state = "0001") then
						sda_t <= '1';
						stop_sda_released(1) <= '1';
					end if;
					
					if(scl_state = "1000" and stop_sda_released = "11") then
						--wait for sda to be high
						if(sda_i = '1') then
							prev_state <= stop;
							dly_state <= prev_state;
							stop_sda_released <= "00";
							if(cmd_reg = '1') then
								
								if(prev_state = phase2tx_1) then
									sm_state <= start;
								else
									sm_state <= done;
									--8 downto 1 as a hack since an extra bit is getting plopped in
									rd_data <= phase2_read_data(8 downto 1);
								end if;
							else
								sm_state <= done;
							end if;
						
						
						end if;
						
					end if;
				when done =>
					cmd_locked <= '0';
					prev_state <= done;
					sm_state <= idle;
					dly_state <= prev_state;
				when others =>
				end case;
				
			end if;
		
		end if;
	end process;
	
end arch;