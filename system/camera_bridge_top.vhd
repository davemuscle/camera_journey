library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

--Top Level for testing camera, framebuffer, debayering

use work.axi_pkg.all;

entity camera_bridge_top is
	port(
		clk_board : in std_logic;
		
        leds : out std_logic_vector(7 downto 0) := (others => '0');
		
        tx : out std_logic;
        rx : in  std_logic;
        
		key1 : in std_logic;
		key0 : in std_logic;
        
        cam_a_pclk  : in    std_logic;
        cam_a_data  : in    std_logic_vector(7 downto 0);
        cam_a_href  : in    std_logic;
        cam_a_vsync : in    std_logic;
        cam_a_sda   : inout std_logic;
        cam_a_scl   : inout std_logic;
		cam_a_xclk  : out   std_logic;
		cam_a_reset : out   std_logic;
		cam_a_pwdn  : out   std_logic;
    
        cam_b_pclk  : in    std_logic;
        cam_b_data  : in    std_logic_vector(7 downto 0);
        cam_b_href  : in    std_logic;
        cam_b_vsync : in    std_logic;
        cam_b_sda   : inout std_logic;
        cam_b_scl   : inout std_logic;
		cam_b_xclk  : out   std_logic;
		cam_b_reset : out   std_logic;
		cam_b_pwdn  : out   std_logic;
    
		hdmi_sda : inout std_logic;
		hdmi_scl : inout std_logic;
		
		vga_clk     : out std_logic;
		vga_hsync   : out std_logic;
		vga_vsync   : out std_logic;
		vga_de      : out std_logic;
		vga_out     : out std_logic_vector(23 downto 0);
		
		HPS_DDR3_ADDR   : out std_logic_vector(14 downto 0);
		HPS_DDR3_BA     : out std_logic_vector(2 downto 0);
		HPS_DDR3_CAS_N  : out std_logic;
		HPS_DDR3_CKE    : out std_logic;
		HPS_DDR3_CK_N   : out std_logic;
		HPS_DDR3_CK_P   : out std_logic;
		HPS_DDR3_CS_N   : out std_logic;
		HPS_DDR3_DM     : out std_logic_vector(3 downto 0);
		HPS_DDR3_DQ     : inout std_logic_vector(31 downto 0);
		HPS_DDR3_DQS_N  : inout std_logic_vector(3 downto 0);
		HPS_DDR3_DQS_P  : inout std_logic_vector(3 downto 0);
		HPS_DDR3_ODT    : out std_logic;
		HPS_DDR3_RAS_N  : out std_logic;
		HPS_DDR3_RESET_N: out std_logic;
		HPS_DDR3_RZQ    : in  std_logic;
		HPS_DDR3_WE_N   : out std_logic
	);
end camera_bridge_top;

architecture arch of camera_bridge_top is 

    component soc_system is
        port (
            hps_0_f2h_cold_reset_req_reset_n : in    std_logic                      := 'X';              -- reset_n
			hps_0_f2h_sdram0_clock_clk    : in    std_logic                      := 'X';             -- clk
			hps_0_f2h_sdram0_data_araddr  : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- araddr
			hps_0_f2h_sdram0_data_arlen   : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- arlen
			hps_0_f2h_sdram0_data_arid    : in    std_logic_vector(7 downto 0)   := (others => 'X'); -- arid
			hps_0_f2h_sdram0_data_arsize  : in    std_logic_vector(2 downto 0)   := (others => 'X'); -- arsize
			hps_0_f2h_sdram0_data_arburst : in    std_logic_vector(1 downto 0)   := (others => 'X'); -- arburst
			hps_0_f2h_sdram0_data_arlock  : in    std_logic_vector(1 downto 0)   := (others => 'X'); -- arlock
			hps_0_f2h_sdram0_data_arprot  : in    std_logic_vector(2 downto 0)   := (others => 'X'); -- arprot
			hps_0_f2h_sdram0_data_arvalid : in    std_logic                      := 'X';             -- arvalid
			hps_0_f2h_sdram0_data_arcache : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- arcache
			hps_0_f2h_sdram0_data_awaddr  : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- awaddr
			hps_0_f2h_sdram0_data_awlen   : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- awlen
			hps_0_f2h_sdram0_data_awid    : in    std_logic_vector(7 downto 0)   := (others => 'X'); -- awid
			hps_0_f2h_sdram0_data_awsize  : in    std_logic_vector(2 downto 0)   := (others => 'X'); -- awsize
			hps_0_f2h_sdram0_data_awburst : in    std_logic_vector(1 downto 0)   := (others => 'X'); -- awburst
			hps_0_f2h_sdram0_data_awlock  : in    std_logic_vector(1 downto 0)   := (others => 'X'); -- awlock
			hps_0_f2h_sdram0_data_awprot  : in    std_logic_vector(2 downto 0)   := (others => 'X'); -- awprot
			hps_0_f2h_sdram0_data_awvalid : in    std_logic                      := 'X';             -- awvalid
			hps_0_f2h_sdram0_data_awcache : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- awcache
			hps_0_f2h_sdram0_data_bresp   : out   std_logic_vector(1 downto 0);                      -- bresp
			hps_0_f2h_sdram0_data_bid     : out   std_logic_vector(7 downto 0);                      -- bid
			hps_0_f2h_sdram0_data_bvalid  : out   std_logic;                                         -- bvalid
			hps_0_f2h_sdram0_data_bready  : in    std_logic                      := 'X';             -- bready
			hps_0_f2h_sdram0_data_arready : out   std_logic;                                         -- arready
			hps_0_f2h_sdram0_data_awready : out   std_logic;                                         -- awready
			hps_0_f2h_sdram0_data_rready  : in    std_logic                      := 'X';             -- rready
			hps_0_f2h_sdram0_data_rdata   : out   std_logic_vector(255 downto 0);                    -- rdata
			hps_0_f2h_sdram0_data_rresp   : out   std_logic_vector(1 downto 0);                      -- rresp
			hps_0_f2h_sdram0_data_rlast   : out   std_logic;                                         -- rlast
			hps_0_f2h_sdram0_data_rid     : out   std_logic_vector(7 downto 0);                      -- rid
			hps_0_f2h_sdram0_data_rvalid  : out   std_logic;                                         -- rvalid
			hps_0_f2h_sdram0_data_wlast   : in    std_logic                      := 'X';             -- wlast
			hps_0_f2h_sdram0_data_wvalid  : in    std_logic                      := 'X';             -- wvalid
			hps_0_f2h_sdram0_data_wdata   : in    std_logic_vector(255 downto 0) := (others => 'X'); -- wdata
			hps_0_f2h_sdram0_data_wstrb   : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- wstrb
			hps_0_f2h_sdram0_data_wready  : out   std_logic;                                         -- wready
			hps_0_f2h_sdram0_data_wid     : in    std_logic_vector(7 downto 0)   := (others => 'X'); -- wid
			hps_0_f2h_warm_reset_req_reset_n : in    std_logic                      := 'X';              -- reset_n
            hps_0_h2f_reset_reset_n       : out   std_logic;                                         -- reset_n
			memory_mem_a                  : out   std_logic_vector(14 downto 0);                     -- mem_a
			memory_mem_ba                 : out   std_logic_vector(2 downto 0);                      -- mem_ba
			memory_mem_ck                 : out   std_logic;                                         -- mem_ck
			memory_mem_ck_n               : out   std_logic;                                         -- mem_ck_n
			memory_mem_cke                : out   std_logic;                                         -- mem_cke
			memory_mem_cs_n               : out   std_logic;                                         -- mem_cs_n
			memory_mem_ras_n              : out   std_logic;                                         -- mem_ras_n
			memory_mem_cas_n              : out   std_logic;                                         -- mem_cas_n
			memory_mem_we_n               : out   std_logic;                                         -- mem_we_n
			memory_mem_reset_n            : out   std_logic;                                         -- mem_reset_n
			memory_mem_dq                 : inout std_logic_vector(31 downto 0)  := (others => 'X'); -- mem_dq
			memory_mem_dqs                : inout std_logic_vector(3 downto 0)   := (others => 'X'); -- mem_dqs
			memory_mem_dqs_n              : inout std_logic_vector(3 downto 0)   := (others => 'X'); -- mem_dqs_n
			memory_mem_odt                : out   std_logic;                                         -- mem_odt
			memory_mem_dm                 : out   std_logic_vector(3 downto 0);                      -- mem_dm
			memory_oct_rzqin              : in    std_logic                      := 'X'              -- oct_rzqin 
            -- clk
        );
    end component soc_system;

	component video_pll is
	port(
		refclk : in std_logic;
		rst    : in std_logic;
		outclk_0 : out std_logic
	);
	end component video_pll;
    
	component pll_100M is
	port(
		refclk   : in std_logic;
		rst      : in std_logic;
		outclk_0 : out std_logic
	);
	end component pll_100M;
    
	component xclk_pll is
	port(
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic;        -- outclk0.clk
		outclk_1 : out std_logic;        -- outclk1.clk
		outclk_2 : out std_logic;        -- outclk2.clk
		outclk_3 : out std_logic;        -- outclk3.clk
		locked   : out std_logic         --  locked.export
	);
	end component xclk_pll;
 
	constant PIXEL_WIDTH : integer :=  32;
	constant DATA_WIDTH  : integer := 256;
	
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
   
    --constant cam_h_total  : integer := 2200;
    --constant cam_v_total  : integer := 1125;

    signal framebuffer_axi_m2s : axi4_m2s := axi4_m2s_init;
    signal framebuffer_axi_s2m : axi4_s2m := axi4_s2m_init;
    signal framebuffer_axi_wdata : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal framebuffer_axi_rdata : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    
    signal reset_ext : std_logic := '0';
    signal hps_reset : std_logic := '0';
    
    signal pclk    : std_logic := '0';
    signal ddr_clk : std_logic := '0';


    signal cam_a_data_reg  : std_logic_vector(7 downto 0) := (others => '0');
    signal cam_a_href_reg  : std_logic := '0';
    signal cam_a_vsync_reg : std_logic := '0';
    signal cam_a_href_dly  : std_logic := '0';
    signal cam_a_vsync_dly : std_logic := '0';

    signal cam_b_data_reg  : std_logic_vector(7 downto 0) := (others => '0');
    signal cam_b_href_reg  : std_logic := '0';
    signal cam_b_vsync_reg : std_logic := '0';
    signal cam_b_href_dly  : std_logic := '0';
    signal cam_b_vsync_dly : std_logic := '0';
    
    signal cam_a_xclk_disable : std_logic := '1';
    signal cam_b_xclk_disable : std_logic := '1';
    signal cam_xclk_disable_comb : std_logic := '1';
    signal cam_xclk_pre : std_logic := '0';
   
    signal cam_a_scl_t, cam_a_sda_t : std_logic := '0';
    signal cam_a_scl_r, cam_a_sda_r : std_logic := '0';
   
begin

    reset_ext <= (not hps_reset) or (not key0);
    
    --clock for 1080p
	video_clocking: video_pll
	port map(
		refclk   => clk_board,
		rst      => '0',
		outclk_0 => pclk
	);
    
    --clock for HPS SDRAM
	ddr3_clocking: pll_100M
	port map(
		refclk   => clk_board,
		rst      => '0',
		outclk_0 => ddr_clk
	);
    
    cam_xclk_disable_comb <= cam_a_xclk_disable or cam_b_xclk_disable;
    
    --external clock for camera A
	xclk_a_clocking: xclk_pll
	port map(        
		refclk   => clk_board,
		rst      => cam_xclk_disable_comb,
		outclk_0 => open,     --50M
		outclk_1 => cam_xclk_pre,     --24M
		outclk_2 => open,     --12M
		outclk_3 => open, --5M
		locked   => open
        
	);

    cam_a_xclk <= cam_xclk_pre;
    cam_b_xclk <= cam_xclk_pre;

    vga_clk <= pclk;

    --OV5640 asserts href one clock early because it was designed for children!
    process(cam_a_pclk)
    begin
        if(rising_edge(cam_a_pclk)) then
            cam_a_data_reg  <= cam_a_data;
            cam_a_href_reg  <= cam_a_href;
            cam_a_vsync_reg <= cam_a_vsync;
            cam_a_href_dly  <= cam_a_href_reg;
            cam_a_vsync_dly <= cam_a_vsync_reg;            
        end if;
    end process;
    
    process(cam_b_pclk)
    begin
        if(rising_edge(cam_b_pclk)) then
            cam_b_data_reg  <= cam_b_data;
            cam_b_href_reg  <= cam_b_href;
            cam_b_vsync_reg <= cam_b_vsync;
            cam_b_href_dly  <= cam_b_href_reg;
            cam_b_vsync_dly <= cam_b_vsync_reg;
        end if;
    end process;
    
    application : entity work.app_top
    generic map(
        PIXEL_WIDTH    => PIXEL_WIDTH,
        DATA_WIDTH     => DATA_WIDTH,
        h_active       => h_active    , 
        h_frontporch   => h_frontporch, 
        h_syncwidth    => h_syncwidth , 
        h_backporch    => h_backporch , 
        h_total        => h_total     , 
        v_active       => v_active    , 
        v_frontporch   => v_frontporch, 
        v_syncwidth    => v_syncwidth , 
        v_backporch    => v_backporch , 
        v_total        => v_total     , 
        SIM            => FALSE,
        CLK_DIV_1ms    => 50000,
        I2C_CLK_DIV    => 500,
        HPD_CHECKRATE  => 500000,
        AXI_TIMEOUT    => 10000000,
        AXI_MAX_BURST  => 8,
        FRAMEBUFFER_FX => TRUE,
        UART_CLKRATE   => 50000000,
        UART_BAUDRATE  =>   115200,
        ENABLE_BOOT    => FALSE
    )
	port map(
        --external reset
        reset_ext  => reset_ext,
        
        --clocks
		clk_board  => clk_board,
        cam_a_pclk => cam_a_pclk,
        cam_b_pclk => cam_b_pclk,
        ddr_clk    => ddr_clk  ,
        pclk       => pclk     ,
		
        --uart debugger
        tx => tx,
        rx => rx,
        
        --camera A
        cam_a_sda           => cam_a_sda  ,
        cam_a_scl           => cam_a_scl  ,
        cam_a_xclk_disable  => cam_a_xclk_disable ,
		cam_a_reset         => cam_a_reset,
		cam_a_pwdn          => cam_a_pwdn ,
        cam_a_data          => cam_a_data_reg ,
        cam_a_href          => cam_a_href_dly ,
        cam_a_vsync         => cam_a_vsync_dly,
        
        --camera B
        cam_b_sda           => cam_b_sda  ,
        cam_b_scl           => cam_b_scl  ,
        cam_b_xclk_disable  => cam_b_xclk_disable ,
		cam_b_reset         => cam_b_reset,
		cam_b_pwdn          => cam_b_pwdn ,
        cam_b_data          => cam_b_data_reg ,
        cam_b_href          => cam_b_href_dly ,
        cam_b_vsync         => cam_b_vsync_dly,
        
        --test output stream
        tb_out_sof   => open,
        tb_out_eol   => open,
        tb_out_valid => open,
        tb_out_data  => open,
        
        --adv7513 control
 		hdmi_sda => hdmi_sda,
		hdmi_scl => hdmi_scl,   
    
        --adv7513 VGA output stream
		vga_hsync => vga_hsync,
		vga_vsync => vga_vsync,
		vga_de    => vga_de   ,
		vga_out   => vga_out  ,
        
        --status signals to LEDs
        leds    => leds,
		
        --framebuffer memory
        framebuffer_axi_m2s   => framebuffer_axi_m2s  ,
        framebuffer_axi_s2m   => framebuffer_axi_s2m  ,
        framebuffer_axi_wdata => framebuffer_axi_wdata,
        framebuffer_axi_rdata => framebuffer_axi_rdata

	);
    
    soc : component soc_system
        port map (
            hps_0_f2h_cold_reset_req_reset_n => '1',
            hps_0_f2h_sdram0_clock_clk   => ddr_clk,
            hps_0_f2h_sdram0_data_araddr => framebuffer_axi_m2s.araddr,  
            hps_0_f2h_sdram0_data_arlen  => framebuffer_axi_m2s.arlen(3 downto 0),
            hps_0_f2h_sdram0_data_arid   => framebuffer_axi_m2s.arid,    
            hps_0_f2h_sdram0_data_arsize => framebuffer_axi_m2s.arsize,  
            hps_0_f2h_sdram0_data_arburst=> framebuffer_axi_m2s.arburst, 
            hps_0_f2h_sdram0_data_arlock => framebuffer_axi_m2s.arlock,  
            hps_0_f2h_sdram0_data_arprot => framebuffer_axi_m2s.arprot,  
            hps_0_f2h_sdram0_data_arvalid=> framebuffer_axi_m2s.arvalid, 
            hps_0_f2h_sdram0_data_arcache=> framebuffer_axi_m2s.arcache, 
            hps_0_f2h_sdram0_data_awaddr => framebuffer_axi_m2s.awaddr,  
            hps_0_f2h_sdram0_data_awlen  => framebuffer_axi_m2s.awlen(3 downto 0),
            hps_0_f2h_sdram0_data_awid   => framebuffer_axi_m2s.awid,    
            hps_0_f2h_sdram0_data_awsize => framebuffer_axi_m2s.awsize,  
            hps_0_f2h_sdram0_data_awburst=> framebuffer_axi_m2s.awburst, 
            hps_0_f2h_sdram0_data_awlock => framebuffer_axi_m2s.awlock,  
            hps_0_f2h_sdram0_data_awprot => framebuffer_axi_m2s.awprot,  
            hps_0_f2h_sdram0_data_awvalid=> framebuffer_axi_m2s.awvalid,             
            hps_0_f2h_sdram0_data_awcache=> framebuffer_axi_m2s.awcache, 
            hps_0_f2h_sdram0_data_bresp  => framebuffer_axi_s2m.bresp,   
            hps_0_f2h_sdram0_data_bid    => framebuffer_axi_s2m.bid,     
            hps_0_f2h_sdram0_data_bvalid => framebuffer_axi_s2m.bvalid,  
            hps_0_f2h_sdram0_data_bready => framebuffer_axi_m2s.bready,  
            hps_0_f2h_sdram0_data_arready=> framebuffer_axi_s2m.arready, 
            hps_0_f2h_sdram0_data_awready=> framebuffer_axi_s2m.awready, 
            hps_0_f2h_sdram0_data_rready => framebuffer_axi_m2s.rready,  
            hps_0_f2h_sdram0_data_rdata  => framebuffer_axi_rdata,   
            hps_0_f2h_sdram0_data_rresp  => framebuffer_axi_s2m.rresp,   
            hps_0_f2h_sdram0_data_rlast  => framebuffer_axi_s2m.rlast,   
            hps_0_f2h_sdram0_data_rid    => framebuffer_axi_s2m.rid,     
            hps_0_f2h_sdram0_data_rvalid => framebuffer_axi_s2m.rvalid,  
            hps_0_f2h_sdram0_data_wlast  => framebuffer_axi_m2s.wlast,   
            hps_0_f2h_sdram0_data_wvalid => framebuffer_axi_m2s.wvalid,  
            hps_0_f2h_sdram0_data_wdata  => framebuffer_axi_wdata,   
            hps_0_f2h_sdram0_data_wstrb  => (others => '1'),   
            hps_0_f2h_sdram0_data_wready => framebuffer_axi_s2m.wready,  
            hps_0_f2h_sdram0_data_wid    => framebuffer_axi_m2s.wid,  
            hps_0_f2h_warm_reset_req_reset_n => '1',
			hps_0_h2f_reset_reset_n      => hps_reset,

            memory_mem_a                     => HPS_DDR3_ADDR,   
            memory_mem_ba                    => HPS_DDR3_BA,     
            memory_mem_ck                    => HPS_DDR3_CK_P,   
            memory_mem_ck_n                  => HPS_DDR3_CK_N,   
            memory_mem_cke                   => HPS_DDR3_CKE,    
            memory_mem_cs_n                  => HPS_DDR3_CS_N,   
            memory_mem_ras_n                 => HPS_DDR3_RAS_N,  
            memory_mem_cas_n                 => HPS_DDR3_CAS_N,  
            memory_mem_we_n                  => HPS_DDR3_WE_N,   
            memory_mem_reset_n               => HPS_DDR3_RESET_N,
            memory_mem_dq                    => HPS_DDR3_DQ,     
            memory_mem_dqs                   => HPS_DDR3_DQS_P,  
            memory_mem_dqs_n                 => HPS_DDR3_DQS_N,  
            memory_mem_odt                   => HPS_DDR3_ODT,    
            memory_mem_dm                    => HPS_DDR3_DM,     
            memory_oct_rzqin                 => HPS_DDR3_RZQ

        );

	
end arch;