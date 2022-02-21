library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Contains records for AXI transactions

--I'm specifially leaving wdata, wstrb, and rdata out of the AXI records
--This is because I like VHDL '93 (limited tool support for 2008), and 
--I haven't found a good way to parameterize the records. 
--It's easier to just have slvs for these two (wstrb is rare) data signals

package axi_pkg is
    
    --AXI Full Master to Slave
	type axi4_m2s is record
		awvalid : std_logic;
        awaddr  : std_logic_vector(31 downto 0);
        awlen   : std_logic_vector( 7 downto 0);
        awsize  : std_logic_vector( 2 downto 0);
        awburst : std_logic_vector( 1 downto 0);
        awid    : std_logic_vector( 7 downto 0);
        awlock  : std_logic_vector( 1 downto 0);
        awprot  : std_logic_vector( 2 downto 0);
        awcache : std_logic_vector( 3 downto 0);
		arvalid : std_logic;
        araddr  : std_logic_vector(31 downto 0);
        arlen   : std_logic_vector( 7 downto 0);
        arsize  : std_logic_vector( 2 downto 0);
        arburst : std_logic_vector( 1 downto 0);
        arid    : std_logic_vector( 7 downto 0);
        arlock  : std_logic_vector( 1 downto 0);
        arprot  : std_logic_vector( 2 downto 0);
        arcache : std_logic_vector( 3 downto 0);
        wlast   : std_logic;
        wvalid  : std_logic;
        wid     : std_logic_vector(7 downto 0);
        bready  : std_logic;
        rready  : std_logic;  
	end record axi4_m2s;
    
    --AXI Full Slave to Master
	type axi4_s2m is record
		awready : std_logic;
        arready : std_logic;
        wready  : std_logic;
        bvalid  : std_logic;
        bresp   : std_logic_vector(1 downto 0);
        bid     : std_logic_vector(7 downto 0);
        rlast   : std_logic;
        rvalid  : std_logic;
        rid     : std_logic_vector(7 downto 0);
        rresp   : std_logic_vector(1 downto 0);
	end record axi4_s2m;
    
    --AXI Full Master to Slave Init
    constant axi4_m2s_init : axi4_m2s := (
        awvalid => '0',
        awaddr  => (others => '0'),
        awlen   => (others => '0'),
        awsize  => (others => '0'),
        awburst => (others => '0'),
        awid    => (others => '0'),
        awlock  => (others => '0'),
        awprot  => (others => '0'),
        awcache => (others => '0'),
        arvalid => '0',
        araddr  => (others => '0'),
        arlen   => (others => '0'),
        arsize  => (others => '0'),
        arburst => (others => '0'),
        arid    => (others => '0'),
        arlock  => (others => '0'),
        arprot  => (others => '0'),
        arcache => (others => '0'),
        wlast   => '0',
        wvalid  => '0',
        wid     => (others => '0'),
        bready  => '0',
        rready  => '0'
    );
    
    --AXI Full Slave to Master Init
    constant axi4_s2m_init : axi4_s2m := (
        awready => '0',
        arready => '0',
        wready  => '0',
        bvalid  => '0',
        bresp   => (others => '0'),
        bid     => (others => '0'),
        rlast   => '0',
        rvalid  => '0',
        rid     => (others => '0'),
        rresp   => (others => '0')
    );
    
    --AXI Lite Master to Slave
	type axi4_lite_m2s is record
		awvalid : std_logic;
        awaddr  : std_logic_vector(31 downto 0);
		arvalid : std_logic;
        araddr  : std_logic_vector(31 downto 0);
        wlast   : std_logic;
        wvalid  : std_logic;
        bready  : std_logic;
        rready  : std_logic;  
	end record axi4_lite_m2s;

    --AXI Lite Slave to Master
	type axi4_lite_s2m is record
		awready : std_logic;
        arready : std_logic;
        wready  : std_logic;
        bvalid  : std_logic;
        bresp   : std_logic_vector(1 downto 0);
        rlast   : std_logic;
        rvalid  : std_logic;
        rresp   : std_logic_vector(1 downto 0);
	end record axi4_lite_s2m;

    --AXI Lite Master to Slave Init
    constant axi4_lite_m2s_init : axi4_lite_m2s := (
        awvalid => '0',
        awaddr  => (others => '0'),
        arvalid => '0',
        araddr  => (others => '0'),
        wlast   => '0',
        wvalid  => '0',
        bready  => '0',
        rready  => '0'
    );
    
    --AXI Lite Slave to Master Init
    constant axi4_lite_s2m_init : axi4_lite_s2m := (
        awready => '0',
        arready => '0',
        wready  => '0',
        bvalid  => '0',
        bresp   => (others => '0'),
        rlast   => '0',
        rvalid  => '0',
        rresp   => (others => '0')
    );

end axi_pkg;