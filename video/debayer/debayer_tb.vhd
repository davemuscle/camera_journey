library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;

entity debayer_tb is 

end debayer_tb;

architecture test of debayer_tb is
    
	signal clk50M : std_logic := '0';
	signal clk_count : integer := 0;
	
	--constant h_active : integer := 640;
	--constant h_total  : integer := 800;
	--constant v_active : integer := 480;
	--constant v_total  : integer := 525;
    
	constant h_active : integer := 160;
	constant h_total  : integer := 200;
	constant v_active : integer := 120;
	constant v_total  : integer := 130;
    
	--constant h_active : integer := 320;
	--constant h_total  : integer := 340;
	--constant v_active : integer := 240;
	--constant v_total  : integer := 250;
    
    signal raw_BGGR, raw_GBRG, raw_GRBG, raw_RGGB : std_logic_vector(7 downto 0) := (others => '0');
    
    signal sof_in, eol_in, vld_in : std_logic := '0';
    signal raw_in : std_logic_vector(7 downto 0) := (others => '0');
    
    signal rgb : std_logic_vector(23 downto 0) := (others => '0');
    
    signal gen_en : std_logic := '0';
    signal image_written : std_logic := '0';
    signal i_w_cnt : integer := 0;
    
    signal mode : std_logic_vector(1 downto 0) := "00";
    
    signal vtg_sof, vtg_eol, vtg_vld : std_logic := '0';
    signal ptg_sof, ptg_eol, ptg_vld : std_logic := '0';
    signal deb_sof, deb_eol, deb_vld : std_logic := '0';
    
    signal ptg_rgb : std_logic_vector(23 downto 0) := (others => '0');
    
begin

	video_timing_gen_inst : entity work.video_timing_generator
    generic map(
        H_ACTIVE => h_active,
        H_TOTAL  => h_total,
        V_ACTIVE => v_active,
        V_TOTAL  => v_total
    )
	port map(
		clk    => clk50M,
		enable => gen_en,

        sof => vtg_sof,
        eol => vtg_eol,
        vld => vtg_vld
	);
    
	pat_gen_inst : entity work.pattern_generator
	generic map(
        H_ACTIVE => h_active,
        V_ACTIVE => v_active,
	    SIM      => TRUE
	)
	port map(
		clk    => clk50M,
		enable => gen_en,
        i_file  => "..\..\matlab\FrameBuffer\test_stream_160x120.txt",
        --i_file  => "..\..\matlab\Verification\boys_640x480.txt",
        --i_file => "..\..\matlab\Verification\maisey_640x480.txt",
        pattern => "11",
        
        sof_i => vtg_sof,
        eol_i => vtg_eol,
        vld_i => vtg_vld,
        
        rgb      => ptg_rgb,
        raw_BGGR => raw_BGGR,
		raw_GBRG => raw_GBRG,
        raw_GRBG => raw_GRBG,
        raw_RGGB => raw_RGGB,
        
        sof_o => ptg_sof,
        eol_o => ptg_eol,
        vld_o => ptg_vld
	);

    process(clk50M)
    begin
        if(rising_edge(clk50M)) then
            --if(ptg_sof = '1') then
            --    case mode is 
            --    when "00"   => mode <= "01";
            --    when "01"   => mode <= "10";
            --    when "10"   => mode <= "11";
            --    when others => mode <= "00";
            --    end case;
            --end if;
            mode <= "00";
            sof_in <= ptg_sof;
            eol_in <= ptg_eol;
            vld_in <= ptg_vld;
            --raw_in <= raw_BGGR when mode = "00" else
            --          raw_GBRG when mode = "01" else
            --          raw_GRBG when mode = "10" else
            --          raw_RGGB;
            raw_in <= raw_BGGR;
        end if;
    end process;
    


	debayer_inst : entity work.debayer
	generic map(
		h_active   => h_active,
		v_active   => v_active
		)
	port map(
		clk => clk50M,
        reset => '0',
        mode => mode,
        buffer_error => open,
        sof_i  => sof_in,
        eol_i  => eol_in,
        vld_i  => vld_in,
        dat_i  => raw_in,

        sof_o => deb_sof,
        eol_o => deb_eol,
        vld_o => deb_vld,
        dat_o => rgb
	);
    
	img_wr_inst : entity work.image_writer
	generic map(
	    o_file => "../../matlab/Debayer/debayer_output.txt",
        DATA_WIDTH => 24,
        h_active => h_active,
        v_active => v_active
        
	)
	port map(
		clk    => clk50M,
		enable => gen_en,
        sof => deb_sof,
        eol => deb_eol,
        data => rgb,
        valid => deb_vld,
        pic_err => open,
        line_err => open,
        i_w => image_written,
        i_w_cnt => i_w_cnt

	);
    
	-- vanilla_test : entity work.image_writer
	-- generic map(
	    -- o_file => "../../matlab/Debayer/vanilla_output.txt",
        -- DATA_WIDTH => 24,
        -- h_active => h_active,
        -- v_active => v_active
        
	-- )
	-- port map(
		-- clk    => clk50M,
		-- enable => gen_en,
        -- sof => ptg_sof,
        -- eol => ptg_eol,
        -- data => ptg_rgb,
        -- valid => ptg_vld,
        -- pic_err => open,
        -- line_err => open,
        -- i_w => image_written,
        -- i_w_cnt => i_w_cnt

	-- );
  
    assert (sof_in  /= '1') report "SOF Seen Upstream" severity note;
    assert (deb_sof /= '1') report "SOF Seen Downstream" severity note; 
    assert (i_w_cnt /= 2) report "Image has been written" severity failure;
	
	clk_stim : process
	begin
		clk50M <= '0';
		wait for 1 ns;
		clk50M <= '1';
		wait for 1 ns;
	end process;

    process(clk50M)
    begin
        if(rising_edge(clk50M)) then
            gen_en <= '1';
        end if;
    end process;

    process
    begin
  
	wait;

    end process;
    
end test;