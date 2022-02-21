library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

use work.axi_pkg.all;

entity top is
	port(
		clk_board : in  std_logic;
        leds      : out std_logic_vector(7 downto 0) := (others => '0');

		hdmi_sda  : inout std_logic;
		hdmi_scl  : inout std_logic;
		
		vga_clk   : out std_logic;
		vga_hsync : out std_logic;
		vga_vsync : out std_logic;
		vga_de    : out std_logic;
		vga_out   : out std_logic_vector(23 downto 0);

        io_hps_io_emac1_inst_TX_CLK : out   std_logic;                                         
        io_hps_io_emac1_inst_TXD0   : out   std_logic;                                         
        io_hps_io_emac1_inst_TXD1   : out   std_logic;                                         
        io_hps_io_emac1_inst_TXD2   : out   std_logic;                                         
        io_hps_io_emac1_inst_TXD3   : out   std_logic;                                         
        io_hps_io_emac1_inst_RXD0   : in    std_logic                      := 'X';             
        io_hps_io_emac1_inst_MDIO   : inout std_logic                      := 'X';             
        io_hps_io_emac1_inst_MDC    : out   std_logic;                                         
        io_hps_io_emac1_inst_RX_CTL : in    std_logic                      := 'X';             
        io_hps_io_emac1_inst_TX_CTL : out   std_logic;                                         
        io_hps_io_emac1_inst_RX_CLK : in    std_logic                      := 'X';             
        io_hps_io_emac1_inst_RXD1   : in    std_logic                      := 'X';             
        io_hps_io_emac1_inst_RXD2   : in    std_logic                      := 'X';             
        io_hps_io_emac1_inst_RXD3   : in    std_logic                      := 'X';             
        io_hps_io_sdio_inst_CMD     : inout std_logic                      := 'X';             
        io_hps_io_sdio_inst_D0      : inout std_logic                      := 'X';             
        io_hps_io_sdio_inst_D1      : inout std_logic                      := 'X';             
        io_hps_io_sdio_inst_CLK     : out   std_logic;                                         
        io_hps_io_sdio_inst_D2      : inout std_logic                      := 'X';             
        io_hps_io_sdio_inst_D3      : inout std_logic                      := 'X';             
        io_hps_io_usb1_inst_D0      : inout std_logic                      := 'X';             
        io_hps_io_usb1_inst_D1      : inout std_logic                      := 'X';             
        io_hps_io_usb1_inst_D2      : inout std_logic                      := 'X';             
        io_hps_io_usb1_inst_D3      : inout std_logic                      := 'X';             
        io_hps_io_usb1_inst_D4      : inout std_logic                      := 'X';             
        io_hps_io_usb1_inst_D5      : inout std_logic                      := 'X';             
        io_hps_io_usb1_inst_D6      : inout std_logic                      := 'X';             
        io_hps_io_usb1_inst_D7      : inout std_logic                      := 'X';             
        io_hps_io_usb1_inst_CLK     : in    std_logic                      := 'X';             
        io_hps_io_usb1_inst_STP     : out   std_logic;                                         
        io_hps_io_usb1_inst_DIR     : in    std_logic                      := 'X';             
        io_hps_io_usb1_inst_NXT     : in    std_logic                      := 'X';             
        io_hps_io_spim1_inst_CLK    : out   std_logic;                                         
        io_hps_io_spim1_inst_MOSI   : out   std_logic;                                         
        io_hps_io_spim1_inst_MISO   : in    std_logic                      := 'X';             
        io_hps_io_spim1_inst_SS0    : out   std_logic;                                         
        io_hps_io_uart0_inst_RX     : in    std_logic                      := 'X';             
        io_hps_io_uart0_inst_TX     : out   std_logic;                                         
        io_hps_io_i2c0_inst_SDA     : inout std_logic                      := 'X';             
        io_hps_io_i2c0_inst_SCL     : inout std_logic                      := 'X';             
        io_hps_io_i2c1_inst_SDA     : inout std_logic                      := 'X';             
        io_hps_io_i2c1_inst_SCL     : inout std_logic                      := 'X';             
        io_hps_io_gpio_inst_GPIO09  : inout std_logic                      := 'X';             
        io_hps_io_gpio_inst_GPIO35  : inout std_logic                      := 'X';             
        io_hps_io_gpio_inst_GPIO40  : inout std_logic                      := 'X';             
        io_hps_io_gpio_inst_GPIO53  : inout std_logic                      := 'X';             
        io_hps_io_gpio_inst_GPIO54  : inout std_logic                      := 'X';             
        io_hps_io_gpio_inst_GPIO61  : inout std_logic                      := 'X';             
        ddr3_mem_a                  : out   std_logic_vector(14 downto 0);                     
        ddr3_mem_ba                 : out   std_logic_vector(2 downto 0);                      
        ddr3_mem_ck                 : out   std_logic;                                         
        ddr3_mem_ck_n               : out   std_logic;                                         
        ddr3_mem_cke                : out   std_logic;                                         
        ddr3_mem_cs_n               : out   std_logic;                                         
        ddr3_mem_ras_n              : out   std_logic;                                         
        ddr3_mem_cas_n              : out   std_logic;                                         
        ddr3_mem_we_n               : out   std_logic;                                         
        ddr3_mem_reset_n            : out   std_logic;                                         
        ddr3_mem_dq                 : inout std_logic_vector(31 downto 0)  := (others => 'X'); 
        ddr3_mem_dqs                : inout std_logic_vector(3 downto 0)   := (others => 'X'); 
        ddr3_mem_dqs_n              : inout std_logic_vector(3 downto 0)   := (others => 'X'); 
        ddr3_mem_odt                : out   std_logic;                                         
        ddr3_mem_dm                 : out   std_logic_vector(3 downto 0);                      
        ddr3_oct_rzqin              : in    std_logic                      := 'X'              
  
	);
end top;

architecture arch of top is 

    signal leds_int : std_logic_vector(7 downto 0) := (others => '0');
    
    signal fs_hparams  : std_logic_vector(31 downto 0) := (others => '0');
    signal fs_vparams  : std_logic_vector(31 downto 0) := (others => '0');
    signal fs_offset0  : std_logic_vector(31 downto 0) := (others => '0');
    signal fs_offset1  : std_logic_vector(31 downto 0) := (others => '0');
    signal fs_offset2  : std_logic_vector(31 downto 0) := (others => '0');
    signal fs_commands : std_logic_vector( 3 downto 0) := (others => '0');  

    signal framestreamer_axi_m2s   : axi4_m2s := axi4_m2s_init;
    signal framestreamer_axi_s2m   : axi4_s2m := axi4_s2m_init;
    signal framestreamer_axi_wdata : std_logic_vector(255 downto 0) := (others => '0');
    signal framestreamer_axi_rdata : std_logic_vector(255 downto 0) := (others => '0');
    
    signal fifo_ov, fifo_un, datamove_error : std_logic := '0';
    
    signal frame_offsets : std_logic_vector(95 downto 0) := (others => '0');
    signal frame_active  : std_logic_vector(2 downto  0) := (others => '0');
    signal output_enable : std_logic := '0';
    
	
	constant h_active     : integer := 1920;
	constant h_frontporch : integer :=   88;
	constant h_syncwidth  : integer :=   44;
	constant h_backporch  : integer :=  148;
	constant h_total      : integer := 2200;
	
	constant v_active     : integer := 1080;
	constant v_frontporch : integer :=    4;
	constant v_syncwidth  : integer :=    5;
	constant v_backporch  : integer :=   36;
	constant v_total      : integer := 1125; 
    
    constant h_active_slv : std_logic_vector(11 downto 0) := std_logic_vector(to_unsigned(h_active,12));
    constant v_active_slv : std_logic_vector(11 downto 0) := std_logic_vector(to_unsigned(v_active,12));
    constant h_total_slv  : std_logic_vector(11 downto 0) := std_logic_vector(to_unsigned(h_total ,12));
    constant v_total_slv  : std_logic_vector(11 downto 0) := std_logic_vector(to_unsigned(v_total ,12));
    
    component video_pll is
        port (
            refclk   : in  std_logic; 
            rst      : in  std_logic; 
            outclk_0 : out std_logic  
        );
    end component video_pll;
    
    signal pclk : std_logic := '0';
    
    signal pixel_out : std_logic_vector(31 downto 0) := (others => '0');
    signal pixel_out_c : std_logic_vector(23 downto 0) := (others => '0');
    signal pixel_out_sof : std_logic := '0';
    signal pixel_out_eol : std_logic := '0';
    signal pixel_out_vld : std_logic := '0';
    
    signal sync_error : std_logic := '0';
    
    constant I2C_CLK_DIV   : integer := 500;
    constant HPD_CHECKRATE : integer := 500000;
    
    signal adv7513_hpd : std_logic := '0';
    signal adv7513_done : std_logic := '0';
    
begin


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
		reset => '0',
		
		data_in    => pixel_out_c,
		valid_in   => pixel_out_vld,
		sof_in     => pixel_out_sof,
		eol_in     => pixel_out_eol,
		
		data_out   => vga_out, --[R / G / B]
		hsync      => vga_hsync,
		vsync      => vga_vsync,
		de         => vga_de,
		sync_error => sync_error

	);	
    vga_clk <= pclk;
    pixel_out_c <= pixel_out(23 downto 0);
    
    video_pll_inst : component video_pll
    port map(
        refclk  => clk_board,
        rst     => '0',
        outclk_0 => pclk
    );

    frame_offsets <= fs_offset2 & fs_offset1 & fs_offset0;
    frame_active  <= fs_commands(2 downto 0);
    output_enable <= fs_commands(3);
    
    --h_active_slv  <= fs_hparams(11 downto  0);
    --h_total_slv   <= fs_hparams(23 downto 12);
    --v_active_slv  <= fs_vparams(11 downto  0);
    --v_total_slv   <= fs_vparams(23 downto 12);
    
    leds(0) <= datamove_error;
    leds(1) <= fifo_un;
    leds(2) <= fifo_ov;
    leds(3) <= sync_error;
    leds(4) <= framestreamer_axi_s2m.arready;
    leds(5) <= framestreamer_axi_s2m.rvalid;
    leds(6) <= adv7513_done;
    leds(7) <= adv7513_hpd;
    
	framestreamer_inst : entity work.framestreamer
	generic map(
        PIXEL_WIDTH       => 32,
		DATA_WIDTH        => 256,
        XFER_TIMEOUT      => 100000,
        MAX_BURST         => 8
	)
	port map(
        
        h_active       => h_active_slv,
        v_active       => v_active_slv,
        h_total        => h_total_slv, 
        v_total        => v_total_slv, 
        frame_offsets  => frame_offsets,
        frame_active   => frame_active,
        output_enable  => output_enable,
        
        fifo_ov        => fifo_ov,
        fifo_un        => fifo_un,
        datamove_error => datamove_error,
        
		pclk           => pclk,
        preset         => '0',
        pixel_out      => pixel_out,
        pixel_out_sof  => pixel_out_sof,
        pixel_out_eol  => pixel_out_eol,
        pixel_out_vld  => pixel_out_vld,
        
        --axi memory
        aclk           => pclk,
        areset         => '0',
		axi4_m2s_o     => framestreamer_axi_m2s,
        axi4_s2m_i     => framestreamer_axi_s2m,
        axi4_wdata     => framestreamer_axi_wdata,
        axi4_rdata     => framestreamer_axi_rdata

	);


    soc : entity work.soc_system_wrapper
    port map(
        h2f_lw_axi_clk              => pclk,
        f2h_sdram_clk_clk           => pclk,
        f2h_sdram_data_m2s          => framestreamer_axi_m2s  ,
        f2h_sdram_data_s2m          => framestreamer_axi_s2m  ,
        f2h_sdram_data_wdata        => framestreamer_axi_wdata,
        f2h_sdram_data_rdata        => framestreamer_axi_rdata,
        io_hps_io_emac1_inst_TX_CLK => io_hps_io_emac1_inst_TX_CLK, 
        io_hps_io_emac1_inst_TXD0   => io_hps_io_emac1_inst_TXD0  , 
        io_hps_io_emac1_inst_TXD1   => io_hps_io_emac1_inst_TXD1  , 
        io_hps_io_emac1_inst_TXD2   => io_hps_io_emac1_inst_TXD2  , 
        io_hps_io_emac1_inst_TXD3   => io_hps_io_emac1_inst_TXD3  , 
        io_hps_io_emac1_inst_RXD0   => io_hps_io_emac1_inst_RXD0  , 
        io_hps_io_emac1_inst_MDIO   => io_hps_io_emac1_inst_MDIO  , 
        io_hps_io_emac1_inst_MDC    => io_hps_io_emac1_inst_MDC   , 
        io_hps_io_emac1_inst_RX_CTL => io_hps_io_emac1_inst_RX_CTL, 
        io_hps_io_emac1_inst_TX_CTL => io_hps_io_emac1_inst_TX_CTL, 
        io_hps_io_emac1_inst_RX_CLK => io_hps_io_emac1_inst_RX_CLK, 
        io_hps_io_emac1_inst_RXD1   => io_hps_io_emac1_inst_RXD1  , 
        io_hps_io_emac1_inst_RXD2   => io_hps_io_emac1_inst_RXD2  , 
        io_hps_io_emac1_inst_RXD3   => io_hps_io_emac1_inst_RXD3  , 
        io_hps_io_sdio_inst_CMD     => io_hps_io_sdio_inst_CMD    , 
        io_hps_io_sdio_inst_D0      => io_hps_io_sdio_inst_D0     , 
        io_hps_io_sdio_inst_D1      => io_hps_io_sdio_inst_D1     , 
        io_hps_io_sdio_inst_CLK     => io_hps_io_sdio_inst_CLK    , 
        io_hps_io_sdio_inst_D2      => io_hps_io_sdio_inst_D2     , 
        io_hps_io_sdio_inst_D3      => io_hps_io_sdio_inst_D3     , 
        io_hps_io_usb1_inst_D0      => io_hps_io_usb1_inst_D0     , 
        io_hps_io_usb1_inst_D1      => io_hps_io_usb1_inst_D1     , 
        io_hps_io_usb1_inst_D2      => io_hps_io_usb1_inst_D2     , 
        io_hps_io_usb1_inst_D3      => io_hps_io_usb1_inst_D3     , 
        io_hps_io_usb1_inst_D4      => io_hps_io_usb1_inst_D4     , 
        io_hps_io_usb1_inst_D5      => io_hps_io_usb1_inst_D5     , 
        io_hps_io_usb1_inst_D6      => io_hps_io_usb1_inst_D6     , 
        io_hps_io_usb1_inst_D7      => io_hps_io_usb1_inst_D7     , 
        io_hps_io_usb1_inst_CLK     => io_hps_io_usb1_inst_CLK    , 
        io_hps_io_usb1_inst_STP     => io_hps_io_usb1_inst_STP    , 
        io_hps_io_usb1_inst_DIR     => io_hps_io_usb1_inst_DIR    , 
        io_hps_io_usb1_inst_NXT     => io_hps_io_usb1_inst_NXT    , 
        io_hps_io_spim1_inst_CLK    => io_hps_io_spim1_inst_CLK   , 
        io_hps_io_spim1_inst_MOSI   => io_hps_io_spim1_inst_MOSI  , 
        io_hps_io_spim1_inst_MISO   => io_hps_io_spim1_inst_MISO  , 
        io_hps_io_spim1_inst_SS0    => io_hps_io_spim1_inst_SS0   , 
        io_hps_io_uart0_inst_RX     => io_hps_io_uart0_inst_RX    , 
        io_hps_io_uart0_inst_TX     => io_hps_io_uart0_inst_TX    , 
        io_hps_io_i2c0_inst_SDA     => io_hps_io_i2c0_inst_SDA    , 
        io_hps_io_i2c0_inst_SCL     => io_hps_io_i2c0_inst_SCL    , 
        io_hps_io_i2c1_inst_SDA     => io_hps_io_i2c1_inst_SDA    , 
        io_hps_io_i2c1_inst_SCL     => io_hps_io_i2c1_inst_SCL    , 
        io_hps_io_gpio_inst_GPIO09  => io_hps_io_gpio_inst_GPIO09 , 
        io_hps_io_gpio_inst_GPIO35  => io_hps_io_gpio_inst_GPIO35 , 
        io_hps_io_gpio_inst_GPIO40  => io_hps_io_gpio_inst_GPIO40 , 
        io_hps_io_gpio_inst_GPIO53  => io_hps_io_gpio_inst_GPIO53 , 
        io_hps_io_gpio_inst_GPIO54  => io_hps_io_gpio_inst_GPIO54 , 
        io_hps_io_gpio_inst_GPIO61  => io_hps_io_gpio_inst_GPIO61 , 
        ddr3_mem_a                  => ddr3_mem_a      ,
        ddr3_mem_ba                 => ddr3_mem_ba     ,
        ddr3_mem_ck                 => ddr3_mem_ck     ,
        ddr3_mem_ck_n               => ddr3_mem_ck_n   ,
        ddr3_mem_cke                => ddr3_mem_cke    ,
        ddr3_mem_cs_n               => ddr3_mem_cs_n   ,
        ddr3_mem_ras_n              => ddr3_mem_ras_n  ,
        ddr3_mem_cas_n              => ddr3_mem_cas_n  ,
        ddr3_mem_we_n               => ddr3_mem_we_n   ,
        ddr3_mem_reset_n            => ddr3_mem_reset_n,
        ddr3_mem_dq                 => ddr3_mem_dq     ,
        ddr3_mem_dqs                => ddr3_mem_dqs    ,
        ddr3_mem_dqs_n              => ddr3_mem_dqs_n  ,
        ddr3_mem_odt                => ddr3_mem_odt    ,
        ddr3_mem_dm                 => ddr3_mem_dm     ,
        ddr3_oct_rzqin              => ddr3_oct_rzqin  ,
        fs_hparams_export           => fs_hparams      ,
        fs_vparams_export           => fs_vparams      ,
        fs_offset0_export           => fs_offset0      ,
        fs_offset1_export           => fs_offset1      ,
        fs_offset2_export           => fs_offset2      ,
        fs_commands_export          => fs_commands
    );

	
end arch;