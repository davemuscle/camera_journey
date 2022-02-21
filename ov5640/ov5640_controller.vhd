library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.ov5640_controller_pkg.all;

entity ov5640_controller is
	generic(
		CLK_DIV_10ms : integer := 50
	);
	port(

    	clk : in std_logic;
		
		start : in std_logic;
       
       --when 0, boot from ROM. When 1, boot from FIFO
        dbg_cmd_sel  : in std_logic; 
        
        --fifo to read from for debug boot
        dbg_fifo_en   : out std_logic;
        dbg_fifo_addr  : in std_logic_vector(15 downto 0);
        dbg_fifo_wr_data : in std_logic_vector(7 downto 0);
        dbg_fifo_empty   : in std_logic;
        
        --signals for the debug port to drive for reading / writing to camera
        dbg_cmd_rd   : in std_logic;
        dbg_cmd_wr   : in std_logic;
        dbg_cmd_addr : in std_logic_vector(15 downto 0);
        dbg_cmd_wr_data : in std_logic_vector(7 downto 0);
        dbg_cmd_rd_data  : out std_logic_vector(7 downto 0);
        
		force_id_read : in std_logic;
		pwr_up_start : out std_logic := '0';
		pwr_up_done : in std_logic;
		
		device_id_good : out std_logic := '0';		
		init_done : out std_logic := '0';
		
        
        
		--i2c ports
		cmd      : out std_logic := '0'; -- only two commands for now
		cmd_en   : out std_logic := '0'; -- 1 = read the new cmd, data and execute
		cmd_busy : in std_logic := '0';
        
		base_addr : out std_logic_vector(15 downto 0) := (others => '0'); --base address within device to pick rd or wr
		
		--write data
		wr_data : out std_logic_vector(7 downto 0) := (others => '0');
		
		--read data
		rd_data : in std_logic_vector(7 downto 0) := (others => '0')
		


	);
end ov5640_controller;

architecture arch of ov5640_controller is 

	signal start_dly : std_logic := '0';
	signal init_pwr_started : std_logic := '0';
	
	signal pwr_up_done_dly : std_logic := '0';
	
	signal pwr_up_wait_cnt : integer range 0 to CLK_DIV_10ms-1 := 0;
	signal pwr_up_wait_en : std_logic := '0';


	signal cmd_busy_dly : std_logic := '0';
	
	signal dev_id_read_en : std_logic := '0';
	signal dev_id_read_state : std_logic_vector(1 downto 0) := (others => '0');
	signal dev_id_low, dev_id_high : std_logic_vector(7 downto 0) := (others => '0');

	signal init_wr_seq_en : std_logic := '0';
	signal init_wr_seq_num : integer range 0 to ov5640_init_wr_seq_len-1 := 0;
	signal init_wr_seq_state : std_logic_vector(0 downto 0) := "0";

    signal cmd_read, cmd_read_reg, cmd_read_dly : std_logic := '0';
    signal cmd_read_started : std_logic := '0';
    
    signal rom_rd_baseaddr : std_logic_vector(15 downto 0) := (others => '0');
    signal rom_rd_data     : std_logic_vector(7 downto 0) := (others => '0');
    
    signal dbg_wr_state : std_logic := '0';
    signal dbg_rd_state : std_logic := '0';
    
    signal init_done_int : std_logic := '0';
    
    signal start_wait_dly : std_logic := '0';
    constant wait_dly_max : integer range 0 to CLK_DIV_10ms-1 := CLK_DIV_10ms/10;
    signal wait_dly_cnt : integer range 0 to CLK_DIV_10ms-1 := 0;

begin

	pwr_up_start <= init_pwr_started;

	device_id_good <= '1' when dev_id_high = x"56" and dev_id_low = x"40" else '0';

    dbg_fifo_en <= cmd_read when dbg_cmd_sel = '1' else '0';

	process(clk)
	begin
		if(rising_edge(clk)) then
		
			start_dly <= start;
		
			--look for a rising edge on the start signal
			if(start_dly = '0' and start = '1') then
				--start command for sccb works off rising edge
				init_pwr_started <= '1';
				init_done <= '0';
                init_done_int <= '0';
			else
				init_pwr_started <= '0';
			end if;
			
			
			pwr_up_done_dly <= pwr_up_done;
			--look for a rising edge on the pwr done signal
			--this tells the ov5640 has been pwdup and reset via pins
			if(pwr_up_done_dly = '0' and pwr_up_done = '1') then
				pwr_up_wait_en <= '1';
			end if;
				
			--wait 10 ms after pwr up for the xclk gate
			if(pwr_up_wait_en = '1') then
				if(pwr_up_wait_cnt = CLK_DIV_10ms-1) then
					pwr_up_wait_cnt <= 0;
					pwr_up_wait_en <= '0';
					dev_id_read_en <= '1';
				else
					pwr_up_wait_cnt <= pwr_up_wait_cnt + 1;
				end if;
			end if;

			--continuously read the device id for i2c debugging
			if(force_id_read = '1') then
				dev_id_read_en <= '1';
			end if;
			
			--register in the cmd busy, look for edges
			cmd_busy_dly <= cmd_busy;
			
			--the first portion of the init sequence reads the device id from registers
			--0x300A and 0x300B -> 0x56 and 0x40
			if(dev_id_read_en = '1') then
				case dev_id_read_state is 
				when "00"   => 
					if(cmd_busy = '0') then
						--setup the read command to register 0x300A
						cmd_en <= '1';
						cmd <= '1';
						base_addr <= x"300A";
						dev_id_read_state <= "01";
					end if;
				when "01"   =>
					if(cmd_busy = '1') then
						cmd_en <= '0';
					end if;
					if(cmd_busy = '0' and cmd_busy_dly = '1') then
						--falling edge on the cmd busy signal, means rd_data is available
						dev_id_high <= rd_data;
						dev_id_read_state <= "10";
					end if;
				when "10"   =>
					if(cmd_busy = '0') then
						--setup the read command to register 0x300B
						cmd_en <= '1';
						cmd <= '1';
						base_addr <= x"300B";
						dev_id_read_state <= "11";
					end if;
				when others => 
					if(cmd_busy = '1') then
						cmd_en <= '0';
					end if;
					if(cmd_busy = '0' and cmd_busy_dly = '1') then
						dev_id_low <= rd_data;
						dev_id_read_state <= "00";
						
						if(force_id_read = '0') then
							dev_id_read_en <= '0';
							
							--start the main init sequence
							init_wr_seq_en <= '1';						
						end if;

					end if;
				end case;
			end if;

            cmd_read_reg <= cmd_read;
            cmd_read_dly <= cmd_read_reg;
            
            if(cmd_read = '1') then
                rom_rd_baseaddr <= ov5640_init_wr_seq(init_wr_seq_num)(23 downto 8);
                rom_rd_data     <= ov5640_init_wr_seq(init_wr_seq_num)(7 downto 0);
            end if;
            
            --pulse this
            if(cmd_read = '1') then
                cmd_read <= '0';
            end if;

			if(init_wr_seq_en = '1') then
				init_done <= '0';
				init_done_int <= '0';
				case init_wr_seq_state is
				when "0"    =>
                
                    --read the command from ROM or FIFO
                    if(cmd_busy = '0' and cmd_read_started = '0') then
                        cmd_read <= '1';
                        cmd_read_started <= '1';
                    end if;
                   
                    --data is available on this clock
                    if(cmd_read_reg = '1') then
                        cmd <= '0';
                        cmd_en <= '1';
                        
                        if(dbg_cmd_sel = '0') then
                            --boot from ROM 
                            base_addr <= rom_rd_baseaddr;
                            wr_data   <= rom_rd_data;
                        else
                            --boot from FIFO
                            base_addr <= dbg_fifo_addr;
                            wr_data   <= dbg_fifo_wr_data;
                        end if;
                        
                    end if;
					
                    --switch states once the command goes high
					if(cmd_busy_dly = '0' and cmd_busy = '1') then
						init_wr_seq_state <= "1";
						cmd_en <= '0';
                        cmd_read_started <= '0';
					end if;
					
				when others => 		
					--wait for the command to finish
                    --check if the fifo is empty, or if we've written everything from the ROM
					if(cmd_busy_dly = '1' and cmd_busy = '0') then
						
                        start_wait_dly <= '1';
                        
                        if(dbg_cmd_sel = '0') then
                            if(init_wr_seq_num = ov5640_init_wr_seq_len-1) then
                                init_wr_seq_num <= 0;
                                init_wr_seq_en <= '0';
                                init_done <= '1';
                                init_done_int <= '1';
                            else
                                init_wr_seq_num <= init_wr_seq_num + 1;
                                init_wr_seq_en <= '1';
                                init_done <= '0';
                                init_done_int <= '0';
                            end if;
                        else
                            if(dbg_fifo_empty = '1') then
                                init_wr_seq_en <= '0';
                                init_done <= '1';
                                init_done_int <= '1';
                                init_wr_seq_num <= 0;
                            else
                                init_wr_seq_en <= '1';
                                init_done <= '0';
                                init_done_int <= '0';
                                init_wr_seq_num <= 0;
                            end if;
                        end if;
					end if;
                    
                    --wait between each command
                    if(start_wait_dly = '1') then
                        if(wait_dly_cnt = wait_dly_max) then
                            start_wait_dly <= '0';
                            init_wr_seq_state <= "0";
                            wait_dly_cnt <= 0;
                        else
                            wait_dly_cnt <= wait_dly_cnt + 1;
                        end if;
                    else
                        wait_dly_cnt <= 0;
                    end if;
                    
				end case;
			end if;
            
            if(init_done_int = '1' and dev_id_read_en = '0') then
                cmd_en <= '0';
                if(cmd_busy = '0') then
                
                    dbg_wr_state <= '0';
                    dbg_rd_state <= '0';
                
                    if(dbg_cmd_wr = '1') then
                        cmd <= '0';
                        cmd_en <= '1';
                        base_addr <= dbg_cmd_addr;
                        wr_data   <= dbg_cmd_wr_data;
                        dbg_wr_state <= '1';
                    elsif(dbg_cmd_rd = '1') then
                        cmd <= '1';
                        cmd_en <= '1';
                        base_addr <= dbg_cmd_addr;
                        dbg_rd_state <= '1';                    
                    end if;
                else

                    if(dbg_wr_state = '1') then
                        dbg_wr_state <= '0';
                    end if;
                    
                    if(dbg_rd_state = '1') then
                        dbg_rd_state <= '0';
                    end if;

                end if;

            end if;

		end if;
	end process;
	
    dbg_cmd_rd_data <= rd_data;
    
end arch;