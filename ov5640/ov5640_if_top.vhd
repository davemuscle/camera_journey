library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.uart_debugger_pkg.all;

entity top is
	port(
    	clk_board  : in  std_logic;
		
        tx : out std_logic;
        rx : in  std_logic;
        
		sda : inout std_logic;
		scl : inout std_logic;
		
		sda_debug : out std_logic;
		scl_debug : out std_logic;
	
		cam_xclk : out std_logic;
		cam_reset : out std_logic;
		cam_pwdn : out std_logic
		
        );
end top;

architecture str of top is 

    signal udb_mm_master : udb_master := udb_master_init;
    signal udb_mm_slave : udb_slave := udb_slave_init;
    
    signal udb_sb_addr : std_logic_vector(15 downto 0) := (others => '0');
    signal udb_sb_wr_data : std_logic_vector(31 downto 0) := (others => '0');
    signal udb_sb_wr_reqs : std_logic_vector(0 downto 0) := (others => '0');
    signal udb_sb_rd_reqs : std_logic_vector(0 downto 0) := (others => '0');
 
    signal udb_sb_rd_data : std_logic_vector(1*32 -1 downto 0) := (others => '0');
    signal udb_sb_wr_acks : std_logic_vector(0 downto 0) := (others => '0');
    signal udb_sb_rd_acks : std_logic_vector(0 downto 0) := (others => '0');
    
begin
	
	scl_debug <= scl;
	sda_debug <= sda;
	

    camera_wrapper_inst : entity work.ov5640_wrapper
	generic map(
		I2C_CLK_DIV => 500,
        CLK_DIV_1ms => 50000,
        REGFILE_SIZE => x"0008",
        SIM => false
	)
	port map(
    	clk => clk_board,

        udb_mm_i => udb_mm_master,
        udb_mm_o => udb_mm_slave,

		cam_sda => sda,
        cam_scl => scl,
        
        cam_xclk  => cam_xclk,
        cam_reset => cam_reset,
        cam_pwdn  => cam_pwdn

	);
    
    udb_mm_master.wr_req <= udb_sb_wr_reqs(0);
    udb_mm_master.rd_req <= udb_sb_rd_reqs(0);
    udb_mm_master.wr_data <= udb_sb_wr_data;
    udb_mm_master.addr <= udb_sb_addr;
    
    udb_sb_rd_data(31 downto 0) <= udb_mm_slave.rd_data;
    udb_sb_wr_acks(0) <= udb_mm_slave.wr_ack;
    udb_sb_rd_acks(0) <= udb_mm_slave.rd_ack;
    

    debugger_inst : entity work.uart_debugger_wrapper
    generic map(
        CLKRATE         => 50000000,
        BAUDRATE        =>   115200,
        NUM_SLAVES      =>        1,
        NUM_SLAVES_LOG2 =>        0
    )
	port map(
		clk       => clk_board,
        
        --Virtual Memory Map
        udb_sb_addr    => udb_sb_addr   ,
        udb_sb_wr_data => udb_sb_wr_data,
        udb_sb_wr_reqs => udb_sb_wr_reqs,
        udb_sb_rd_reqs => udb_sb_rd_reqs,
 
        udb_sb_rd_data => udb_sb_rd_data,
        udb_sb_wr_acks => udb_sb_wr_acks,
        udb_sb_rd_acks => udb_sb_rd_acks,
        
        --UART signals
		tx        => tx,
		rx        => rx,
		uart_fifo_status => open
        
	);	
	

	
end str;