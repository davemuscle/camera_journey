library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
	
--Structural connection from FIFO logic to arbiter
    
use work.axi_pkg.all;
    
entity framebuffer is
	generic(
        PIXEL_WIDTH     : integer := 8;
		DATA_WIDTH      : integer := 128;
        XFER_TIMEOUT    : integer := 1000;
        MAX_BURST       : integer := 16;
		h_active        : integer := 1920;
		v_active        : integer := 1080;
		h_blank         : integer := 280;
		v_blank         : integer := 45;
        INCLUDE_FX      : boolean := false
	);
	port(

        rst             : in  std_logic;
        
        --user status
        ufifo_ov_sticky : out std_logic := '0';
        ufifo_un_sticky : out std_logic := '0';
        dfifo_ov_sticky : out std_logic := '0';
        dfifo_un_sticky : out std_logic := '0';
        read_time       : out std_logic_vector(11 downto 0) := (others => '0');
        write_time      : out std_logic_vector(11 downto 0) := (others => '0');
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
end framebuffer;

architecture str of framebuffer is 

    signal mem_dvideo_en : std_logic := '0';
    signal mem_dreq_line : std_logic := '0';
    signal mem_dreq_line_sof : std_logic := '0';
    
    signal mem_uline_loaded : std_logic := '0';
    signal mem_uline_loaded_sof : std_logic := '0';
    
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
    
begin    


	framebuffer_logic_inst : entity work.framebuffer_logic
	generic map(
        PIXEL_WIDTH       => PIXEL_WIDTH,
		DATA_WIDTH        => DATA_WIDTH,
		h_active          => h_active ,
		v_active          => v_active ,
		h_blank           => h_blank,
		v_blank           => v_blank
	)
	port map(
        
		--input stream side (upstream)
		upstream_clk     => upstream_clk,
		pixel_in         => pixel_in,
		pixel_in_valid   => pixel_in_valid,
		pixel_in_sof     => pixel_in_sof,
		pixel_in_eol     => pixel_in_eol,
		
		--output stream side (downstream)
		downstream_clk   => downstream_clk,
		pixel_out        => logic_pixel_out,
		pixel_out_valid  => logic_pixel_out_valid,
		pixel_out_sof    => logic_pixel_out_sof,
		pixel_out_eol    => logic_pixel_out_eol,
        
		mem_clk              => aclk,
        mem_uline_loaded     => mem_uline_loaded       ,       
        mem_uline_loaded_sof => mem_uline_loaded_sof   ,
        mem_ufifo_rd_en      => fifo_rd_en             ,
        mem_ufifo_rd_data    => fifo_rd_data           ,
        mem_dvideo_en        => mem_dvideo_en          ,
        mem_dreq_line        => mem_dreq_line          ,
        mem_dreq_line_sof    => mem_dreq_line_sof      ,
        mem_dfifo_wr_en      => fifo_wr_en             ,
        mem_dfifo_wr_data    => fifo_wr_data           ,    
		
        reset           => rst,
        ufifo_ov_sticky => ufifo_ov_sticky,
        ufifo_un_sticky => ufifo_un_sticky,
        dfifo_ov_sticky => dfifo_ov_sticky,
        dfifo_un_sticky => dfifo_un_sticky
	);
    
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
        
        read_time     => read_time     ,
        write_time    => write_time    ,  
        request_error => request_error ,  
        load_error    => load_error    ,  
        timeout_error => timeout_error ,
    
        mem_uline_loaded      => mem_uline_loaded       ,       
        mem_uline_loaded_sof  => mem_uline_loaded_sof   ,
        mem_dvideo_en         => mem_dvideo_en          ,
        mem_dreq_line         => mem_dreq_line          ,
        mem_dreq_line_sof     => mem_dreq_line_sof      ,

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