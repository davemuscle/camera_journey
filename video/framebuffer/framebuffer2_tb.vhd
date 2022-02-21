library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.math_real.all;

use work.axi_pkg.all;

entity framebuffer2_tb is 

end framebuffer2_tb;

architecture test of framebuffer2_tb is

    --generics, constants
	--constant upstream_period_ns : time := (1 sec / 75000000);
	constant upstream_period_ns : time := (1 sec / 8400000);
	constant downstream_period_ns : time := (1 sec / 148500000);

	constant PIXEL_WIDTH : integer := 32;
	constant DATA_WIDTH : integer := PIXEL_WIDTH*16;



	constant h_active : integer := 160;
	constant v_active : integer := 120;
    --constant h_total  : integer := 130;
    --constant v_total  : integer := 6;
    constant h_total  : integer := 200;
    constant v_total  : integer := 128;

    constant BURST_SIZE : integer := 8;

    signal vert_scroll_size   : integer := 40;
    signal vert_scroll_offset : std_logic_vector(11 downto 0) := (others => '0');
    signal vert_scroll_offset_big : std_logic_vector(63 downto 0) := (others => '0');

    signal horz_scroll_size : integer := 40;
    signal horz_scroll_offset : std_logic_vector(11 downto 0) := (others => '0');

    --clocking
	signal clk : std_logic := '0';
	signal clk_count : integer := 0;
	signal downstream_clk, upstream_clk : std_logic := '0';

    --pixel streams
	signal pixel_in, pixel_out : std_Logic_vector(PIXEL_WIDTH-1 downto 0) := (others => '0');
	signal pixel_in_valid, pixel_out_valid : std_logic := '0';
	signal pixel_in_sof, pixel_in_eol : std_logic := '0';
	signal pixel_out_sof, pixel_out_eol : std_logic := '0';	

    --verification
    signal gen_en : std_logic := '0';
    signal rgb : std_logic_vector(23 downto 0) := (others => '0');
    signal image_written : std_logic := '0';
    signal i_w_cnt : integer := 0;
    
    --random tb
    signal sof_toggle : std_logic := '0';

    constant BRAM_TEST_SIZE : integer := integer(ceil(log2(real((2**26) / (DATA_WIDTH/8)))));

    signal framebuffer_axi_m2s : axi4_m2s := axi4_m2s_init;
    signal framebuffer_axi_s2m : axi4_s2m := axi4_s2m_init;
    signal framebuffer_axi_wdata : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal framebuffer_axi_rdata : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    signal ctrl1 : std_logic_vector(31 downto 0) := (others => '0');
    
    signal valid_dly : std_logic := '0';
    signal cnt_rec, cnt_exp : std_logic_vector(PIXEL_WIDTH-1 downto 0) := (others => '0');
    
    signal arbiter_status2 : std_logic_vector(31 downto 0) := (others => '0');
    signal upstream_fifo_status : std_logic_vector(1 downto 0) := (others => '0');
    signal downstream_fifo_status : std_logic_vector(1 downto 0) := (others => '0');
    signal request_error, load_error, timeout_error : std_logic := '0';
    
    
    signal request_dly, load_dly, timeout_dly : std_logic_vector(511 downto 0) := (others => '0');
    signal dov, dun, uov, uun : std_logic_vector(511 downto 0) := (others => '0');
    
    signal bad_cnt_dly : std_logic_vector(1023 downto 0) := (others => '0');
    
    signal bad : std_logic := '0';
    
    signal valid_note : std_logic := '0';
    
    signal reset_go : std_logic_vector(127 downto 0) := (others => '0');
    signal rst : std_logic := '0';
    signal en_dly : std_logic_vector(127 downto 0) := (others => '0');
    signal pattern : std_logic_vector(1 downto 0) := "11";
    
    signal dov_sticky, dun_sticky, uov_sticky, uun_sticky : std_logic := '0';
    
    signal rst_dly : std_logic_vector(511 downto 0) := (others => '0');
    
    signal sof_i, eol_i, vld_i : std_logic := '0';
    signal timing_sof_i, timing_eol_i, timing_vld_i : std_logic := '0';
    signal frame_sync : std_logic := '0';
    signal fifo_status : std_logic_vector(7 downto 0) := (others => '0');
begin

	video_timing_gen_inst : entity work.video_timing_generator
    generic map(
        H_ACTIVE => h_active,
        H_TOTAL  => h_total,
        V_ACTIVE => v_active,
        V_TOTAL  => v_total
    )
	port map(
		clk    => upstream_clk,
		enable => gen_en,

        sof => sof_i,
        eol => eol_i,
        vld => vld_i
	);

	pat_gen_inst : entity work.pattern_generator
	generic map(
        H_ACTIVE => h_active,
        V_ACTIVE => v_active,
        SIM      => TRUE
        
	)
	port map(
		clk      => upstream_clk,
		enable   => gen_en,
        i_file => "../../matlab/FrameBuffer/test_stream_160x120.txt",
        pattern  => pattern,

        sof_i  => sof_i,
        eol_i  => eol_i,
        vld_i  => vld_i,
    
        rgb      => rgb,
        raw_BGGR => open,
		raw_GBRG => open,
        raw_GRBG => open,
        raw_RGGB => open,
        
        
        sof_o => pixel_in_sof,
        eol_o => pixel_in_eol,
        vld_o => pixel_in_valid

	);

    pixel_in <= x"00" & rgb;

    --scroll_offset_big <= std_logic_vector(to_unsigned(LINE_SIZE_BYTES,32) * to_unsigned(scroll_size,32));
    --scroll_offset <= scroll_offset_big(31 downto 0);
    vert_scroll_offset <= std_logic_vector(to_unsigned(vert_scroll_size,12));
    horz_scroll_offset <= std_logic_vector(to_unsigned(horz_scroll_size,12));
    
	framebuffer_inst : entity work.framebuffer2
	generic map(
        PIXEL_WIDTH       => PIXEL_WIDTH,
		DATA_WIDTH        => DATA_WIDTH,
        XFER_TIMEOUT      => 100000,
        MAX_BURST         => BURST_SIZE,
		h_active          => h_active ,
		v_active          => v_active ,
		h_total           => h_total,
		v_total           => v_total,
        INCLUDE_FX        => TRUE

	)
	port map(
        rst => rst,
        
        fifo_status            => open,
        
        request_error          => request_error,
        load_error             => load_error,
        timeout_error          => timeout_error,
        
        vert_bypass           => '0',
        vert_splitscreen      => '0',
        vert_splitscreen_type => "000001",
        vert_flip             => '0',
        vert_mirror           => '0',
        vert_scroll           => '0',
        vert_scroll_offset    => vert_scroll_offset,
       
        horz_bypass           => '0',
        horz_splitscreen      => '0',
        horz_splitscreen_type => "000001",
        horz_flip             => '0',
        horz_mirror           => '0',
        horz_scroll           => '0',
        horz_scroll_offset    => horz_scroll_offset,
       
		--input stream side (upstream)
		upstream_clk     => upstream_clk,
		pixel_in         => pixel_in,
		pixel_in_valid   => pixel_in_valid,
		pixel_in_sof     => pixel_in_sof,
		pixel_in_eol     => pixel_in_eol,
		
        frame_sync       => '1',
        video_ready      => open,
        
		--output stream side (downstream)
		downstream_clk   => downstream_clk,
		pixel_out        => pixel_out,
		pixel_out_valid  => pixel_out_valid,
		pixel_out_sof    => pixel_out_sof,
		pixel_out_eol    => pixel_out_eol,
        
        --axi memory
        aclk       => clk,
		axi4_m2s_o => framebuffer_axi_m2s,
        axi4_s2m_i => framebuffer_axi_s2m,
        axi4_wdata => framebuffer_axi_wdata,
        axi4_rdata => framebuffer_axi_rdata
        
		
	);
    
	output_timing_gen_inst : entity work.video_timing_generator
    generic map(
        H_ACTIVE => h_active,
        H_TOTAL  => h_total,
        V_ACTIVE => v_active,
        V_TOTAL  => v_total
    )
	port map(
		clk    => downstream_clk,
		enable => gen_en,

        sof => timing_sof_i,
        eol => timing_eol_i,
        vld => timing_vld_i
	);

    axi_bram_inst : entity work.axi_bram_model
    generic map(
		DATA_WIDTH        => DATA_WIDTH,
        BRAM_TEST_SIZE    => BRAM_TEST_SIZE
    )
    port map(
        aclk    => clk,
        areset  => rst,
        axi4_m2s_i => framebuffer_axi_m2s,
        axi4_s2m_o => framebuffer_axi_s2m,
        axi4_wdata => framebuffer_axi_wdata,
        axi4_rdata => framebuffer_axi_rdata
        
    );

	img_wr_inst : entity work.image_writer
	generic map(
	    o_file => "../../matlab/FrameBuffer/framebuffer_output.txt",
        DATA_WIDTH => 24,
        h_active   => h_active,
        v_active   => v_active
        
	)
	port map(
		clk      => downstream_clk,
		enable   => gen_en,
        sof      => pixel_out_sof,
        eol      => pixel_out_eol,
        data     => pixel_out(23 downto 0),
        valid    => pixel_out_valid,
        pic_err  => open,
        line_err => open,
        i_w      => image_written,
        i_w_cnt  => i_w_cnt

	);
    
    --assert (image_written = '0') report "Image has been written" severity failure;
	
	upclk_stim : process
	begin
		upstream_clk <= '0';
		wait for upstream_period_ns;
		upstream_clk <= '1';
		wait for upstream_period_ns;
	end process;

	clk_stim : process
	begin
		clk <= '0';
		wait for 10 ns;
		clk <= '1';
		wait for 10 ns;
	end process;
	
	dwnclk_stim : process
	begin
		downstream_clk <= '0';
		wait for downstream_period_ns;
		downstream_clk <= '1';
		wait for downstream_period_ns;
	end process;
	

    
    assert(load_dly(511) = '0') report "Load Error" severity failure;
    assert(request_dly(511) = '0') report "Request Error" severity failure;
    assert(timeout_dly(511) = '0') report "Timeout Error" severity failure;
    assert (bad_cnt_dly(1023) = '0') report "Bad Count Received" severity failure;
    
    assert(uov(511) = '0') report "Upstream FIFO Overflowflow" severity failure;
    assert(uun(511) = '0') report "Upstream FIFO Underflow" severity failure; 
    assert(dov(511) = '0') report "Downstream FIFO Overflow" severity failure;
    assert(dun(511) = '0') report "Downstream FIFO Underflow" severity failure;   
    
    gen_en <= en_dly(127);
    
	--testbench stimulus
	process(clk)
	begin
		if(rising_edge(clk)) then

			clk_count <= clk_count + 1;
            
            load_dly <= load_dly(510 downto 0) & load_error;
            request_dly <= request_dly(510 downto 0) & request_error;
            timeout_dly <= timeout_dly(510 downto 0) & timeout_error;
            

		end if;
	end process;
    
    process(upstream_clk)
    begin
        if(rising_edge(upstream_clk)) then
            uov <= uov(510 downto 0) & uov_sticky;
            uun <= uun(510 downto 0) & uun_sticky;
        end if;
    end process;
    
    --comparison to counting data
    process(downstream_clk)
    begin
        if(rising_edge(downstream_clk)) then
            if(pixel_out_valid = '1') then
                cnt_exp <= std_logic_vector(unsigned(cnt_exp)+1);
                if(cnt_exp = std_logic_vector(to_unsigned(v_active*h_active-1,PIXEL_WIDTH))) then
                    cnt_exp <= (others => '0');
                end if;
                if(pixel_out_sof = '1') then
                    cnt_exp <= (others => '0');
                end if;
            end if;
            valid_dly <= pixel_out_valid;
            cnt_rec <= pixel_out;
            -- if(valid_dly = '1') then
                -- if(cnt_exp /= cnt_rec) then
                    -- bad <= '1';
                    -- bad_cnt_dly <= bad_cnt_dly(1022 downto 0) & '1';
                -- else
                    -- bad_cnt_dly <= bad_cnt_dly(1022 downto 0) & '0';
                -- end if;
                
            -- end if;
            dov <= dov(510 downto 0) & dov_sticky;
            dun <= dun(510 downto 0) & dun_sticky;
            
            if(pixel_out_valid = '1' and valid_note = '0') then
                valid_note <= '1';
                assert false report "Valid received" severity note;
            end if;
            
            if(image_written = '1') then
                assert false report "Image Written" severity note; 
            end if;
            
            reset_go <= reset_go(126 downto 0) & '0';
            
            rst_dly <= rst_dly(510 downto 0) & '0'; 
            
            if(image_written = '1' and i_w_cnt = 2) then
            
                --assert false report "Second Image Written" severity failure;
            
                --enable reset
                --rst_dly(0) <= '1';
                --assert false report "Reset Active" severity note;
                --assert false report "Switching Pattern" severity note;
                --pattern <= "01";
            end if;
            
            if(rst_dly(511) = '1') then
                reset_go <= (others => '1');
            end if;
            
            rst <= reset_go(127);
            
            
            en_dly <= en_dly(126 downto 0) & not rst;
            if(rst = '1') then
                valid_note <= '0';
            end if;
            
            if(image_written = '1' and i_w_cnt = 4) then
                assert false report "Fourth Image Written" severity failure;
            end if;
            
            
            
        end if;
    end process;

    process
    begin
		wait;
    end process;
    
end test;