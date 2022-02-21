library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
	
--Structural connection from FIFO logic to arbiter
    
use work.axi_pkg.all;
    
entity dualframebuffer is
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

        rst               : in  std_logic;

        a_fifo_status     : out std_logic_vector(7 downto 0) := (others => '0');
        a_request_error   : out std_logic := '0';
        a_load_error      : out std_logic := '0';
        a_timeout_error   : out std_logic := '0';
        
        b_fifo_status     : out std_logic_vector(7 downto 0) := (others => '0');
        b_request_error   : out std_logic := '0';
        b_load_error      : out std_logic := '0';
        b_timeout_error   : out std_logic := '0';
        
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
		a_upstream_clk   : in  std_logic;
		a_pixel_in       : in  std_logic_vector(PIXEL_WIDTH-1 downto 0);
		a_pixel_in_valid : in  std_logic;
		a_pixel_in_sof   : in  std_logic;
		a_pixel_in_eol   : in  std_logic;
        
		b_upstream_clk   : in  std_logic;
		b_pixel_in       : in  std_logic_vector(PIXEL_WIDTH-1 downto 0);
		b_pixel_in_valid : in  std_logic;
		b_pixel_in_sof   : in  std_logic;
		b_pixel_in_eol   : in  std_logic;
        
		--output stream side (downstream)
		downstream_clk  : in  std_logic;
        
		a_pixel_out     : out std_logic_vector(PIXEL_WIDTH-1 downto 0) := (others => '0');
        b_pixel_out     : out std_logic_vector(PIXEL_WIDTH-1 downto 0) := (others => '0');
		pixel_out_valid : out std_logic := '0';
		pixel_out_sof   : out std_logic := '0';
		pixel_out_eol   : out std_logic := '0';
        
        --axi memory
        aclk         : in std_logic;
        a_axi4_m2s_o : out axi4_m2s := axi4_m2s_init;
        a_axi4_s2m_i : in  axi4_s2m := axi4_s2m_init;
        a_axi4_wdata : out std_logic_vector(DATA_WIDTH-1 downto 0);
        a_axi4_rdata : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        
        b_axi4_m2s_o : out axi4_m2s := axi4_m2s_init;
        b_axi4_s2m_i : in  axi4_s2m := axi4_s2m_init;
        b_axi4_wdata : out std_logic_vector(DATA_WIDTH-1 downto 0);
        b_axi4_rdata : in  std_logic_vector(DATA_WIDTH-1 downto 0)
  
	);
end dualframebuffer;

architecture str of dualframebuffer is 
    
    signal fs_1, fs_2 : std_logic := '0';

    signal a_pixel_out_valid : std_logic := '0';
    signal a_pixel_out_sof   : std_logic := '0';
    signal a_pixel_out_eol   : std_logic := '0';

    signal b_pixel_out_valid : std_logic := '0';
    signal b_pixel_out_sof   : std_logic := '0';
    signal b_pixel_out_eol   : std_logic := '0';
    
begin    

	a_framebuffer_inst : entity work.framebuffer2
	generic map(
        PIXEL_WIDTH       => PIXEL_WIDTH,
		DATA_WIDTH        => DATA_WIDTH,
        XFER_TIMEOUT      => AXI_TIMEOUT,
        MAX_BURST         => AXI_MAX_BURST,
		h_active          => h_active ,
		v_active          => v_active ,
		h_total           => h_total,
		v_total           => v_total,
        INCLUDE_FX        => FRAMEBUFFER_FX

	)
	port map(
    
        rst                    => rst,

        fifo_status            => a_fifo_status,
        request_error          => a_request_error        ,
        load_error             => a_load_error           ,
        timeout_error          => a_timeout_error        ,
        
        vert_bypass            => reg_vert_bypass          ,
        vert_splitscreen       => reg_vert_splitscreen     ,
        vert_splitscreen_type  => reg_vert_splitscreen_type, 
        vert_flip              => reg_vert_flip            ,
        vert_mirror            => reg_vert_mirror          ,
        vert_scroll            => reg_vert_scroll          ,
        vert_scroll_offset     => reg_vert_scroll_offset   ,
        horz_bypass            => reg_horz_bypass          ,
        horz_splitscreen       => reg_horz_splitscreen     ,
        horz_splitscreen_type  => reg_horz_splitscreen_type,
        horz_flip              => reg_horz_flip            ,
        horz_mirror            => reg_horz_mirror          ,
        horz_scroll            => reg_horz_scroll          ,
        horz_scroll_offset     => reg_horz_scroll_offset   ,
    
		--input stream side (upstream)
		upstream_clk     => a_upstream_clk,
		pixel_in         => a_pixel_in,
		pixel_in_valid   => a_pixel_in_valid,
		pixel_in_sof     => a_pixel_in_sof,
		pixel_in_eol     => a_pixel_in_eol,
		
        frame_sync  => fs_1, 
        video_ready => fs_2,
        
		--output stream side (downstream)
		downstream_clk   => downstream_clk,
		pixel_out        => a_pixel_out,
		pixel_out_valid  => a_pixel_out_valid,
		pixel_out_sof    => a_pixel_out_sof,
		pixel_out_eol    => a_pixel_out_eol,
        
        --axi memory
		aclk       => aclk,
		axi4_m2s_o => a_axi4_m2s_o,
        axi4_s2m_i => a_axi4_s2m_i,
        axi4_wdata => a_axi4_wdata,
        axi4_rdata => a_axi4_rdata

	);

	a_framebuffer_inst : entity work.framebuffer2
	generic map(
        PIXEL_WIDTH       => PIXEL_WIDTH,
		DATA_WIDTH        => DATA_WIDTH,
        XFER_TIMEOUT      => AXI_TIMEOUT,
        MAX_BURST         => AXI_MAX_BURST,
		h_active          => h_active ,
		v_active          => v_active ,
		h_total           => h_total,
		v_total           => v_total,
        INCLUDE_FX        => FRAMEBUFFER_FX

	)
	port map(
    
        rst                    => rst,

        fifo_status            => b_fifo_status,
        request_error          => b_request_error        ,
        load_error             => b_load_error           ,
        timeout_error          => b_timeout_error        ,
        
        vert_bypass            => reg_vert_bypass          ,
        vert_splitscreen       => reg_vert_splitscreen     ,
        vert_splitscreen_type  => reg_vert_splitscreen_type, 
        vert_flip              => reg_vert_flip            ,
        vert_mirror            => reg_vert_mirror          ,
        vert_scroll            => reg_vert_scroll          ,
        vert_scroll_offset     => reg_vert_scroll_offset   ,
        horz_bypass            => reg_horz_bypass          ,
        horz_splitscreen       => reg_horz_splitscreen     ,
        horz_splitscreen_type  => reg_horz_splitscreen_type,
        horz_flip              => reg_horz_flip            ,
        horz_mirror            => reg_horz_mirror          ,
        horz_scroll            => reg_horz_scroll          ,
        horz_scroll_offset     => reg_horz_scroll_offset   ,
    
		--input stream side (upstream)
		upstream_clk     => b_upstream_clk,
		pixel_in         => b_pixel_in,
		pixel_in_valid   => b_pixel_in_valid,
		pixel_in_sof     => b_pixel_in_sof,
		pixel_in_eol     => b_pixel_in_eol,
		
        frame_sync  => fs_2, 
        video_ready => fs_1,
        
		--output stream side (downstream)
		downstream_clk   => downstream_clk,
		pixel_out        => b_pixel_out,
		pixel_out_valid  => b_pixel_out_valid,
		pixel_out_sof    => b_pixel_out_sof,
		pixel_out_eol    => b_pixel_out_eol,
        
        --axi memory
		aclk       => aclk,
		axi4_m2s_o => b_axi4_m2s_o,
        axi4_s2m_i => b_axi4_s2m_i,
        axi4_wdata => b_axi4_wdata,
        axi4_rdata => b_axi4_rdata

	);

    pixel_out_sof <= a_pixel_out_sof and b_pixel_out_sof;
    pixel_out_eol <= a_pixel_out_eol and b_pixel_out_eol;
    pixel_out_valid <= a_pixel_out_valid and b_pixel_out_valid;
    

end str;