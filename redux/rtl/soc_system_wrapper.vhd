library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

library soc_system;

use work.axi_pkg.all;

--AXI3 ports:
--SDRAM, 256 bit data, 32 bit address, 8 bit ID

entity soc_system_wrapper is
	port(
        h2f_lw_axi_clk              : in    std_logic                      := 'X';             -- clk
        f2h_sdram_clk_clk           : in    std_logic                      := 'X';             -- clk
        f2h_sdram_data_m2s          : in    axi4_m2s;
        f2h_sdram_data_s2m          : out   axi4_s2m := axi4_s2m_init;
        f2h_sdram_data_wdata        : in    std_logic_vector(255 downto 0);
        f2h_sdram_data_rdata        : out   std_logic_vector(255 downto 0);
        io_hps_io_emac1_inst_TX_CLK : out   std_logic;                                         -- hps_io_emac1_inst_TX_CLK
        io_hps_io_emac1_inst_TXD0   : out   std_logic;                                         -- hps_io_emac1_inst_TXD0
        io_hps_io_emac1_inst_TXD1   : out   std_logic;                                         -- hps_io_emac1_inst_TXD1
        io_hps_io_emac1_inst_TXD2   : out   std_logic;                                         -- hps_io_emac1_inst_TXD2
        io_hps_io_emac1_inst_TXD3   : out   std_logic;                                         -- hps_io_emac1_inst_TXD3
        io_hps_io_emac1_inst_RXD0   : in    std_logic                      := 'X';             -- hps_io_emac1_inst_RXD0
        io_hps_io_emac1_inst_MDIO   : inout std_logic                      := 'X';             -- hps_io_emac1_inst_MDIO
        io_hps_io_emac1_inst_MDC    : out   std_logic;                                         -- hps_io_emac1_inst_MDC
        io_hps_io_emac1_inst_RX_CTL : in    std_logic                      := 'X';             -- hps_io_emac1_inst_RX_CTL
        io_hps_io_emac1_inst_TX_CTL : out   std_logic;                                         -- hps_io_emac1_inst_TX_CTL
        io_hps_io_emac1_inst_RX_CLK : in    std_logic                      := 'X';             -- hps_io_emac1_inst_RX_CLK
        io_hps_io_emac1_inst_RXD1   : in    std_logic                      := 'X';             -- hps_io_emac1_inst_RXD1
        io_hps_io_emac1_inst_RXD2   : in    std_logic                      := 'X';             -- hps_io_emac1_inst_RXD2
        io_hps_io_emac1_inst_RXD3   : in    std_logic                      := 'X';             -- hps_io_emac1_inst_RXD3
        io_hps_io_sdio_inst_CMD     : inout std_logic                      := 'X';             -- hps_io_sdio_inst_CMD
        io_hps_io_sdio_inst_D0      : inout std_logic                      := 'X';             -- hps_io_sdio_inst_D0
        io_hps_io_sdio_inst_D1      : inout std_logic                      := 'X';             -- hps_io_sdio_inst_D1
        io_hps_io_sdio_inst_CLK     : out   std_logic;                                         -- hps_io_sdio_inst_CLK
        io_hps_io_sdio_inst_D2      : inout std_logic                      := 'X';             -- hps_io_sdio_inst_D2
        io_hps_io_sdio_inst_D3      : inout std_logic                      := 'X';             -- hps_io_sdio_inst_D3
        io_hps_io_usb1_inst_D0      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D0
        io_hps_io_usb1_inst_D1      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D1
        io_hps_io_usb1_inst_D2      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D2
        io_hps_io_usb1_inst_D3      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D3
        io_hps_io_usb1_inst_D4      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D4
        io_hps_io_usb1_inst_D5      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D5
        io_hps_io_usb1_inst_D6      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D6
        io_hps_io_usb1_inst_D7      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D7
        io_hps_io_usb1_inst_CLK     : in    std_logic                      := 'X';             -- hps_io_usb1_inst_CLK
        io_hps_io_usb1_inst_STP     : out   std_logic;                                         -- hps_io_usb1_inst_STP
        io_hps_io_usb1_inst_DIR     : in    std_logic                      := 'X';             -- hps_io_usb1_inst_DIR
        io_hps_io_usb1_inst_NXT     : in    std_logic                      := 'X';             -- hps_io_usb1_inst_NXT
        io_hps_io_spim1_inst_CLK    : out   std_logic;                                         -- hps_io_spim1_inst_CLK
        io_hps_io_spim1_inst_MOSI   : out   std_logic;                                         -- hps_io_spim1_inst_MOSI
        io_hps_io_spim1_inst_MISO   : in    std_logic                      := 'X';             -- hps_io_spim1_inst_MISO
        io_hps_io_spim1_inst_SS0    : out   std_logic;                                         -- hps_io_spim1_inst_SS0
        io_hps_io_uart0_inst_RX     : in    std_logic                      := 'X';             -- hps_io_uart0_inst_RX
        io_hps_io_uart0_inst_TX     : out   std_logic;                                         -- hps_io_uart0_inst_TX
        io_hps_io_i2c0_inst_SDA     : inout std_logic                      := 'X';             -- hps_io_i2c0_inst_SDA
        io_hps_io_i2c0_inst_SCL     : inout std_logic                      := 'X';             -- hps_io_i2c0_inst_SCL
        io_hps_io_i2c1_inst_SDA     : inout std_logic                      := 'X';             -- hps_io_i2c1_inst_SDA
        io_hps_io_i2c1_inst_SCL     : inout std_logic                      := 'X';             -- hps_io_i2c1_inst_SCL
        io_hps_io_gpio_inst_GPIO09  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO09
        io_hps_io_gpio_inst_GPIO35  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO35
        io_hps_io_gpio_inst_GPIO40  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO40
        io_hps_io_gpio_inst_GPIO53  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO53
        io_hps_io_gpio_inst_GPIO54  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO54
        io_hps_io_gpio_inst_GPIO61  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO61
        ddr3_mem_a                  : out   std_logic_vector(14 downto 0);                     -- mem_a
        ddr3_mem_ba                 : out   std_logic_vector(2 downto 0);                      -- mem_ba
        ddr3_mem_ck                 : out   std_logic;                                         -- mem_ck
        ddr3_mem_ck_n               : out   std_logic;                                         -- mem_ck_n
        ddr3_mem_cke                : out   std_logic;                                         -- mem_cke
        ddr3_mem_cs_n               : out   std_logic;                                         -- mem_cs_n
        ddr3_mem_ras_n              : out   std_logic;                                         -- mem_ras_n
        ddr3_mem_cas_n              : out   std_logic;                                         -- mem_cas_n
        ddr3_mem_we_n               : out   std_logic;                                         -- mem_we_n
        ddr3_mem_reset_n            : out   std_logic;                                         -- mem_reset_n
        ddr3_mem_dq                 : inout std_logic_vector(31 downto 0)  := (others => 'X'); -- mem_dq
        ddr3_mem_dqs                : inout std_logic_vector(3 downto 0)   := (others => 'X'); -- mem_dqs
        ddr3_mem_dqs_n              : inout std_logic_vector(3 downto 0)   := (others => 'X'); -- mem_dqs_n
        ddr3_mem_odt                : out   std_logic;                                         -- mem_odt
        ddr3_mem_dm                 : out   std_logic_vector(3 downto 0);                      -- mem_dm
        ddr3_oct_rzqin              : in    std_logic                      := 'X';             -- oct_rzqin
        fs_hparams_export           : out   std_logic_vector(31 downto 0);                     -- export
        fs_vparams_export           : out   std_logic_vector(31 downto 0);                     -- export
        fs_offset0_export           : out   std_logic_vector(31 downto 0);                     -- export
        fs_offset1_export           : out   std_logic_vector(31 downto 0);                     -- export
        fs_offset2_export           : out   std_logic_vector(31 downto 0);                     -- export
        fs_commands_export          : out   std_logic_vector(3 downto 0)                       -- export

	);
end soc_system_wrapper;

architecture arch of soc_system_wrapper is 

	-- component soc_system is
		-- port (
			-- ddr3_mem_a                  : out   std_logic_vector(14 downto 0);                     -- mem_a
			-- ddr3_mem_ba                 : out   std_logic_vector(2 downto 0);                      -- mem_ba
			-- ddr3_mem_ck                 : out   std_logic;                                         -- mem_ck
			-- ddr3_mem_ck_n               : out   std_logic;                                         -- mem_ck_n
			-- ddr3_mem_cke                : out   std_logic;                                         -- mem_cke
			-- ddr3_mem_cs_n               : out   std_logic;                                         -- mem_cs_n
			-- ddr3_mem_ras_n              : out   std_logic;                                         -- mem_ras_n
			-- ddr3_mem_cas_n              : out   std_logic;                                         -- mem_cas_n
			-- ddr3_mem_we_n               : out   std_logic;                                         -- mem_we_n
			-- ddr3_mem_reset_n            : out   std_logic;                                         -- mem_reset_n
			-- ddr3_mem_dq                 : inout std_logic_vector(31 downto 0)  := (others => 'X'); -- mem_dq
			-- ddr3_mem_dqs                : inout std_logic_vector(3 downto 0)   := (others => 'X'); -- mem_dqs
			-- ddr3_mem_dqs_n              : inout std_logic_vector(3 downto 0)   := (others => 'X'); -- mem_dqs_n
			-- ddr3_mem_odt                : out   std_logic;                                         -- mem_odt
			-- ddr3_mem_dm                 : out   std_logic_vector(3 downto 0);                      -- mem_dm
			-- ddr3_oct_rzqin              : in    std_logic                      := 'X';             -- oct_rzqin
			-- f2h_sdram_clk_clk           : in    std_logic                      := 'X';             -- clk
			-- f2h_sdram_data_araddr       : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- araddr
			-- f2h_sdram_data_arlen        : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- arlen
			-- f2h_sdram_data_arid         : in    std_logic_vector(7 downto 0)   := (others => 'X'); -- arid
			-- f2h_sdram_data_arsize       : in    std_logic_vector(2 downto 0)   := (others => 'X'); -- arsize
			-- f2h_sdram_data_arburst      : in    std_logic_vector(1 downto 0)   := (others => 'X'); -- arburst
			-- f2h_sdram_data_arlock       : in    std_logic_vector(1 downto 0)   := (others => 'X'); -- arlock
			-- f2h_sdram_data_arprot       : in    std_logic_vector(2 downto 0)   := (others => 'X'); -- arprot
			-- f2h_sdram_data_arvalid      : in    std_logic                      := 'X';             -- arvalid
			-- f2h_sdram_data_arcache      : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- arcache
			-- f2h_sdram_data_awaddr       : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- awaddr
			-- f2h_sdram_data_awlen        : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- awlen
			-- f2h_sdram_data_awid         : in    std_logic_vector(7 downto 0)   := (others => 'X'); -- awid
			-- f2h_sdram_data_awsize       : in    std_logic_vector(2 downto 0)   := (others => 'X'); -- awsize
			-- f2h_sdram_data_awburst      : in    std_logic_vector(1 downto 0)   := (others => 'X'); -- awburst
			-- f2h_sdram_data_awlock       : in    std_logic_vector(1 downto 0)   := (others => 'X'); -- awlock
			-- f2h_sdram_data_awprot       : in    std_logic_vector(2 downto 0)   := (others => 'X'); -- awprot
			-- f2h_sdram_data_awvalid      : in    std_logic                      := 'X';             -- awvalid
			-- f2h_sdram_data_awcache      : in    std_logic_vector(3 downto 0)   := (others => 'X'); -- awcache
			-- f2h_sdram_data_bresp        : out   std_logic_vector(1 downto 0);                      -- bresp
			-- f2h_sdram_data_bid          : out   std_logic_vector(7 downto 0);                      -- bid
			-- f2h_sdram_data_bvalid       : out   std_logic;                                         -- bvalid
			-- f2h_sdram_data_bready       : in    std_logic                      := 'X';             -- bready
			-- f2h_sdram_data_arready      : out   std_logic;                                         -- arready
			-- f2h_sdram_data_awready      : out   std_logic;                                         -- awready
			-- f2h_sdram_data_rready       : in    std_logic                      := 'X';             -- rready
			-- f2h_sdram_data_rdata        : out   std_logic_vector(255 downto 0);                    -- rdata
			-- f2h_sdram_data_rresp        : out   std_logic_vector(1 downto 0);                      -- rresp
			-- f2h_sdram_data_rlast        : out   std_logic;                                         -- rlast
			-- f2h_sdram_data_rid          : out   std_logic_vector(7 downto 0);                      -- rid
			-- f2h_sdram_data_rvalid       : out   std_logic;                                         -- rvalid
			-- f2h_sdram_data_wlast        : in    std_logic                      := 'X';             -- wlast
			-- f2h_sdram_data_wvalid       : in    std_logic                      := 'X';             -- wvalid
			-- f2h_sdram_data_wdata        : in    std_logic_vector(255 downto 0) := (others => 'X'); -- wdata
			-- f2h_sdram_data_wstrb        : in    std_logic_vector(31 downto 0)  := (others => 'X'); -- wstrb
			-- f2h_sdram_data_wready       : out   std_logic;                                         -- wready
			-- f2h_sdram_data_wid          : in    std_logic_vector(7 downto 0)   := (others => 'X'); -- wid
			-- fs_commands_export          : out   std_logic_vector(3 downto 0);                      -- export
			-- fs_hparams_export           : out   std_logic_vector(31 downto 0);                     -- export
			-- fs_offset0_export           : out   std_logic_vector(31 downto 0);                     -- export
			-- fs_offset1_export           : out   std_logic_vector(31 downto 0);                     -- export
			-- fs_offset2_export           : out   std_logic_vector(31 downto 0);                     -- export
			-- fs_vparams_export           : out   std_logic_vector(31 downto 0);                     -- export
			-- h2f_lw_axi_clk              : in    std_logic                      := 'X';             -- clk
			-- io_hps_io_emac1_inst_TX_CLK : out   std_logic;                                         -- hps_io_emac1_inst_TX_CLK
			-- io_hps_io_emac1_inst_TXD0   : out   std_logic;                                         -- hps_io_emac1_inst_TXD0
			-- io_hps_io_emac1_inst_TXD1   : out   std_logic;                                         -- hps_io_emac1_inst_TXD1
			-- io_hps_io_emac1_inst_TXD2   : out   std_logic;                                         -- hps_io_emac1_inst_TXD2
			-- io_hps_io_emac1_inst_TXD3   : out   std_logic;                                         -- hps_io_emac1_inst_TXD3
			-- io_hps_io_emac1_inst_RXD0   : in    std_logic                      := 'X';             -- hps_io_emac1_inst_RXD0
			-- io_hps_io_emac1_inst_MDIO   : inout std_logic                      := 'X';             -- hps_io_emac1_inst_MDIO
			-- io_hps_io_emac1_inst_MDC    : out   std_logic;                                         -- hps_io_emac1_inst_MDC
			-- io_hps_io_emac1_inst_RX_CTL : in    std_logic                      := 'X';             -- hps_io_emac1_inst_RX_CTL
			-- io_hps_io_emac1_inst_TX_CTL : out   std_logic;                                         -- hps_io_emac1_inst_TX_CTL
			-- io_hps_io_emac1_inst_RX_CLK : in    std_logic                      := 'X';             -- hps_io_emac1_inst_RX_CLK
			-- io_hps_io_emac1_inst_RXD1   : in    std_logic                      := 'X';             -- hps_io_emac1_inst_RXD1
			-- io_hps_io_emac1_inst_RXD2   : in    std_logic                      := 'X';             -- hps_io_emac1_inst_RXD2
			-- io_hps_io_emac1_inst_RXD3   : in    std_logic                      := 'X';             -- hps_io_emac1_inst_RXD3
			-- io_hps_io_sdio_inst_CMD     : inout std_logic                      := 'X';             -- hps_io_sdio_inst_CMD
			-- io_hps_io_sdio_inst_D0      : inout std_logic                      := 'X';             -- hps_io_sdio_inst_D0
			-- io_hps_io_sdio_inst_D1      : inout std_logic                      := 'X';             -- hps_io_sdio_inst_D1
			-- io_hps_io_sdio_inst_CLK     : out   std_logic;                                         -- hps_io_sdio_inst_CLK
			-- io_hps_io_sdio_inst_D2      : inout std_logic                      := 'X';             -- hps_io_sdio_inst_D2
			-- io_hps_io_sdio_inst_D3      : inout std_logic                      := 'X';             -- hps_io_sdio_inst_D3
			-- io_hps_io_usb1_inst_D0      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D0
			-- io_hps_io_usb1_inst_D1      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D1
			-- io_hps_io_usb1_inst_D2      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D2
			-- io_hps_io_usb1_inst_D3      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D3
			-- io_hps_io_usb1_inst_D4      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D4
			-- io_hps_io_usb1_inst_D5      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D5
			-- io_hps_io_usb1_inst_D6      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D6
			-- io_hps_io_usb1_inst_D7      : inout std_logic                      := 'X';             -- hps_io_usb1_inst_D7
			-- io_hps_io_usb1_inst_CLK     : in    std_logic                      := 'X';             -- hps_io_usb1_inst_CLK
			-- io_hps_io_usb1_inst_STP     : out   std_logic;                                         -- hps_io_usb1_inst_STP
			-- io_hps_io_usb1_inst_DIR     : in    std_logic                      := 'X';             -- hps_io_usb1_inst_DIR
			-- io_hps_io_usb1_inst_NXT     : in    std_logic                      := 'X';             -- hps_io_usb1_inst_NXT
			-- io_hps_io_spim1_inst_CLK    : out   std_logic;                                         -- hps_io_spim1_inst_CLK
			-- io_hps_io_spim1_inst_MOSI   : out   std_logic;                                         -- hps_io_spim1_inst_MOSI
			-- io_hps_io_spim1_inst_MISO   : in    std_logic                      := 'X';             -- hps_io_spim1_inst_MISO
			-- io_hps_io_spim1_inst_SS0    : out   std_logic;                                         -- hps_io_spim1_inst_SS0
			-- io_hps_io_uart0_inst_RX     : in    std_logic                      := 'X';             -- hps_io_uart0_inst_RX
			-- io_hps_io_uart0_inst_TX     : out   std_logic;                                         -- hps_io_uart0_inst_TX
			-- io_hps_io_i2c0_inst_SDA     : inout std_logic                      := 'X';             -- hps_io_i2c0_inst_SDA
			-- io_hps_io_i2c0_inst_SCL     : inout std_logic                      := 'X';             -- hps_io_i2c0_inst_SCL
			-- io_hps_io_i2c1_inst_SDA     : inout std_logic                      := 'X';             -- hps_io_i2c1_inst_SDA
			-- io_hps_io_i2c1_inst_SCL     : inout std_logic                      := 'X';             -- hps_io_i2c1_inst_SCL
			-- io_hps_io_gpio_inst_GPIO09  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO09
			-- io_hps_io_gpio_inst_GPIO35  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO35
			-- io_hps_io_gpio_inst_GPIO40  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO40
			-- io_hps_io_gpio_inst_GPIO53  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO53
			-- io_hps_io_gpio_inst_GPIO54  : inout std_logic                      := 'X';             -- hps_io_gpio_inst_GPIO54
			-- io_hps_io_gpio_inst_GPIO61  : inout std_logic                      := 'X'              -- hps_io_gpio_inst_GPIO61
		-- );
	-- end component soc_system;
      
begin

	u0 : entity soc_system.soc_system
		port map (
			h2f_lw_axi_clk              => h2f_lw_axi_clk,              --     h2f_lw_axi.clk
			f2h_sdram_clk_clk           => f2h_sdram_clk_clk,           --  f2h_sdram_clk.clk
			f2h_sdram_data_araddr       => f2h_sdram_data_m2s.araddr,       -- f2h_sdram_data.araddr
			f2h_sdram_data_arlen        => f2h_sdram_data_m2s.arlen(3 downto 0),        --               .arlen
			f2h_sdram_data_arid         => f2h_sdram_data_m2s.arid,         --               .arid
			f2h_sdram_data_arsize       => f2h_sdram_data_m2s.arsize,       --               .arsize
			f2h_sdram_data_arburst      => f2h_sdram_data_m2s.arburst,      --               .arburst
			f2h_sdram_data_arlock       => f2h_sdram_data_m2s.arlock,       --               .arlock
			f2h_sdram_data_arprot       => f2h_sdram_data_m2s.arprot,       --               .arprot
			f2h_sdram_data_arvalid      => f2h_sdram_data_m2s.arvalid,      --               .arvalid
			f2h_sdram_data_arcache      => f2h_sdram_data_m2s.arcache,      --               .arcache
			f2h_sdram_data_awaddr       => f2h_sdram_data_m2s.awaddr,       --               .awaddr
			f2h_sdram_data_awlen        => f2h_sdram_data_m2s.awlen(3 downto 0),        --               .awlen
			f2h_sdram_data_awid         => f2h_sdram_data_m2s.awid,         --               .awid
			f2h_sdram_data_awsize       => f2h_sdram_data_m2s.awsize,       --               .awsize
			f2h_sdram_data_awburst      => f2h_sdram_data_m2s.awburst,      --               .awburst
			f2h_sdram_data_awlock       => f2h_sdram_data_m2s.awlock,       --               .awlock
			f2h_sdram_data_awprot       => f2h_sdram_data_m2s.awprot,       --               .awprot
			f2h_sdram_data_awvalid      => f2h_sdram_data_m2s.awvalid,      --               .awvalid
			f2h_sdram_data_awcache      => f2h_sdram_data_m2s.awcache,      --               .awcache
			f2h_sdram_data_bresp        => f2h_sdram_data_s2m.bresp,        --               .bresp
			f2h_sdram_data_bid          => f2h_sdram_data_s2m.bid,          --               .bid
			f2h_sdram_data_bvalid       => f2h_sdram_data_s2m.bvalid,       --               .bvalid
			f2h_sdram_data_bready       => f2h_sdram_data_m2s.bready,       --               .bready
			f2h_sdram_data_arready      => f2h_sdram_data_s2m.arready,      --               .arready
			f2h_sdram_data_awready      => f2h_sdram_data_s2m.awready,      --               .awready
			f2h_sdram_data_rready       => f2h_sdram_data_m2s.rready,       --               .rready
			f2h_sdram_data_rdata        => f2h_sdram_data_rdata,        --               .rdata
			f2h_sdram_data_rresp        => f2h_sdram_data_s2m.rresp,        --               .rresp
			f2h_sdram_data_rlast        => f2h_sdram_data_s2m.rlast,        --               .rlast
			f2h_sdram_data_rid          => f2h_sdram_data_s2m.rid,          --               .rid
			f2h_sdram_data_rvalid       => f2h_sdram_data_s2m.rvalid,       --               .rvalid
			f2h_sdram_data_wlast        => f2h_sdram_data_m2s.wlast,        --               .wlast
			f2h_sdram_data_wvalid       => f2h_sdram_data_m2s.wvalid,       --               .wvalid
			f2h_sdram_data_wdata        => f2h_sdram_data_wdata,        --               .wdata
			f2h_sdram_data_wstrb        => (others => '1'),               --               .wstrb
			f2h_sdram_data_wready       => f2h_sdram_data_s2m.wready,       --               .wready
			f2h_sdram_data_wid          => f2h_sdram_data_m2s.wid,          --               .wid
            
			io_hps_io_emac1_inst_TX_CLK => io_hps_io_emac1_inst_TX_CLK, --             io.hps_io_emac1_inst_TX_CLK
			io_hps_io_emac1_inst_TXD0   => io_hps_io_emac1_inst_TXD0,   --               .hps_io_emac1_inst_TXD0
			io_hps_io_emac1_inst_TXD1   => io_hps_io_emac1_inst_TXD1,   --               .hps_io_emac1_inst_TXD1
			io_hps_io_emac1_inst_TXD2   => io_hps_io_emac1_inst_TXD2,   --               .hps_io_emac1_inst_TXD2
			io_hps_io_emac1_inst_TXD3   => io_hps_io_emac1_inst_TXD3,   --               .hps_io_emac1_inst_TXD3
			io_hps_io_emac1_inst_RXD0   => io_hps_io_emac1_inst_RXD0,   --               .hps_io_emac1_inst_RXD0
			io_hps_io_emac1_inst_MDIO   => io_hps_io_emac1_inst_MDIO,   --               .hps_io_emac1_inst_MDIO
			io_hps_io_emac1_inst_MDC    => io_hps_io_emac1_inst_MDC,    --               .hps_io_emac1_inst_MDC
			io_hps_io_emac1_inst_RX_CTL => io_hps_io_emac1_inst_RX_CTL, --               .hps_io_emac1_inst_RX_CTL
			io_hps_io_emac1_inst_TX_CTL => io_hps_io_emac1_inst_TX_CTL, --               .hps_io_emac1_inst_TX_CTL
			io_hps_io_emac1_inst_RX_CLK => io_hps_io_emac1_inst_RX_CLK, --               .hps_io_emac1_inst_RX_CLK
			io_hps_io_emac1_inst_RXD1   => io_hps_io_emac1_inst_RXD1,   --               .hps_io_emac1_inst_RXD1
			io_hps_io_emac1_inst_RXD2   => io_hps_io_emac1_inst_RXD2,   --               .hps_io_emac1_inst_RXD2
			io_hps_io_emac1_inst_RXD3   => io_hps_io_emac1_inst_RXD3,   --               .hps_io_emac1_inst_RXD3
			io_hps_io_sdio_inst_CMD     => io_hps_io_sdio_inst_CMD,     --               .hps_io_sdio_inst_CMD
			io_hps_io_sdio_inst_D0      => io_hps_io_sdio_inst_D0,      --               .hps_io_sdio_inst_D0
			io_hps_io_sdio_inst_D1      => io_hps_io_sdio_inst_D1,      --               .hps_io_sdio_inst_D1
			io_hps_io_sdio_inst_CLK     => io_hps_io_sdio_inst_CLK,     --               .hps_io_sdio_inst_CLK
			io_hps_io_sdio_inst_D2      => io_hps_io_sdio_inst_D2,      --               .hps_io_sdio_inst_D2
			io_hps_io_sdio_inst_D3      => io_hps_io_sdio_inst_D3,      --               .hps_io_sdio_inst_D3
			io_hps_io_usb1_inst_D0      => io_hps_io_usb1_inst_D0,      --               .hps_io_usb1_inst_D0
			io_hps_io_usb1_inst_D1      => io_hps_io_usb1_inst_D1,      --               .hps_io_usb1_inst_D1
			io_hps_io_usb1_inst_D2      => io_hps_io_usb1_inst_D2,      --               .hps_io_usb1_inst_D2
			io_hps_io_usb1_inst_D3      => io_hps_io_usb1_inst_D3,      --               .hps_io_usb1_inst_D3
			io_hps_io_usb1_inst_D4      => io_hps_io_usb1_inst_D4,      --               .hps_io_usb1_inst_D4
			io_hps_io_usb1_inst_D5      => io_hps_io_usb1_inst_D5,      --               .hps_io_usb1_inst_D5
			io_hps_io_usb1_inst_D6      => io_hps_io_usb1_inst_D6,      --               .hps_io_usb1_inst_D6
			io_hps_io_usb1_inst_D7      => io_hps_io_usb1_inst_D7,      --               .hps_io_usb1_inst_D7
			io_hps_io_usb1_inst_CLK     => io_hps_io_usb1_inst_CLK,     --               .hps_io_usb1_inst_CLK
			io_hps_io_usb1_inst_STP     => io_hps_io_usb1_inst_STP,     --               .hps_io_usb1_inst_STP
			io_hps_io_usb1_inst_DIR     => io_hps_io_usb1_inst_DIR,     --               .hps_io_usb1_inst_DIR
			io_hps_io_usb1_inst_NXT     => io_hps_io_usb1_inst_NXT,     --               .hps_io_usb1_inst_NXT
			io_hps_io_spim1_inst_CLK    => io_hps_io_spim1_inst_CLK,    --               .hps_io_spim1_inst_CLK
			io_hps_io_spim1_inst_MOSI   => io_hps_io_spim1_inst_MOSI,   --               .hps_io_spim1_inst_MOSI
			io_hps_io_spim1_inst_MISO   => io_hps_io_spim1_inst_MISO,   --               .hps_io_spim1_inst_MISO
			io_hps_io_spim1_inst_SS0    => io_hps_io_spim1_inst_SS0,    --               .hps_io_spim1_inst_SS0
			io_hps_io_uart0_inst_RX     => io_hps_io_uart0_inst_RX,     --               .hps_io_uart0_inst_RX
			io_hps_io_uart0_inst_TX     => io_hps_io_uart0_inst_TX,     --               .hps_io_uart0_inst_TX
			io_hps_io_i2c0_inst_SDA     => io_hps_io_i2c0_inst_SDA,     --               .hps_io_i2c0_inst_SDA
			io_hps_io_i2c0_inst_SCL     => io_hps_io_i2c0_inst_SCL,     --               .hps_io_i2c0_inst_SCL
			io_hps_io_i2c1_inst_SDA     => io_hps_io_i2c1_inst_SDA,     --               .hps_io_i2c1_inst_SDA
			io_hps_io_i2c1_inst_SCL     => io_hps_io_i2c1_inst_SCL,     --               .hps_io_i2c1_inst_SCL
			io_hps_io_gpio_inst_GPIO09  => io_hps_io_gpio_inst_GPIO09,  --               .hps_io_gpio_inst_GPIO09
			io_hps_io_gpio_inst_GPIO35  => io_hps_io_gpio_inst_GPIO35,  --               .hps_io_gpio_inst_GPIO35
			io_hps_io_gpio_inst_GPIO40  => io_hps_io_gpio_inst_GPIO40,  --               .hps_io_gpio_inst_GPIO40
			io_hps_io_gpio_inst_GPIO53  => io_hps_io_gpio_inst_GPIO53,  --               .hps_io_gpio_inst_GPIO53
			io_hps_io_gpio_inst_GPIO54  => io_hps_io_gpio_inst_GPIO54,  --               .hps_io_gpio_inst_GPIO54
			io_hps_io_gpio_inst_GPIO61  => io_hps_io_gpio_inst_GPIO61,  --               .hps_io_gpio_inst_GPIO61
			ddr3_mem_a                  => ddr3_mem_a,                  --           ddr3.mem_a
			ddr3_mem_ba                 => ddr3_mem_ba,                 --               .mem_ba
			ddr3_mem_ck                 => ddr3_mem_ck,                 --               .mem_ck
			ddr3_mem_ck_n               => ddr3_mem_ck_n,               --               .mem_ck_n
			ddr3_mem_cke                => ddr3_mem_cke,                --               .mem_cke
			ddr3_mem_cs_n               => ddr3_mem_cs_n,               --               .mem_cs_n
			ddr3_mem_ras_n              => ddr3_mem_ras_n,              --               .mem_ras_n
			ddr3_mem_cas_n              => ddr3_mem_cas_n,              --               .mem_cas_n
			ddr3_mem_we_n               => ddr3_mem_we_n,               --               .mem_we_n
			ddr3_mem_reset_n            => ddr3_mem_reset_n,            --               .mem_reset_n
			ddr3_mem_dq                 => ddr3_mem_dq,                 --               .mem_dq
			ddr3_mem_dqs                => ddr3_mem_dqs,                --               .mem_dqs
			ddr3_mem_dqs_n              => ddr3_mem_dqs_n,              --               .mem_dqs_n
			ddr3_mem_odt                => ddr3_mem_odt,                --               .mem_odt
			ddr3_mem_dm                 => ddr3_mem_dm,                 --               .mem_dm
			ddr3_oct_rzqin              => ddr3_oct_rzqin,              --               .oct_rzqin
			fs_hparams_export           => fs_hparams_export,           --     fs_hparams.export
			fs_vparams_export           => fs_vparams_export,           --     fs_vparams.export
			fs_offset0_export           => fs_offset0_export,           --     fs_offset0.export
			fs_offset1_export           => fs_offset1_export,           --     fs_offset1.export
			fs_offset2_export           => fs_offset2_export,           --     fs_offset2.export
			fs_commands_export          => fs_commands_export           --    fs_commands.export
		);

	
end arch;