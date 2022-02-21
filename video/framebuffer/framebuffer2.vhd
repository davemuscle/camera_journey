library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
	
--Structural connection from FIFO logic to arbiter
    
use work.axi_pkg.all;
    
entity framebuffer2 is
	generic(
        PIXEL_WIDTH     : integer := 8;
		DATA_WIDTH      : integer := 128;
        XFER_TIMEOUT    : integer := 1000;
        MAX_BURST       : integer := 16;
		h_active        : integer := 1920;
		v_active        : integer := 1080;
		h_total         : integer := 2200;
		v_total         : integer := 1125;
        INCLUDE_FX      : boolean := false
	);
	port(

        rst             : in  std_logic;
        
        --user status
        fifo_status     : out std_logic_vector(7 downto 0)  := (others => '0');
        request_error   : out std_logic := '0';
        load_error      : out std_logic := '0';
        timeout_error   : out std_logic := '0';
        
        --vertical addressing
        vert_bypass           : in std_logic;
        vert_splitscreen      : in std_logic;
        vert_splitscreen_type : in std_logic_vector(5 downto 0);
        vert_flip             : in std_logic;
        vert_mirror           : in std_logic;
        vert_scroll           : in std_logic;
        vert_scroll_offset    : in std_logic_vector(11 downto 0);
    
        --horizontal addressing
        horz_bypass           : in std_logic;
        horz_splitscreen      : in std_logic;
        horz_splitscreen_type : in std_logic_vector(5 downto 0);
        horz_flip             : in std_logic;
        horz_mirror           : in std_logic;
        horz_scroll           : in std_logic;
        horz_scroll_offset    : in std_logic_vector(11 downto 0);
        
		--input stream side (upstream)
		upstream_clk   : in  std_logic;
		pixel_in       : in  std_logic_vector(PIXEL_WIDTH-1 downto 0);
		pixel_in_valid : in  std_logic;
		pixel_in_sof   : in  std_logic;
		pixel_in_eol   : in  std_logic;
		
        --extra sync features, downstream clock domain
        frame_sync     : in  std_logic;
        video_ready    : out std_logic;
        
		--output stream side (downstream)
		downstream_clk  : in  std_logic;
		pixel_out       : out std_logic_vector(PIXEL_WIDTH-1 downto 0) := (others => '0');
		pixel_out_valid : out std_logic := '0';
		pixel_out_sof   : out std_logic := '0';
		pixel_out_eol   : out std_logic := '0';
	
        --axi memory
        aclk       : in std_logic;
        axi4_m2s_o : out axi4_m2s := axi4_m2s_init;
        axi4_s2m_i : in  axi4_s2m := axi4_s2m_init;
        axi4_wdata : out std_logic_vector(DATA_WIDTH-1 downto 0);
        axi4_rdata : in  std_logic_vector(DATA_WIDTH-1 downto 0)
  
	);
end framebuffer2;

architecture str of framebuffer2 is 

	constant FIFO_SIZE  : integer := 2*h_active/(DATA_WIDTH/PIXEL_WIDTH);

    signal pixel_packed_in_sof       : std_logic := '0';
    signal pixel_packed_in_eol       : std_logic := '0';
    signal pixel_packed_in_valid     : std_logic := '0';
    signal pixel_packed_in           : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal pixel_packed_in_sof_latch : std_logic := '0';
    
    signal uline_loaded     : std_logic := '0';
    signal uline_loaded_sof : std_logic := '0';
    signal aline_loaded     : std_logic := '0';
    signal aline_loaded_sof : std_logic := '0';

    signal avideo_en : std_logic := '0';
    signal areq_line : std_logic := '0';
    signal areq_line_sof : std_logic := '0';
    signal dreq_line : std_logic := '0';
    signal dreq_line_sof : std_logic := '0';

    signal dvideo_en_meta : std_logic := '0';
    signal dvideo_en_sync : std_logic := '0';
    signal gtiming_en  : std_logic := '0';
    signal gtiming_sof : std_logic := '0';
    signal gtiming_eol : std_logic := '0';
    signal gtiming_vld : std_logic := '0';
    
    signal gtiming_first : std_logic := '0';
    signal hcnt : unsigned(11 downto 0) := (others => '0');
    signal vcnt : unsigned(11 downto 0) := (others => '0');
    
    constant UNPACK_O_H_CNT : integer := integer(ceil(real(h_active)/real(DATA_WIDTH/PIXEL_WIDTH)));
        
    signal pixel_packed_out : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal pixel_packed_out_fifo_rd : std_logic := '0';
    signal pixel_packed_out_sof : std_logic := '0';
    signal pixel_packed_out_eol : std_logic := '0';
    signal pixel_packed_out_vld : std_logic := '0';
    
    signal fifo_wr_en, fifo_rd_en : std_logic := '0';
    signal fifo_wr_data, fifo_rd_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    
    signal arbiter_go           : std_logic := '0';
    signal arbiter_dir          : std_logic := '0';
    signal arbiter_busy         : std_logic := '0';
    signal arbiter_done         : std_logic := '0';
    signal arbiter_timed_out    : std_logic := '0';
    signal arbiter_transfer_len : std_logic_vector(15 downto 0) := (others => '0');
    signal arbiter_burst_len    : std_logic_vector( 7 downto 0) := (others => '0');
    signal arbiter_addr         : std_logic_vector(31 downto 0) := (others => '0');
    
    signal datamove_go           : std_logic := '0';
    signal datamove_dir          : std_logic := '0';
    signal datamove_busy         : std_logic := '0';
    signal datamove_done         : std_logic := '0';
    signal datamove_timed_out    : std_logic := '0';
    signal datamove_transfer_len : std_logic_vector(15 downto 0) := (others => '0');
    signal datamove_burst_len    : std_logic_vector( 7 downto 0) := (others => '0');
    signal datamove_addr         : std_logic_vector(31 downto 0) := (others => '0');
    
    signal first : std_logic := '0';
    signal frame_num_read : integer range 0 to 3 := 0;
    
    signal logic_pixel_out_valid : std_logic := '0';
    signal logic_pixel_out_sof   : std_logic := '0';
    signal logic_pixel_out_eol   : std_logic := '0';
    signal logic_pixel_out       : std_logic_vector(PIXEL_WIDTH-1 downto 0) := (others => '0');
    
    signal packer_ov : std_logic := '0';
    signal packer_un : std_logic := '0';
    signal unpacker_ov : std_logic := '0';
    signal unpacker_un : std_logic := '0';
    
    signal ufifo_ov : std_logic := '0';
    signal ufifo_un : std_logic := '0';
    signal dfifo_ov : std_logic := '0';
    signal dfifo_un : std_logic := '0';
    signal fifo_status_t : std_logic_vector(7 downto 0) := (others => '0');
begin    

    fifo_status_t <= packer_ov   & packer_un   &
                     unpacker_ov & unpacker_un &
                     ufifo_ov    & ufifo_un    &
                     dfifo_ov    & dfifo_un;

    process(rst,fifo_status_t)
    begin
        if(rst = '1') then
            fifo_status <= (others => '0');
        else
            for i in 0 to 7 loop
                if(fifo_status_t(i) = '1') then
                    fifo_status(i) <= '1';
                end if;
            end loop;
        end if;
    end process;

    --Stream of input pixels at PIXEL_WIDTH come in
    stream_packer_inst : entity work.stream_pack
        generic map(
            INPUT_WIDTH  => PIXEL_WIDTH,
            OUTPUT_WIDTH => DATA_WIDTH,
            H_ACTIVE     => h_active
        )
        port map(
            clk    => upstream_clk,
            reset  => rst,
            
            fifo_ov => packer_ov,
            fifo_un => packer_un,
            
            sof_i   => pixel_in_sof,
            eol_i   => pixel_in_eol,
            vld_i   => pixel_in_valid,
            dat_i   => pixel_in,
            
            sof_o   => pixel_packed_in_sof,
            eol_o   => pixel_packed_in_eol,
            vld_o   => pixel_packed_in_valid,
            dat_o   => pixel_packed_in
        );
    --Stream of input pixels at DATA_WIDTH go out
    
    --Signal to memory transfer that a line is ready
    process(upstream_clk)
    begin
        if(rising_edge(upstream_clk)) then
            uline_loaded     <= '0';
            uline_loaded_sof <= '0';
            if(pixel_packed_in_sof = '1' and pixel_packed_in_valid = '1') then
                pixel_packed_in_sof_latch <= '1';
            end if;
            if(pixel_packed_in_eol = '1' and pixel_packed_in_valid = '1') then
                if(pixel_packed_in_sof_latch = '1') then
                    pixel_packed_in_sof_latch <= '0';
                    uline_loaded_sof <= '1';
                else
                    uline_loaded     <= '1';
                end if;
            end if;
            if(rst = '1') then
                pixel_packed_in_sof_latch <= '0';
            end if;
        end if;
    end process;
    
    --CDC
    pulse_sync_inst1 : entity work.pulse_sync_handshake
    port map(
        clk_a   => upstream_clk,
        pulse_a => uline_loaded,
        busy_a  => open,
        clk_b   => aclk,
        pulse_b => aline_loaded
    );
    pulse_sync_inst2 : entity work.pulse_sync_handshake
    port map(
        clk_a   => upstream_clk,
        pulse_a => uline_loaded_sof,
        busy_a  => open,
        clk_b   => aclk,
        pulse_b => aline_loaded_sof
    );

    --Async FIFO to hold upstream packed pixels
	upstream_fifo_inst : entity work.async_fifo
	generic map(
		gDEPTH => FIFO_SIZE, 
		gWIDTH => DATA_WIDTH, 
		gOREGS => 0
	)
	port map(
		wr_clk  => upstream_clk, 
		wr_en   => pixel_packed_in_valid,
		wr_data => pixel_packed_in,
		rd_clk  => aclk,
		rd_en   => fifo_rd_en,
		rd_data => fifo_rd_data,
		reset   => rst,
		ff      => open,
		fe      => open,
		ov      => ufifo_ov,
		un      => ufifo_un
	);
    
    --Async FIFO to hold downstream packed pixels
	downstream_fifo_inst : entity work.async_fifo
	generic map(
		gDEPTH => FIFO_SIZE, 
		gWIDTH => DATA_WIDTH, 
		gOREGS => 0
	)
	port map(
		wr_clk  => aclk, 
		wr_en   => fifo_wr_en,
		wr_data => fifo_wr_data,
		rd_clk  => downstream_clk,
		rd_en   => pixel_packed_out_fifo_rd,
		rd_data => pixel_packed_out,
		reset   => rst,
		ff      => open,
		fe      => open,
		ov      => dfifo_ov,
		un      => dfifo_un
	);
    
    --CDC
    pulse_sync_inst3 : entity work.pulse_sync_handshake
    port map(
        clk_a   => downstream_clk,
        pulse_a => dreq_line,
        busy_a  => open,
        clk_b   => aclk,
        pulse_b => areq_line
    );
    pulse_sync_inst4 : entity work.pulse_sync_handshake
    port map(
        clk_a   => downstream_clk,
        pulse_a => dreq_line_sof,
        busy_a  => open,
        clk_b   => aclk,
        pulse_b => areq_line_sof
    );
    
    video_ready <= dvideo_en_sync;
    

    --Drive the arbiter to read lines
    process(downstream_clk)
    begin
        if(rising_edge(downstream_clk)) then
        
            dvideo_en_meta <= avideo_en;
            dvideo_en_sync <= dvideo_en_meta;
        
            if(dvideo_en_sync = '1' and frame_sync = '1') then
                gtiming_en <= '1';
            end if;
        
            if(frame_sync = '0') then
                gtiming_en <= '0';
            end if;
        
            dreq_line     <= '0';
            dreq_line_sof <= '0';
            
            pixel_packed_out_fifo_rd <= '0';
            pixel_packed_out_eol <= '0';
            pixel_packed_out_sof <= '0';
            pixel_packed_out_vld <= '0';
            
            if(gtiming_en = '1') then
                --Video counting 
                hcnt <= hcnt + 1;
                if(hcnt = to_unsigned(h_total-1,12)) then
                    hcnt <= (others => '0');
                    vcnt <= vcnt + 1;
                    if(vcnt = to_unsigned(v_total-1,12)) then
                        vcnt <= (others => '0');
                    end if;
                end if;
                
                if(vcnt < to_unsigned(v_active,12) and hcnt = to_unsigned(0,12)) then
                    dreq_line <= '1';
                    dreq_line_sof <= '0';
                end if;
                if(vcnt = to_unsigned(0,12) and hcnt = to_unsigned(0,12)) then
                    dreq_line_sof <= '1';
                    dreq_line     <= '0';
                end if;
                
                if(vcnt > to_unsigned(0,12) and vcnt <= to_unsigned(v_active,12)) then
                    if(hcnt < to_unsigned(UNPACK_O_H_CNT,12)) then
                        pixel_packed_out_fifo_rd <= '1';
                    end if;
                end if;
                if(pixel_packed_out_fifo_rd = '1') then
                    if(vcnt = to_unsigned(1,12) and hcnt = to_unsigned(1,12)) then
                        pixel_packed_out_sof <= '1';
                    end if;
                    if(vcnt > to_unsigned(0,12) and hcnt = to_unsigned(UNPACK_O_H_CNT,12)) then
                        pixel_packed_out_eol <= '1';
                    end if;
                end if;
                pixel_packed_out_vld <= pixel_packed_out_fifo_rd;
                
            else
                hcnt <= (others => '0');
                vcnt <= (others => '0');
            end if;

            if(rst = '1') then
                hcnt <= (others => '0');
                vcnt <= (others => '0');
                gtiming_en <= '0';
            end if;

        end if;
    end process;
    
    --Stream unpacker
    stream_unpack_inst : entity work.stream_unpack
    generic map(
        INPUT_WIDTH  => DATA_WIDTH,
        OUTPUT_WIDTH => PIXEL_WIDTH,
        H_ACTIVE     => h_active
    )
    port map(
        clk      => downstream_clk,
        reset    => rst,
        
        fifo_ov  => unpacker_ov,
        fifo_un  => unpacker_un,
        
        sof_i    => pixel_packed_out_sof,
        eol_i    => pixel_packed_out_eol,
        vld_i    => pixel_packed_out_vld,
        dat_i    => pixel_packed_out,
        
        sof_o    => logic_pixel_out_sof,
        eol_o    => logic_pixel_out_eol,
        vld_o    => logic_pixel_out_valid,
        dat_o    => logic_pixel_out
    );
    

    
    --Arbiter and AXI transactions
    framebuffer_arbiter_inst : entity work.framebuffer_arbiter
    generic map(
        PIXEL_WIDTH       => PIXEL_WIDTH,
		DATA_WIDTH        => DATA_WIDTH,
		h_active          => h_active,
		v_active          => v_active
    )
    port map(
 		clk                   => aclk,
        rst                   => rst,
        
        read_time             => open    ,
        write_time            => open    ,  
        request_error         => request_error ,  
        load_error            => load_error    ,  
        timeout_error         => timeout_error ,
    
        mem_uline_loaded      => aline_loaded           ,       
        mem_uline_loaded_sof  => aline_loaded_sof       ,
        mem_dvideo_en         => avideo_en              ,
        mem_dreq_line         => areq_line              ,
        mem_dreq_line_sof     => areq_line_sof          ,

        first                 => first,
        frame_num_read        => frame_num_read,

        datamove_go           => arbiter_go          ,
        datamove_dir          => arbiter_dir         ,
        datamove_busy         => arbiter_busy        ,
        datamove_done         => arbiter_done        ,
        datamove_timed_out    => arbiter_timed_out   ,        
        datamove_transfer_len => arbiter_transfer_len,        
        datamove_addr         => arbiter_addr        
        
    );

    FX_GEN : if(INCLUDE_FX = TRUE) generate
        framebuffer_addressing_vert_inst : entity work.framebuffer_addressing_vert
        generic map(
            PIXEL_WIDTH       => PIXEL_WIDTH,
            DATA_WIDTH        => DATA_WIDTH,
            h_active          => h_active,
            v_active          => v_active
        )
        port map(
            clk                   => aclk,
            rst                   => rst,

            bypass                => vert_bypass,
            splitscreen           => vert_splitscreen,
            splitscreen_type      => vert_splitscreen_type,
            flip                  => vert_flip,
            mirror                => vert_mirror,
            scroll                => vert_scroll,
            scroll_offset         => vert_scroll_offset,
       
            first                 => first,
            frame_num_read        => frame_num_read,
            
            arbiter_go            => arbiter_go          ,
            arbiter_dir           => arbiter_dir         ,
            arbiter_busy          => arbiter_busy        ,
            arbiter_done          => arbiter_done        ,
            arbiter_timed_out     => arbiter_timed_out   ,        
            arbiter_transfer_len  => arbiter_transfer_len,        
            arbiter_addr          => arbiter_addr        ,

            datamove_go           => datamove_go          ,
            datamove_dir          => datamove_dir         ,
            datamove_busy         => datamove_busy        ,
            datamove_done         => datamove_done        ,
            datamove_timed_out    => datamove_timed_out   ,        
            datamove_transfer_len => datamove_transfer_len,        
            datamove_addr         => datamove_addr        
            
        );
        
        framebuffer_addressing_horz_inst : entity work.framebuffer_addressing_horz
        generic map(
            PIXEL_WIDTH       => PIXEL_WIDTH,
            DATA_WIDTH        => DATA_WIDTH,
            h_active          => h_active,
            v_active          => v_active
        )
        port map(
            clk              => downstream_clk,
            rst              => rst,

            bypass           => horz_bypass,
            splitscreen      => horz_splitscreen,
            splitscreen_type => horz_splitscreen_type,
            flip             => horz_flip,
            mirror           => horz_mirror,
            scroll           => horz_scroll,
            scroll_offset    => horz_scroll_offset,
     
            pixel_in_sof     => logic_pixel_out_sof  ,
            pixel_in_eol     => logic_pixel_out_eol  ,
            pixel_in_valid   => logic_pixel_out_valid,
            pixel_in         => logic_pixel_out      ,
            
            pixel_out_sof    => pixel_out_sof  ,
            pixel_out_eol    => pixel_out_eol  ,
            pixel_out_valid  => pixel_out_valid,        
            pixel_out        => pixel_out      
      
        );
        
    end generate FX_GEN;
    
    NO_FX_GEN : if(INCLUDE_FX = FALSE) generate
    
        pixel_out_sof   <= logic_pixel_out_sof;
        pixel_out_eol   <= logic_pixel_out_eol;
        pixel_out_valid <= logic_pixel_out_valid;
        pixel_out       <= logic_pixel_out;
        
        datamove_go           <= arbiter_go;
        datamove_dir          <= arbiter_dir;
        arbiter_busy          <= datamove_busy;
        arbiter_done          <= datamove_done;
        arbiter_timed_out     <= datamove_timed_out;
        datamove_transfer_len <= arbiter_transfer_len;
        datamove_addr         <= arbiter_addr;
        
    end generate NO_FX_GEN;
    
    datamover_inst : entity work.axi_datamover
	generic map(
		DATA_WIDTH     => DATA_WIDTH,
        MAX_BURST      => MAX_BURST,
        TIMEOUT_CLOCKS => XFER_TIMEOUT
	)
	port map(
        --clocks and reset -------------------------------
		clk => aclk,
        --rst => rst,
        rst => '0',
        --control and status
        go           => datamove_go          ,
        dir          => datamove_dir         ,
        busy         => datamove_busy        ,
        done         => datamove_done        ,
        timed_out    => datamove_timed_out   ,
        transfer_len => datamove_transfer_len,
        start_addr   => datamove_addr        ,   
        --fifo2slave -------------------------------------
        f2s_fifo_en     => fifo_rd_en,
        f2s_fifo_data   => fifo_rd_data,
        --slave2fifo -------------------------------------
        s2f_fifo_en     => fifo_wr_en,
        s2f_fifo_data   => fifo_wr_data,
        --axi --------------------------------------------
        axi4_m2s_o => axi4_m2s_o,
        axi4_s2m_i => axi4_s2m_i,
        axi4_wdata => axi4_wdata,
        axi4_rdata => axi4_rdata
	);
    
end str;