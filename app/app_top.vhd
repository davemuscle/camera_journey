library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

--Camera System, Stream IO Application Level

use work.axi_pkg.all;

entity app_top is
    generic(
        PIXEL_WIDTH    : integer := 32;
        DATA_WIDTH     : integer := 256;
        h_active       : integer := 1920;
        h_frontporch   : integer := 88;
        h_syncwidth    : integer := 44;
        h_backporch    : integer := 148;
        h_total        : integer := 2200;
        v_active       : integer := 1080;
        v_frontporch   : integer := 4;
        v_syncwidth    : integer := 5;
        v_backporch    : integer := 36;
        v_total        : integer := 1125;
        SIM            : boolean := false;
        CLK_DIV_1ms    : integer := 50000;
        I2C_CLK_DIV    : integer := 500;
        HPD_CHECKRATE  : integer := 50000000;
        AXI_TIMEOUT    : integer := 10000000;
        AXI_MAX_BURST  : integer := 8;
        FRAMEBUFFER_FX : boolean := true;
        UART_CLKRATE   : integer := 50000000;
        UART_BAUDRATE  : integer := 115200;
        ENABLE_BOOT    : boolean := true
    );
	port(
        --external reset
        reset_ext  : in std_logic;
        
        --clocks
		clk_board : in std_logic;
        cam_a_pclk  : in std_logic;
        cam_b_pclk  : in std_logic;
        ddr_clk   : in std_logic;
        pclk      : in std_logic;
		
        --uart debugger
        tx        : out std_logic;
        rx        : in  std_logic;
        
        --camera A
        cam_a_sda           : inout std_logic;
        cam_a_scl           : inout std_logic;
        cam_a_xclk_disable  : out   std_logic;
		cam_a_reset         : out   std_logic;
		cam_a_pwdn          : out   std_logic;
        cam_a_data          : in    std_logic_vector(7 downto 0);
        cam_a_href          : in    std_logic;
        cam_a_vsync         : in    std_logic;
        
        --camera B
        cam_b_sda           : inout std_logic;
        cam_b_scl           : inout std_logic;
        cam_b_xclk_disable  : out   std_logic;
	    cam_b_reset         : out   std_logic;
	    cam_b_pwdn          : out   std_logic;
        cam_b_data          : in    std_logic_vector(7 downto 0);
        cam_b_href          : in    std_logic;
        cam_b_vsync         : in    std_logic;
        
        
        --test output stream
        tb_out_sof   : out std_logic;
        tb_out_eol   : out std_logic;
        tb_out_valid : out std_logic;
        tb_out_data  : out std_logic_vector(23 downto 0);
        
        --adv7513 control
 		hdmi_sda : inout std_logic;
		hdmi_scl : inout std_logic;   
    
        --adv7513 VGA output stream
		vga_hsync : out std_logic;
		vga_vsync : out std_logic;
		vga_de    : out std_logic;
		vga_out   : out std_logic_vector(23 downto 0) := (others => '0');
        
        --status signals to LEDs
        leds    : out std_logic_vector(7 downto 0) := (others => '0');
		
        --framebuffer memory
        framebuffer_axi_m2s   : out axi4_m2s;
        framebuffer_axi_s2m   : in  axi4_s2m;
        framebuffer_axi_wdata : out std_logic_vector(DATA_WIDTH-1 downto 0);
        framebuffer_axi_rdata : in  std_logic_vector(DATA_WIDTH-1 downto 0)

	);
end app_top;

architecture arch of app_top is 
	
    ----------------------------------------------------------------------------------------
    -- Resets
    ----------------------------------------------------------------------------------------
    signal reset   : std_logic := '0';
    signal reset_n : std_logic := '1';
    ----------------------------------------------------------------------------------------
    -- Pixel Stream: OV5640 to AXI Stream
    ----------------------------------------------------------------------------------------

    signal cam_a_stream_sof   : std_logic := '0';
    signal cam_a_stream_eol   : std_logic := '0';
    signal cam_a_stream_valid : std_logic := '0';
    signal cam_a_stream_data  : std_logic_vector(7 downto 0) := (others => '0');

    signal cam_b_stream_sof   : std_logic := '0';
    signal cam_b_stream_eol   : std_logic := '0';
    signal cam_b_stream_valid : std_logic := '0';
    signal cam_b_stream_data  : std_logic_vector(7 downto 0) := (others => '0');

    signal cam_stream_sof   : std_logic := '0';
    signal cam_stream_eol   : std_logic := '0';
    signal cam_stream_valid : std_logic := '0';
    signal cam_stream_data  : std_logic_vector(47 downto 0) := (others => '0');
    ----------------------------------------------------------------------------------------
    --  Pixel Stream: Framebuffer Upstream and Downstream
    ----------------------------------------------------------------------------------------
	signal pixel_out_sof   : std_logic := '0';
    signal pixel_out_eol   : std_logic := '0';
    signal pixel_out_valid : std_logic := '0';
	signal pixel_in_sof    : std_logic := '0';
    signal pixel_in_eol    : std_logic := '0';
    signal pixel_in_valid  : std_logic := '0';
	signal pixel_in        : std_logic_vector(PIXEL_WIDTH-1 downto 0) := (others => '0'); 
    signal pixel_out       : std_Logic_vector(PIXEL_WIDTH-1 downto 0) := (others => '0');
    signal pixel_a_in : std_logic_vector(PIXEL_WIDTH_1 downto 0) := (others => '0');
    signal pixel_b_in : std_logic_vector(PIXEL_WIDTH_1 downto 0) := (others => '0');
    signal pixel_a_sof : std_logic := '0';
    signal pixel_b_sof : std_logic := '0';
    signal pixel_a_eol : std_logic := '0';
    signal pixel_b_eol : std_logic := '0';
    signal pixel_a_vld : std_logic := '0';
    signal pixel_b_vld : std_logic := '0';
    ----------------------------------------------------------------------------------------
    -- Pixel Stream: Debayer
    ----------------------------------------------------------------------------------------
    signal debayer_a_sof      : std_logic := '0';
    signal debayer_a_eol      : std_logic := '0';
    signal debayer_a_valid    : std_logic := '0';
    signal debayer_a_data     : std_logic_vector(23 downto 0) := (others => '0');
    
    signal debayer_b_sof      : std_logic := '0';
    signal debayer_b_eol      : std_logic := '0';
    signal debayer_b_valid    : std_logic := '0';
    signal debayer_b_data     : std_logic_vector(23 downto 0) := (others => '0');
    
    ----------------------------------------------------------------------------------------
    -- ADV7513
    ----------------------------------------------------------------------------------------
	signal adv7513_done : std_logic := '0';
	signal adv7513_hpd  : std_logic := '0';
    signal t_vga_hsync : std_logic := '0';
    signal t_vga_vsync : std_logic := '0';
    signal t_vga_de    : std_logic := '0';
    signal t_vga_out   : std_logic_vector(23 downto 0) := (others => '0');
    ----------------------------------------------------------------------------------------
    -- OV5640
    ----------------------------------------------------------------------------------------
    signal cam_init_reset : std_logic := '0';
    ----------------------------------------------------------------------------------------
    -- Pattern Generators
    ----------------------------------------------------------------------------------------
    signal pat_gen_cam_sof      : std_logic := '0';
    signal pat_gen_cam_eol      : std_logic := '0';
    signal pat_gen_cam_valid    : std_logic := '0';
    signal pat_gen_cam_data     : std_logic_vector(7 downto 0) := (others => '0');

    signal pat_gen_debayer_sof      : std_logic := '0';
    signal pat_gen_debayer_eol      : std_logic := '0';
    signal pat_gen_debayer_valid    : std_logic := '0';
    signal pat_gen_debayer_data     : std_logic_vector(23 downto 0) := (others => '0');

    signal pat_gen_frm_sof      : std_logic := '0';
    signal pat_gen_frm_eol      : std_logic := '0';
    signal pat_gen_frm_valid    : std_logic := '0';
    signal pat_gen_frm_data     : std_logic_vector(23 downto 0) := (others => '0');
    
    signal conv_data : std_logic_vector(23 downto 0) := (others => '0');
    signal conv_valid : std_logic := '0';
    signal conv_sof   : std_logic := '0';
    signal conv_eol   : std_logic := '0';    
    ----------------------------------------------------------------------------------------
    -- UART Debugger Signals
    ----------------------------------------------------------------------------------------
    signal rm_wr_en, rm_rd_en, rm_rd_valid : std_logic := '0';
    signal rm_addr : std_logic_vector(15 downto 0) := (others => '0');
    signal rm_wr_data, rm_rd_data : std_logic_vector(31 downto 0) := (others => '0');
    signal uart_fifo_status : std_logic_vector(3 downto 0) := (others => '0');
    ----------------------------------------------------------------------------------------
    -- Camera Signals to UART Debugger
    ----------------------------------------------------------------------------------------
    signal reg_camera_init_go     : std_logic_vector(1 downto 0) := "00"; 
    signal reg_camera_init_sel    : std_logic_vector(1 downto 0) := "00";
    signal reg_camera_fid         : std_logic_vector(1 downto 0) := "00";             
    signal reg_camera_wr          : std_logic_vector(1 downto 0) := "00";  
    signal reg_camera_fifo_wr     : std_logic_vector(1 downto 0) := "00";
    signal reg_camera_addr        : std_logic_vector(31 downto 0) := (others => '0');
    signal reg_camera_wr_data     : std_logic_vector(15 downto 0) := (others => '0');
    signal reg_camera_rd          : std_logic_vector(1 downto 0) := "00";
    signal reg_camera_rd_data     : std_logic_vector(15 downto 0) := (others => '0');
    signal reg_camera_init_done   : std_logic_vector(1 downto 0) := "00";
    signal reg_camera_boot_done   : std_logic_vector(1 downto 0) := "00";
    signal reg_camera_cmd_busy    : std_logic_vector(1 downto 0) := "00";
    signal reg_camera_pwr_up_done : std_logic_vector(1 downto 0) := "00";
    signal reg_camera_pclk_freq   : std_logic_vector(63 downto 0) := (others => '0');
    ----------------------------------------------------------------------------------------
    -- Videopipe Signals to UART Debugger
    ----------------------------------------------------------------------------------------
    signal reg_vp_reset        : std_logic := '0';
    signal reg_vp_cam_mux      : std_logic := '0';
    signal reg_vp_frm_mux      : std_logic := '0';
    signal reg_vp_dem_mux      : std_logic := '0';
    signal reg_vp_debayer_mode : std_logic_vector(1 downto 0) := (others => '0');
    signal reg_vp_overlay      : std_logic := '0';
    signal reg_vp_debayer_bypass      : std_logic := '0';
    signal reg_vp_camera_select      : std_logic := '0';
    ----------------------------------------------------------------------------------------
    -- Framebuffer Signals to UART Debugger
    ----------------------------------------------------------------------------------------
    signal reg_ufifo_ov_sticky       : std_logic;
    signal reg_ufifo_un_sticky       : std_logic;
    signal reg_dfifo_ov_sticky       : std_logic;
    signal reg_dfifo_un_sticky       : std_logic;
    signal reg_read_time             : std_logic_vector(11 downto 0);
    signal reg_write_time            : std_logic_vector(11 downto 0);
    signal reg_request_error         : std_logic;
    signal reg_load_error            : std_logic;
    signal reg_timeout_error         : std_logic;
    signal reg_vert_bypass           : std_logic := '0';
    signal reg_vert_splitscreen      : std_logic := '0';
    signal reg_vert_splitscreen_type : std_logic_vector(5 downto 0) := (others => '0');
    signal reg_vert_flip             : std_logic := '0';
    signal reg_vert_mirror           : std_logic := '0';
    signal reg_vert_scroll           : std_logic := '0';
    signal reg_vert_scroll_offset    : std_logic_vector(11 downto 0) := (others => '0');
    signal reg_horz_bypass           : std_logic := '0';
    signal reg_horz_splitscreen      : std_logic := '0';
    signal reg_horz_splitscreen_type : std_logic_vector(5 downto 0) := (others => '0');
    signal reg_horz_flip             : std_logic := '0';
    signal reg_horz_mirror           : std_logic := '0';
    signal reg_horz_scroll           : std_logic := '0';
    signal reg_horz_scroll_offset    : std_logic_vector(11 downto 0) := (others => '0');


    signal line_sync_err : std_logic := '0';
    signal sync_error    : std_logic := '0';
    
    signal debayer_valid_dly : std_logic := '0';
    
    --signal cam_xclk_disable : std_logic := '0';
    
    signal stream_aligner_error : std_logic := '0';
    
    signal frex_a : std_logic := '0';
    signal frex_b : std_logic := '0';
    signal frex_a_count : unsigned(11 downto 0) := (others => '0');
    signal frex_b_count : unsigned(11 downto 0) := (others => '0');

begin

    reset   <= reset_ext or reg_vp_reset;
    reset_n <= not reset;

    leds(0) <= adv7513_hpd;
    leds(1) <= adv7513_done;
    leds(2) <= reg_camera_init_done(0);
    leds(3) <= reg_camera_init_done(1);
    leds(4) <= stream_aligner_error;
    leds(5) <= reg_ufifo_ov_sticky or reg_ufifo_un_sticky or reg_dfifo_ov_sticky or reg_dfifo_un_sticky;
    leds(6) <= uart_fifo_status(3) or uart_fifo_status(2) or uart_fifo_status(1) or uart_fifo_status(0);
    leds(7) <= reset;

    --Uart interface for register debug
 	uart_db_inst : entity work.uart_debugger
    generic map(
		CLKRATE  => UART_CLKRATE,
		BAUDRATE => UART_BAUDRATE,
		DATA_SIZE =>  8,
		FIFO_SIZE => 16
    )
	port map(
		clk => clk_board,
        
        rx => rx,
        tx => tx,
        
        uart_fifo_status => uart_fifo_status,
        
		rm_wr_en    => rm_wr_en,
        rm_rd_en    => rm_rd_en,
        rm_rd_valid => rm_rd_valid,
        rm_addr     => rm_addr,
        rm_wr_data  => rm_wr_data,
        rm_rd_data  => rm_rd_data
	);
    
    --Uart interface for register debug
 	camera_bridge_top_regfile_inst : entity work.camera_bridge_top_regfile
	port map(
		clk         => clk_board,
        ddr_clk     => ddr_clk,
		rm_wr_en    => rm_wr_en,
        rm_rd_en    => rm_rd_en,
        rm_rd_valid => rm_rd_valid,
        rm_addr     => rm_addr,
        rm_wr_data  => rm_wr_data,
        rm_rd_data  => rm_rd_data,
       
        reg_camera_init_go      => reg_camera_init_go     ,
        reg_camera_init_sel     => reg_camera_init_sel    ,
        reg_camera_fid          => reg_camera_fid         ,
        reg_camera_addr         => reg_camera_addr        ,
        reg_camera_wr           => reg_camera_wr          ,
        reg_camera_fifo_wr      => reg_camera_fifo_wr     ,
        reg_camera_wr_data      => reg_camera_wr_data     ,
        reg_camera_rd           => reg_camera_rd          ,
        reg_camera_rd_data      => reg_camera_rd_data     ,
        reg_camera_init_done    => reg_camera_init_done   ,
        reg_camera_boot_done    => reg_camera_boot_done          ,
        reg_camera_cmd_busy     => reg_camera_cmd_busy           ,
        reg_camera_pwr_up_done  => reg_camera_pwr_up_done        ,
        reg_camera_pclk_freq    => reg_camera_pclk_freq,
        
        reg_vp_reset            => reg_vp_reset        ,
        reg_vp_cam_mux          => reg_vp_cam_mux      ,
        reg_vp_frm_mux          => reg_vp_frm_mux      ,
        reg_vp_dem_mux          => reg_vp_dem_mux      ,
        reg_vp_debayer_mode     => reg_vp_debayer_mode ,
        reg_vp_debayer_bypass   => reg_vp_debayer_bypass,
        reg_vp_camera_select    => reg_vp_camera_select,
 
        reg_ufifo_ov_sticky       => reg_ufifo_ov_sticky       ,
        reg_ufifo_un_sticky       => reg_ufifo_un_sticky       ,
        reg_dfifo_ov_sticky       => reg_dfifo_ov_sticky       ,
        reg_dfifo_un_sticky       => reg_dfifo_un_sticky       ,
        reg_read_time             => reg_read_time             ,
        reg_write_time            => reg_write_time            ,
        reg_request_error         => reg_request_error         ,        
        reg_load_error            => reg_load_error            ,
        reg_timeout_error         => reg_timeout_error         ,
        reg_vert_bypass           => reg_vert_bypass           ,
        reg_vert_splitscreen      => reg_vert_splitscreen      ,
        reg_vert_splitscreen_type => reg_vert_splitscreen_type ,
        reg_vert_flip             => reg_vert_flip             ,
        reg_vert_mirror           => reg_vert_mirror           ,
        reg_vert_scroll           => reg_vert_scroll           ,
        reg_vert_scroll_offset    => reg_vert_scroll_offset    ,
        reg_horz_bypass           => reg_horz_bypass           ,
        reg_horz_splitscreen      => reg_horz_splitscreen      ,
        reg_horz_splitscreen_type => reg_horz_splitscreen_type ,
        reg_horz_flip             => reg_horz_flip             ,
        reg_horz_mirror           => reg_horz_mirror           ,
        reg_horz_scroll           => reg_horz_scroll           ,
        reg_horz_scroll_offset    => reg_horz_scroll_offset    

	);

    --Camera A
    camera_a_wrapper_inst : entity work.ov5640_wrapper
    generic map(
        I2C_CLK_DIV => I2C_CLK_DIV,
        CLK_DIV_1ms => CLK_DIV_1ms,
        SIM         => SIM,
        ENABLE_BOOT => ENABLE_BOOT
    )
    port map(
        clk => clk_board,

        reg_camera_init_go      => reg_camera_init_go(0)                   ,
        reg_camera_init_sel     => reg_camera_init_sel(0)                  ,
        reg_camera_fid          => reg_camera_fid(0)                       ,
        reg_camera_addr         => reg_camera_addr(15 downto 0) ,
        reg_camera_wr           => reg_camera_wr(0)                        ,
        reg_camera_fifo_wr      => reg_camera_fifo_wr(0)                   ,
        reg_camera_wr_data      => reg_camera_wr_data(7 downto 0),
        reg_camera_rd           => reg_camera_rd(0)                        ,
        reg_camera_rd_data      => reg_camera_rd_data(7 downto 0),
        reg_camera_init_done    => reg_camera_init_done(0)                 ,
        reg_boot_done           => reg_camera_boot_done(0)                 ,
        reg_cmd_busy            => reg_camera_cmd_busy(0)                  ,
        reg_pwr_up_done         => reg_camera_pwr_up_done(0)               ,
        
        manual_reset            => open,
        
        cam_sda                 => cam_a_sda,
        cam_scl                 => cam_a_scl,
        
        cam_xclk_disable        => cam_a_xclk_disable,
        cam_reset               => cam_a_reset,
        cam_pwdn                => cam_a_pwdn

    );
    
    --Camera B
    camera_b_wrapper_inst : entity work.ov5640_wrapper
    generic map(
        I2C_CLK_DIV => I2C_CLK_DIV,
        CLK_DIV_1ms => CLK_DIV_1ms,
        SIM         => SIM,
        ENABLE_BOOT => ENABLE_BOOT
    )
    port map(
        clk => clk_board,

        reg_camera_init_go      => reg_camera_init_go(1)                   ,
        reg_camera_init_sel     => reg_camera_init_sel(1)                  ,
        reg_camera_fid          => reg_camera_fid(1)                       ,
        reg_camera_addr         => reg_camera_addr(31 downto 16) ,
        reg_camera_wr           => reg_camera_wr(1)                        ,
        reg_camera_fifo_wr      => reg_camera_fifo_wr(1)                   ,
        reg_camera_wr_data      => reg_camera_wr_data(15 downto 8),
        reg_camera_rd           => reg_camera_rd(1)                        ,
        reg_camera_rd_data      => reg_camera_rd_data(15 downto 8),
        reg_camera_init_done    => reg_camera_init_done(1)                 ,
        reg_boot_done           => reg_camera_boot_done(1)                 ,
        reg_cmd_busy            => reg_camera_cmd_busy(1)                  ,
        reg_pwr_up_done         => reg_camera_pwr_up_done(1)               ,

        manual_reset            => open,
        
        cam_sda                 => cam_b_sda,
        cam_scl                 => cam_b_scl,
        
        cam_xclk_disable        => cam_b_xclk_disable,
        cam_reset               => cam_b_reset,
        cam_pwdn                => cam_b_pwdn

    );
    
    cam_a_stream : entity work.dvp2stream
    generic map(
        DATA_WIDTH     => 8,
        FRAMES_TO_LOCK => 3
    )
    port map(
        clk    => cam_a_pclk,
        reset  => reset,
        
        href_i  => cam_a_href,
        vsync_i => cam_a_vsync,
        data_i  => cam_a_data,
        
        sof_o   => cam_a_stream_sof,
        eol_o   => cam_a_stream_eol,
        vld_o   => cam_a_stream_valid,
        data_o  => cam_a_stream_data
       
    );
    
    cam_b_stream : entity work.dvp2stream
    generic map(
        DATA_WIDTH     => 8,
        FRAMES_TO_LOCK => 3
    )
    port map(
        clk    => cam_b_pclk,
        reset  => reset,
        
        href_i  => cam_b_href,
        vsync_i => cam_b_vsync,
        data_i  => cam_b_data,
        
        sof_o   => cam_b_stream_sof,
        eol_o   => cam_b_stream_eol,
        vld_o   => cam_b_stream_valid,
        data_o  => cam_b_stream_data
       
    );
        
    debayer_a_inst : entity work.debayer
    generic map(
        H_ACTIVE   => h_active,
        V_ACTIVE   => v_active
    )
    port map(
        clk          => cam_a_pclk,
        reset        => reset,
        
        mode         => reg_vp_debayer_mode,
        buffer_error => open,
        bypass       => reg_vp_debayer_bypass,
        
        sof_i        => cam_a_stream_sof,
        eol_i        => cam_a_stream_eol,
        vld_i        => cam_a_stream_valid,
        dat_i        => cam_a_stream_data,

        sof_o        => debayer_a_sof,
        eol_o        => debayer_a_eol,
        vld_o        => debayer_a_valid,
        dat_o        => debayer_a_data 
    );
    
    debayer_b_inst : entity work.debayer
    generic map(
        H_ACTIVE   => h_active,
        V_ACTIVE   => v_active
    )
    port map(
        clk          => cam_b_pclk,
        reset        => reset,
        
        mode         => reg_vp_debayer_mode,
        buffer_error => open,
        bypass       => reg_vp_debayer_bypass,
        
        sof_i        => cam_b_stream_sof,
        eol_i        => cam_b_stream_eol,
        vld_i        => cam_b_stream_valid,
        dat_i        => cam_b_stream_data,

        sof_o        => debayer_b_sof,
        eol_o        => debayer_b_eol,
        vld_o        => debayer_b_valid,
        dat_o        => debayer_b_data 
    );
        

    dual_cam_pclk_monitor: entity work.frequency_monitor
	generic map(
        REFCLK_CNT_MAX => 50000000
    )
	port map(
	    refclk => clk_board,
        clk_a  => cam_a_pclk,
        clk_b  => cam_b_pclk,
        frq_a  => reg_camera_pclk_freq(31 downto 0),
        frq_b  => reg_camera_pclk_freq(63 downto 32)
       
    );
    
    --Convert to RGB565 (take three bits off red and blue, two off green)
    pixel_a_in(4 downto 0)   <= debayer_a_data(7 downto 3);
    pixel_a_in(10 downto 5)  <= debayer_a_data(15 downto 10);
    pixel_a_in(15 downto 11) <= debayer_a_data(23 downto 19);
    pixel_a_vld              <= debayer_a_valid; 
    pixel_a_eol              <= debayer_a_eol; 
    pixel_a_sof              <= debayer_a_sof; 
    
    pixel_b_in(4 downto 0)   <= debayer_b_data(7 downto 3);
    pixel_b_in(10 downto 5)  <= debayer_b_data(15 downto 10);
    pixel_b_in(15 downto 11) <= debayer_b_data(23 downto 19);
    pixel_b_vld              <= debayer_b_valid; 
    pixel_b_eol              <= debayer_b_eol; 
    pixel_b_sof              <= debayer_b_sof; 
    
    --pixel_in(20 downto 16) <= cam_stream_data(7+24 downto 3+24);
    --pixel_in(26 downto 21) <= cam_stream_data(15+24 downto 10+24);
    --pixel_in(31 downto 27) <= cam_stream_data(23+24 downto 19+24);
    --pixel_in_valid         <= cam_stream_valid; 
    --pixel_in_eol           <= cam_stream_eol; 
    --pixel_in_sof           <= cam_stream_sof; 

	framebuffer_inst : entity work.framebuffer
	generic map(
        PIXEL_WIDTH       => PIXEL_WIDTH,
		DATA_WIDTH        => DATA_WIDTH,
        XFER_TIMEOUT      => AXI_TIMEOUT,
        MAX_BURST         => AXI_MAX_BURST,
		h_active          => h_active ,
		v_active          => v_active ,
		h_blank           => h_frontporch+h_backporch+h_syncwidth,
		v_blank           => v_frontporch+v_backporch+v_syncwidth,
        INCLUDE_FX        => FRAMEBUFFER_FX

	)
	port map(
    
        rst                    => reset,

        ufifo_ov_sticky        => reg_ufifo_ov_sticky      ,
        ufifo_un_sticky        => reg_ufifo_un_sticky      ,
        dfifo_ov_sticky        => reg_dfifo_ov_sticky      ,
        dfifo_un_sticky        => reg_dfifo_un_sticky      ,
        read_time              => reg_read_time            ,
        write_time             => reg_write_time           ,
        request_error          => reg_request_error        ,
        load_error             => reg_load_error           ,
        timeout_error          => reg_timeout_error        ,
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
		upstream_clk     => cam_a_pclk,
		pixel_in         => pixel_in,
		pixel_in_valid   => pixel_in_valid,
		pixel_in_sof     => pixel_in_sof,
		pixel_in_eol     => pixel_in_eol,
		
		--output stream side (downstream)
		downstream_clk   => pclk,
		pixel_out        => pixel_out,
		pixel_out_valid  => pixel_out_valid,
		pixel_out_sof    => pixel_out_sof,
		pixel_out_eol    => pixel_out_eol,
        
        --axi memory
		aclk       => ddr_clk,
		axi4_m2s_o => framebuffer_axi_m2s,
        axi4_s2m_i => framebuffer_axi_s2m,
        axi4_wdata => framebuffer_axi_wdata,
        axi4_rdata => framebuffer_axi_rdata

		
	);

    --Switch between camera outputs
    process(pixel_out, reg_vp_camera_select)
    begin
        if(reg_vp_camera_select = '0') then
            conv_data  <= pixel_out(15 downto 11) & "000" & 
                          pixel_out( 10 downto 5) &  "00" & 
                          pixel_out( 4 downto  0) & "000";

        else
            conv_data  <= pixel_out(15+16 downto 11+16) & "000" & 
                          pixel_out(10+16 downto  5+16) &  "00" & 
                          pixel_out( 4+16 downto  0+16) & "000";
        end if;
    end process;

    
    conv_valid <= pixel_out_valid; 
    conv_eol   <= pixel_out_eol; 
    conv_sof   <= pixel_out_sof; 
    
    tb_out_sof   <= conv_sof;
    tb_out_eol   <= conv_eol;
    tb_out_valid <= conv_valid;
    tb_out_data  <= conv_data;
    
	--convert video stream to vga output
	stream_converter : entity work.vstream2vga
	generic map(
		DATA_WIDTH   => 24,
		SYNC_POL     => '0',
	    h_active 	 => h_active 	,
	    h_frontporch => h_frontporch,
	    h_syncwidth  => h_syncwidth ,
	    h_backporch  => h_backporch ,
	    h_total      => h_total     ,
	    v_active     => v_active    ,
	    v_frontporch => v_frontporch,
	    v_syncwidth  => v_syncwidth ,
	    v_backporch  => v_backporch ,
	    v_total		 => v_total		
	)
	port map(
		clk   => pclk,
		reset => reset,
		
		data_in    => conv_data,
		valid_in   => conv_valid,
		sof_in     => conv_sof,
		eol_in     => conv_eol,
		
		data_out   => t_vga_out, --[R / G / B]
		hsync      => t_vga_hsync,
		vsync      => t_vga_vsync,
		de         => t_vga_de,
		sync_error => sync_error

	);	
    
    process(pclk)
    begin
        if(rising_edge(pclk)) then
            vga_out   <= t_vga_out;
            vga_hsync <= t_vga_hsync;
            vga_vsync <= t_vga_vsync;
            vga_de    <= t_vga_de;
        end if;
    end process;
	
    adv7513_hdmi_if_inst : entity work.adv7513_hdmi_if
	generic map(
		DEV_ADDR      => "0111001",
		HPD_CHECKRATE => HPD_CHECKRATE,
		I2C_CLK_DIV   => I2C_CLK_DIV     
	)
	port map(
    	clk => clk_board,

		--i2c pins
		sda => hdmi_sda,
		scl => hdmi_scl,
		
		--status signals
		hpd_detect_o => adv7513_hpd,
		init_done_o  => adv7513_done,
		init_busy_o  => open
    );
	
    --Pattern generator to replace camera
	--pat_gen_cam_inst : entity work.pattern_generator
	--generic map(
	--    USE_BLANKING => true,
    --    USE_IMG_FILE => false,
    --    i_file       => "../video/verification/test_stream.txt",
    --    h_active     => h_active,
    --    h_total      => cam_h_total,
    --    v_active     => v_active,
    --    v_total      => cam_v_total
	--)
	--port map(
	--	clk      => cam_pclk,
	--	enable   => reset_n,
    --    pattern  => "01",
    --    movement => '1',
    --    
    --    rgb      => open,
    --    raw_BGGR => pat_gen_cam_data,
	--	raw_GBRG => open,
    --    raw_GRBG => open,
    --    raw_RGGB => open,
    --    
    --    valid => pat_gen_cam_valid,
    --    sof   => pat_gen_cam_sof,
    --    eol   => pat_gen_cam_eol
    --
	--);
    --Pattern generator to replace debayer
 	--pat_gen_debayer_inst : entity work.pattern_generator
	--generic map(
	--    USE_BLANKING => true,
    --    USE_IMG_FILE => false,
    --    i_file       => "../video/verification/test_stream.txt",
    --    h_active     => h_active,
    --    h_total      => cam_h_total,
    --    v_active     => v_active,
    --    v_total      => cam_v_total
    --    
	--)
	--port map(
	--	clk      => cam_pclk,
	--	enable   => reset_n,
    --    pattern  => "00",
    --    movement => '0',
    --    
    --    rgb      => pat_gen_debayer_data,
    --    raw_BGGR => open,
	--	raw_GBRG => open,
    --    raw_GRBG => open,
    --    raw_RGGB => open,
    --    
    --    valid => pat_gen_debayer_valid,
    --    sof   => pat_gen_debayer_sof,
    --    eol   => pat_gen_debayer_eol
	--);  
    --Pattern generator to replace framebuffer
 	--pat_gen_frm_inst : entity work.pattern_generator
	--generic map(
	--    USE_BLANKING => true,
    --    USE_IMG_FILE => false,
    --    i_file       => "../video/verification/test_stream.txt",
    --    h_active     => h_active,
    --    h_total      => h_total,
    --    v_active     => v_active,
    --    v_total      => v_total
    --    
	--)
	--port map(
	--	clk      => pclk,
	--	enable   => reset_n,
    --    i_file   => "../video/verification/test_stream.txt",
    --    pattern  => "00",
    --    
    --    rgb      => pat_gen_frm_data,
    --    raw_BGGR => open,
	--	raw_GBRG => open,
    --    raw_GRBG => open,
    --    raw_RGGB => open,
    --    
    --    valid => pat_gen_frm_valid,
    --    sof   => pat_gen_frm_sof,
    --    eol   => pat_gen_frm_eol
	--);  
end arch;