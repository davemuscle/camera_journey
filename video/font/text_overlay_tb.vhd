library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;

entity text_overlay_tb is 

end text_overlay_tb;

architecture test of text_overlay_tb is
    
	signal clk : std_logic := '0';
	signal clk_count : integer := 0;

	constant h_active : integer := 640;
	constant h_total  : integer := 800;
	constant v_active : integer := 480;
	constant v_total  : integer := 525;

	--constant h_active : integer := 1920;
	--constant h_total  : integer := 2200;
	--constant v_active : integer := 1080;
	--constant v_total  : integer := 1125;
    
    signal h_count, v_count : integer range 0 to 4095 := 0;
    
    signal sof_i, eol_i, valid_i : std_logic := '0';
    signal data_i : std_logic_vector(23 downto 0) := (0 => '0', others => '0');

    signal data_o : std_logic_vector(23 downto 0) := (others => '0');
    signal sof_o : std_logic := '0';
    signal eol_o : std_logic := '0';
    signal valid_o : std_logic := '0';
    
    signal gen_en : std_logic := '0';
    signal image_written : std_logic := '0';
    
    constant test_string : string := "Hey";
    --signal char : std_logic_vector(7 downto 0) := (others => '0');
    signal char : integer;

    signal msg_wr,msg_clr : std_logic := '0';
    signal msg_sel : integer := 0;
    signal msg_data : std_logic_vector(7 downto 0) := (others => '0');
    signal msg_h, msg_v : integer := 0;
    
    signal fps : integer := 0;
    
begin

	pat_gen_inst : entity work.pattern_generator
	generic map(
	    USE_BLANKING => true,
        USE_IMG_FILE => true,
        i_file => "../../matlab/Font/test_stream.txt",
        h_active => h_active,
        h_total  => h_total,
        v_active => v_active,
        v_total  => v_total
        
	)
	port map(
		clk    => clk,
		enable => gen_en,
        pattern => "10",
        movement => '0',
        
        rgb => data_i,
        raw_BGGR => open,
		raw_GBRG => open,
        raw_GRBG => open,
        raw_RGGB => open,
        
        valid => valid_i,
        sof   => sof_i,
        eol   => eol_i

	);

	text_overlay_inst : entity work.text_overlay
	generic map(
        NUM_MSGS   => 4,
        MAX_MSG_LEN => 32,
		h_active   => h_active,
		h_total    => h_total,
		v_active   => v_active,
		v_total    => v_total
		)
	port map(
		clk     => clk,
        reset   => '0',
        
        msg_wr  => msg_wr,
        msg_clr => msg_clr,
        msg_sel => msg_sel,
        msg_data => msg_data,
        msg_h    => msg_h,
        msg_v    => msg_v,
        
        msg_killall => '0',
        msg_en   => '1',
        
        msg_text_color => x"FF0000",
        msg_bg_color   => x"000000",
        msg_bg_en      => '1',
        
        sof_i   => sof_i,
        eol_i   => eol_i,
        data_i  => data_i,
        valid_i => valid_i,

        sof_o   => sof_o,
        eol_o   => eol_o,
        data_o  => data_o,
        valid_o => valid_o
	);
    

	name_inst : entity work.NameAndFPS

	port map(
		clk     => clk,
        reset   => '0',
        
        fps => 8,
        
        msg_wr   => msg_wr,
        msg_sel  => msg_sel,
        msg_data => msg_data,
        msg_h    => msg_h,
        msg_v    => msg_v
        

	);

	img_wr_inst : entity work.image_writer
	generic map(
	    o_file => "../../matlab/Font/text_overlay_output.txt",
        DATA_WIDTH => 24,
        h_active => h_active,
        v_active => v_active
        
	)
	port map(
		clk      => clk,
		enable   => gen_en,
        sof      => sof_o,
        eol      => eol_o,
        data     => data_o,
        valid    => valid_o,
        pic_err  => open,
        line_err => open,
        i_w      => image_written,
        i_w_cnt  => open

	);
 
    assert (image_written = '0') report "Image has been written" severity failure;
	
	clk_stim : process
	begin
		clk <= '0';
		wait for 10 ns;
		clk <= '1';
		wait for 10 ns;
	end process;

    

    process(clk)
        variable char_t : integer;
    begin
        if(rising_edge(clk)) then
            clk_count <= clk_count + 1;
            
            
            -- if(clk_count = 4) then
                -- msg_h <= 0;
                -- msg_v <= 0;
                -- msg_wr <= '1';
                -- msg_sel <= 0;
                -- msg_data <= x"01";
            -- end if;
            -- if(clk_count = 5) then
                -- msg_wr <= '1';
                -- msg_sel <= 0;
                -- char_t := character'pos(test_string(1));
                -- msg_data <= std_logic_vector(to_unsigned(char_t,8));
            -- end if;
            -- if(clk_count = 6) then
                -- msg_wr <= '1';
                -- msg_sel <= 0;
                -- char_t := character'pos(test_string(2));
                -- msg_data <= std_logic_vector(to_unsigned(char_t,8));
            -- end if;
            -- if(clk_count = 7) then
                -- msg_wr <= '1';
                -- msg_sel <= 0;
                -- char_t := character'pos(test_string(3));
                -- msg_data <= std_logic_vector(to_unsigned(char_t,8));
            -- end if;
            -- if(clk_count = 8) then
                -- msg_wr <= '1';
                -- msg_sel <= 0;
                -- msg_data <= x"03";
            -- end if;
            -- if(clk_count = 9) then
                -- msg_wr <= '0';
                -- msg_sel <= 0;
                -- msg_data <= (others => '0');
            -- end if;
            
            -- if(clk_count = 10) then
                -- msg_h <= 200;
                -- msg_v <= 300;
                -- msg_wr <= '1';
                -- msg_sel <= 1;
                -- msg_data <= x"01";
            -- end if;
            -- if(clk_count = 11) then
                -- msg_wr <= '1';
                -- msg_sel <= 1;
                -- msg_data <= x"31";
            -- end if;
            -- if(clk_count = 12) then
                -- msg_wr <= '1';
                -- msg_sel <= 1;
                -- msg_data <= x"32";
            -- end if;
            -- if(clk_count = 13) then
                -- msg_wr <= '1';
                -- msg_sel <= 1;
                -- msg_data <= x"33";
            -- end if;
            -- if(clk_count = 14) then
                -- msg_wr <= '1';
                -- msg_sel <= 1;
                -- msg_data <= x"34";
            -- end if;
            -- if(clk_count = 15) then
                -- msg_wr <= '1';
                -- msg_sel <= 1;
                -- msg_data <= x"03";
            -- end if;
            -- if(clk_count = 16) then
                -- msg_wr <= '0';
                -- msg_sel <= 1;
                -- msg_data <= (others => '0');
            -- end if;
            
            
            if(clk_count = 100) then
                gen_en <= '1';
            end if;
            
            if(clk_count = 10) then
                fps <= 37;
                
            end if;
            
            if(clk_count = 15) then
            
                fps <= 60;
            end if;
            
            char <= char_t;
            
        end if;
    end process;

    process
    begin
  
	wait;

    end process;
    
end test;