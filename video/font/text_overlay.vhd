library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
--Dave Muscle

--Adds text overlay in ASCII format to video stream
  
--Input Messages with this format:
--msg_data =    [0x01] [CHAR1] [CHAR2] ... [0x03]
--msg_wr   =  __---------------------------------__
--msg_sel  =     [x = 1 to enable,  0 to disable]

--Potential bug if you try and send the max amount of chars in a message, keep to max-1 or max-2

use work.text_overlay_font_pkg.all;

entity text_overlay is
	generic(
        NUM_MSGS    : integer := 32;
        MAX_MSG_LEN : integer := 128;
		h_active    : integer := 1920;
		h_total     : integer := 2200;
		v_active    : integer := 1080;
		v_total     : integer := 1125
		);
	port(
	    clk     : in std_logic;
		reset   : in std_logic;

        msg_wr   : in std_logic;
        msg_clr  : in std_logic;
        msg_sel  : in integer;
        msg_data : in std_logic_vector(7 downto 0);
        msg_h    : in integer;
        msg_v    : in integer;
        
        msg_killall : in std_logic;
        msg_en   : in std_logic;
        
        msg_text_color : in std_logic_vector(23 downto 0);
        msg_bg_color   : in std_logic_vector(23 downto 0);
        msg_bg_en      : in std_logic;
        
        sof_i   : in std_logic;
        eol_i   : in std_logic;
        data_i  : in std_logic_vector(23 downto 0);
        valid_i : in std_logic;
        
        sof_o   : out std_logic := '0';
        eol_o   : out std_logic := '0';
        data_o  : out std_logic_vector(23 downto 0) := (others => '0');
        valid_o : out std_logic := '0'
		
        );
end text_overlay;

architecture arch of text_overlay is 
    
    constant RAM_SIZE : integer := MAX_MSG_LEN*8;
    constant RAM_SIZE_LOG2 : integer := integer(ceil(log2(real(RAM_SIZE))));
    constant NUM_MSGS_LOG2 : integer := integer(ceil(log2(real(NUM_MSGS))));
    
    signal valid_i_dly : std_logic := '0';
    signal sof_i_dly : std_logic := '0';
    signal eol_i_dly : std_logic := '0';
    signal data_i_dly : std_logic_vector(23 downto 0) := (others => '0');
    signal eof : std_logic := '0';
    
    signal h_count, v_count : integer range 0 to 4095 := 0;
    signal enable : std_logic := '0';

    signal reset_meta, reset_sync, self_reset : std_logic := '0';
   
    signal ram_wr      : std_logic := '0';
    signal ram_rd      : std_logic := '0';
    signal ram_wr_data : std_logic_vector(7 downto 0) := (others => '0');
    signal ram_rd_data : std_logic_vector(7 downto 0) := (others => '0');
    signal ram_wr_addr : std_logic_vector(RAM_SIZE_LOG2-1 downto 0) := (others => '0');
    signal ram_rd_addr : std_logic_vector(RAM_SIZE_LOG2-1 downto 0) := (others => '0');
    
    signal ram_wr_page_addr : std_logic_vector(NUM_MSGS_LOG2-1 downto 0) := (others => '0');
    signal ram_rd_page_addr : std_logic_vector(NUM_MSGS_LOG2-1 downto 0) := (others => '0');
    
    signal ram_wr_full_addr : std_logic_vector(RAM_SIZE_LOG2+NUM_MSGS_LOG2-1 downto 0) := (others => '0');
    signal ram_rd_full_addr : std_logic_vector(RAM_SIZE_LOG2+NUM_MSGS_LOG2-1 downto 0) := (others => '0');

    
    signal msg_wr_dly, msg_record : std_logic := '0';
    type msg_loc_t is array(0 to NUM_MSGS-1) of integer;
    signal msg_loc_h,msg_loc_v : msg_loc_t := (others => 0);
    signal msg_active : std_logic_vector(NUM_MSGS-1 downto 0) := (others => '0');
    signal msg_clr_dly : std_logic := '0';
    signal msg_data_dly : std_logic_vector(7 downto 0) := (others => '0');
    type msg_len_t is array(0 to NUM_MSGS-1) of std_logic_vector(RAM_SIZE_LOG2-1 downto 0);
    signal msg_len : msg_len_t := (others => (others => '0'));
    
    signal msg_state : std_logic_vector(3 downto 0) := (others => '0');
    signal msg_running : std_logic := '0';
    signal msg_num : integer := 0;
    signal msg_addr : std_logic_vector(RAM_SIZE_LOG2-1 downto 0) := (others => '0');
    signal msg_rd_cnt : integer := 0;
    signal msg_rd : std_logic := '0';
    
    signal font_read_addr_sub  : std_logic_vector(7 downto 0) := (others => '0');
    signal font_read_addr_adj  : std_logic_vector(15 downto 0) := (others => '0');
    signal font_read_addr_mult : std_logic_vector(15 downto 0) := (others => '0'); 

    signal font_rom_rd_data : std_logic_vector(CHAR_WIDTH-1 downto 0) := (others => '0');

    signal msg_row : integer := 0;
    signal msg_col : integer := 0;
    
    signal msg_len_cnt : integer := 0;
    
    signal char_go : std_logic := '0';
    signal char_val : std_logic := '0';
    
    constant PIPE_DLY : integer := 6;
    signal sof_pipe : std_logic_vector(PIPE_DLY-1 downto 0) := (others => '0');
    signal eol_pipe : std_logic_vector(PIPE_DLY-1 downto 0) := (others => '0');
    signal valid_pipe : std_logic_vector(PIPE_DLY-1 downto 0) := (others => '0');
    type data_dly_t is array(0 to PIPE_DLY-1) of std_logic_vector(23 downto 0);
    signal data_pipe : data_dly_t := (others => (others => '0'));
    
    signal sof_dly, eol_dly, valid_dly : std_logic := '0';
    signal data_dly : std_logic_vector(23 downto 0) := (others => '0');
    
    signal text_valid : std_logic := '0';
    signal row_lock : std_logic := '0';
begin	

	--Setup counting and timing structure
	process(clk)
	begin
		if(rising_edge(clk)) then
		
			--enable the counters for keeping track of time
			if(sof_i = '1' and valid_i = '1') then
				enable <= '1';
                h_count <= 0;
                v_count <= 0;
			end if;

            --delay inputs to lineup with the count
            sof_i_dly <= sof_i;
            eol_i_dly <= eol_i;
            valid_i_dly <= valid_i;
            data_i_dly <= data_i;
            
			--if enabled, count through the frame
			if(enable = '1') then
				if(h_count = h_total-1) then
					h_count <= 0;
					if(v_count = v_total-1) then
						v_count <= 0;
					else
						v_count <= v_count + 1;
					end if;
				else
					h_count <= h_count + 1;
				end if;
			end if;
            
            --stream correction
            if(enable = '1') then
                if(sof_i_dly = '0' and h_count = 0 and v_count = 0) then
                    self_reset <= '1';
                end if;
                
                if(eol_i_dly = '0' and h_count = h_active-1 and v_count < v_active) then
                    self_reset <= '1';
                end if;
            end if;
            
            if(enable = '1' and h_count = h_active-1 and v_count = v_active-1) then
                eof <= '1';
            else
                eof <= '0';
            end if;
            
            reset_meta <= reset;
            reset_sync <= reset_meta;
            
            if(reset_sync = '1' or self_reset = '1') then
                enable <= '0';
                h_count <= 0;
                v_count <= 0;
                sof_i_dly <= '0';
                eol_i_dly <= '0';
                valid_i_dly <= '0';
                self_reset <= '0';
                eof <= '0';
            end if;
            
		end if;
	end process;

    --overlay text onto screen
    process(clk)
    begin
        if(rising_edge(clk)) then
        
            --delay count and data values
            sof_pipe(PIPE_DLY-1 downto 0) <= sof_pipe(PIPE_DLY-2 downto 0) & sof_i_dly;
            eol_pipe(PIPE_DLY-1 downto 0) <= eol_pipe(PIPE_DLY-2 downto 0) & eol_i_dly;
            valid_pipe(PIPE_DLY-1 downto 0) <= valid_pipe(PIPE_DLY-2 downto 0) & valid_i_dly;
            
            for i in 0 to PIPE_DLY-2 loop
                data_pipe(i+1) <= data_pipe(i);
            end loop;
            data_pipe(0) <= data_i_dly;

            sof_dly <= sof_pipe(PIPE_DLY-1);
            eol_dly <= eol_pipe(PIPE_DLY-1);
            valid_dly <= valid_pipe(PIPE_DLY-1);
            data_dly <= data_pipe(PIPE_DLY-1);
            
        
            --enable starting the text
            ram_rd <= '0';
        
            --a character has been read from the ram
            if(msg_state = "0001") then
                ram_rd_addr <= std_logic_vector(unsigned(ram_rd_addr)+1);
                msg_rd_cnt <= msg_rd_cnt - 1;
                msg_state <= "0100";
                row_lock <= '0';
            end if;

            --second, offset the ASCII character to lineup with the ROM from MATLAB            
            if(msg_state = "0100") then
                font_read_addr_sub <= std_logic_vector(unsigned(ram_rd_data)-to_unsigned(32,8));
                msg_state <= "0101";
            end if;
            
            if(msg_state = "0101") then
                font_read_addr_mult <= std_logic_vector(unsigned(font_read_addr_sub)*to_unsigned(CHAR_HEIGHT,8));
                msg_state <= "0110";
            end if;
        
            if(msg_state = "0110") then
                font_read_addr_adj <= std_logic_vector(unsigned(font_read_addr_mult) + to_unsigned(msg_row,16));
                msg_state <= "0010";
            end if;

            text_valid <= '0';
            
            if(char_go = '1') then
                --shift left the pixel data from the font rom
                char_val <= font_rom_rd_data(CHAR_WIDTH-1);
                text_valid <= '1';
                font_rom_rd_data <= font_rom_rd_data(CHAR_WIDTH-2 downto 0) & '0';
                msg_col <= msg_col + 1;
                
                --when msg_col = CHAR_WIDTH-1, we are outputting the last pixel of the character row
                if(msg_col = CHAR_WIDTH-1) then
                    msg_col <= 0;

                    if(msg_rd_cnt = 0) then
                        char_go <= '0';

                        if(msg_row = CHAR_HEIGHT-1 and msg_rd_cnt = 0) then
                            --end of string
                            msg_state <= "0000";
                        end if;
                        
                        if(row_lock = '0') then
                            msg_row <= msg_row + 1;
                            row_lock <= '1';
                        end if;
                        
                    end if;

                end if;
                
                
                --check if we need to start fetching a new character from the ROM
                if(msg_col = CHAR_WIDTH-1-5) then
                    if(msg_rd_cnt /= 0) then
                        ram_rd <= '1';
                        msg_state <= "0001";
                    end if;
                end if;
                
            end if; 
 
            --third, read from the ROM
            if(msg_state = "0010") then
                msg_state <= "1000";
                font_rom_rd_data <= font_rom(to_integer(unsigned(font_read_addr_adj)));
                char_go <= '1';
            end if;
            
            --fourth, read character from rom on rows after the first
            if(msg_state = "1000") then
            
                if(char_go = '0' and msg_row < CHAR_HEIGHT and msg_active(msg_num)='1' and h_count = msg_loc_h(msg_num)) then
                
                    msg_state <= "0001";
                    ram_rd <= '1';
                    msg_rd_cnt <= to_integer(unsigned(msg_len(msg_num)));
                    ram_rd_addr <= (others => '0');
                    
                end if;
            end if;
            
            --enable starting the text, moved to end to act as reset
            for i in 0 to NUM_MSGS-1 loop
                if(h_count = msg_loc_h(i) and v_count = msg_loc_v(i) and msg_active(i) = '1' and enable = '1') then
                    --only have one text line enabled at a time
                    --this should prioritize higher messages
                    
                    --first, read from the msg ram to get the ASCII character
                    msg_state <= "0001";
                    msg_num <= i;
                    ram_rd_addr <= (others => '0');
                    msg_rd_cnt <= to_integer(unsigned(msg_len(i)));
                    ram_rd <= '1';
                    msg_row <= 0;
                    msg_col <= 0;
                    char_go <= '0';
                    text_valid <= '0';

                end if;
            end loop;

            if(reset_sync = '1' or enable = '0') then
                msg_state <= "0000";
                ram_rd <= '0';
                msg_row <= 0;
                msg_col <= 0;
                char_go <= '0';
                text_valid <= '0';
                msg_rd_cnt <= 0;
            end if;

        end if;
    end process;
    
    ram_rd_page_addr <= std_logic_vector(to_unsigned(msg_num,ram_rd_page_addr'length));
    ram_rd_full_addr <= ram_rd_page_addr & ram_rd_addr;
    
    --output pixels
    process(clk)
    begin
        if(rising_edge(clk)) then
        
            sof_o <= sof_dly;
            eol_o <= eol_dly;
            valid_o <= valid_dly;
        
            if(text_valid = '1' and msg_en = '1') then
                if(char_val = '0') then
                    --write text color
                    data_o <= msg_text_color;
                else
                    if(msg_bg_en = '1') then
                        data_o <= msg_bg_color;
                    else
                        data_o <= data_dly;
                    end if;
                end if;
            
            else
                --passthrough 
                data_o <= data_dly;
            
            end if;



        end if;
    end process;
    
    --scope the input msg port and write messages into block ram
    process(clk)
    begin
        if(rising_edge(clk)) then
        
            msg_wr_dly <= msg_wr;
            msg_clr_dly <= msg_clr;
            msg_data_dly <= msg_data;
            
            --start recording the message
            if(msg_wr_dly = '0' and msg_wr = '1' and msg_data = x"01") then
                msg_record <= '1';

                msg_loc_h(msg_sel) <= msg_h;
                msg_loc_v(msg_sel) <= msg_v;
                ram_wr_addr <= (others => '0');
                msg_len(msg_sel) <= (others => '0');
            end if;
            
            
            --clear the active message on the select bits
            if(msg_clr_dly = '0' and msg_clr = '1') then
                msg_active(msg_sel) <= '0';
            end if;

            if(ram_wr = '1') then
                ram_wr_addr <= std_logic_vector(unsigned(ram_wr_addr)+1);
                msg_len(msg_sel) <= std_logic_vector(unsigned(msg_len(msg_sel)) + 1);
            end if;
            
            ram_wr_page_addr <= std_logic_vector(to_unsigned(msg_sel,ram_wr_page_addr'length));
            
            ram_wr <= msg_record;
            
            --message recording is done
            if(msg_wr = '1' and msg_data = x"03" and msg_record = '1') then
                msg_record <= '0';
                msg_active(msg_sel) <= '1';
                ram_wr <= '0';
            end if;
            
            if(msg_killall = '1') then
                msg_active <= (others => '0');
            end if;
            
            if(reset_sync = '1') then
                msg_record <= '0';
                ram_wr <= '0';
                
            end if;
            
        end if;
    end process;
    
    ram_wr_full_addr <= ram_wr_page_addr & ram_wr_addr;
    ram_wr_data <= msg_data_dly;

    --generate a big RAM for each message we want to send
    msg_ram_inst : entity work.inferred_ram
    generic map(
        gDEPTH => NUM_MSGS_LOG2+RAM_SIZE_LOG2,
        gWIDTH => 8,
        gOREGS => 0
    )
    port map(
        a_clk  => clk,
        a_wr   => ram_wr,
        a_en   => '0',
        a_di   => ram_wr_data,
        a_do   => open,
        a_addr => ram_wr_full_addr,
        b_clk  => clk,
        b_wr   => '0',
        b_en   => ram_rd,
        b_di   => (others => '0'),
        b_do   => ram_rd_data,
        b_addr => ram_rd_full_addr
    );

    
end arch;
