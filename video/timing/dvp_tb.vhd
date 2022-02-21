library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;

entity dvp_tb is 

end dvp_tb;

architecture test of dvp_tb is
    
	signal clk : std_logic := '0';
    signal clk_cnt : integer := 0;
    
    constant h_active : integer := 640;
    constant v_active : integer := 480;
    constant h_total  : integer := 800;
    constant v_total  : integer := 525;
    
    signal gen_en : std_logic := '0';
    signal rgb : std_logic_vector(23 downto 0) := (others => '0');
    signal valid, sof, eol : std_logic := '0';
    
    signal image_written : std_logic := '0';
    signal i_w_cnt : integer := 0;
    
    signal vtg_sof, vtg_eol, vtg_vld : std_logic := '0';
    signal ptg_sof, ptg_eol, ptg_vld : std_logic := '0';
    
    signal d2s_sof,d2s_eol,d2s_vld : std_logic := '0';
    signal dvp_data_i : std_logic_vector(23 downto 0) := (others => '0');
    signal dvp_data_o : std_logic_vector(23 downto 0) := (others => '0');
    signal s2d_sof,s2d_eol,s2d_vld : std_logic := '0';
    
    signal dvp_sof,dvp_eol,dvp_vld : std_logic := '0';
    signal dvp_href : std_logic := '0';
    signal dvp_vsync : std_logic := '0';
    
begin

    process(clk)
    begin
        if(rising_edge(clk)) then
            gen_en <= '1';
        end if;
    end process;

	video_timing_gen_inst : entity work.video_timing_generator
    generic map(
        H_ACTIVE => h_active,
        H_TOTAL  => h_total,
        V_ACTIVE => v_active,
        V_TOTAL  => v_total
    )
	port map(
		clk    => clk,
		enable => gen_en,

        sof => vtg_sof,
        eol => vtg_eol,
        vld => vtg_vld
	);
    
	pat_gen_inst : entity work.pattern_generator
	generic map(
        H_ACTIVE => h_active,
        V_ACTIVE => v_active,
	    SIM => TRUE
	)
	port map(
		clk    => clk,
		enable => gen_en,
        i_file  => "..\..\matlab\Verification\test_stream.txt",
        pattern => "11",
        
        sof_i => vtg_sof,
        eol_i => vtg_eol,
        vld_i => vtg_vld,
        
        rgb => rgb,
        raw_BGGR => open,
		raw_GBRG => open,
        raw_GRBG => open,
        raw_RGGB => open,
        
        sof_o => ptg_sof,
        eol_o => ptg_eol,
        vld_o => ptg_vld
	);

	stream2dvp_inst : entity work.stream2dvp
	generic map(
        DATA_WIDTH => 24
	)
	port map(
		clk    => clk,
		reset  => '0',
 
        sof_i  => ptg_sof,
        eol_i  => ptg_eol,
        vld_i  => ptg_vld,
        data_i => rgb,
        
        href_o => dvp_href,
        vsync_o => dvp_vsync,
        data_o => dvp_data_i
	);

    --assert (dvp_vsync = '0') report "stream2dvp has given vsync" severity note; 

	dvp2stream_inst : entity work.dvp2stream
	generic map(
        DATA_WIDTH => 24,
        FRAMES_TO_LOCK => 3
	)
	port map(
		clk    => clk,
		reset  => '0',
 
        href_i => dvp_href,
        vsync_i => dvp_vsync,
        data_i => dvp_data_i,
 
        sof_o  => dvp_sof,
        eol_o  => dvp_eol,
        vld_o  => dvp_vld,
        data_o => dvp_data_o
	);

    --assert (dvp_sof = '0') report "dvp2stream has given sof" severity note;

	img_wr_inst : entity work.image_writer
	generic map(
	    o_file => "..\..\matlab\Verification\test_output.txt",
        DATA_WIDTH => 24,
        h_active => h_active,
        v_active => v_active
        
	)
	port map(
		clk    => clk,
		enable => gen_en,
        sof => dvp_sof,
        eol => dvp_eol,
        data => dvp_data_o,
        valid => dvp_vld,
        pic_err => open,
        line_err => open,
        i_w => image_written,
        i_w_cnt => i_w_cnt

	);
    
    --assert (image_written = '0') report "Image has been written" severity failure;
    assert (i_w_cnt /= 4) report "Image has been written" severity failure;
	
	clk_stim : process
	begin
		clk <= '0';
		wait for 10 ns;
		clk <= '1';
		wait for 10 ns;
	end process;

    process
    begin
  
	wait;

    end process;
    
end test;