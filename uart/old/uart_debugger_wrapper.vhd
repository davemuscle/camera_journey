library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

use work.uart_debugger_pkg.all;

--Wrapper for COM Port -> UART -> FPGA Registers


entity uart_debugger_wrapper is
    generic(
        CLKRATE : integer := 50000000;
        BAUDRATE : integer := 115200;
        NUM_SLAVES : integer := 2;
        NUM_SLAVES_LOG2 : integer := 1
    );
	port(
		clk       : in std_logic;
        
        --Virtual Memory Map
        udb_sb_addr    : out std_logic_vector(15 downto 0) := (others => '0');
        udb_sb_wr_data : out std_logic_vector(31 downto 0) := (others => '0');
        udb_sb_wr_reqs : out std_logic_vector(NUM_SLAVES-1 downto 0) := (others => '0');
        udb_sb_rd_reqs : out std_logic_vector(NUM_SLAVES-1 downto 0) := (others => '0');
 
        udb_sb_rd_data : in std_logic_vector(NUM_SLAVES*32 -1 downto 0);
        udb_sb_wr_acks : in std_logic_vector(NUM_SLAVES-1 downto 0);
        udb_sb_rd_acks : in std_logic_vector(NUM_SLAVES-1 downto 0);
        
        --UART signals
		tx        : out std_logic;
		rx        : in std_logic;
		uart_fifo_status : out std_logic_vector(3 downto 0)
        
	);
end uart_debugger_wrapper;

architecture arch of uart_debugger_wrapper is 

	signal uart_rx_valid : std_logic := '0';
	signal uart_rd_en    : std_logic := '0';
	signal uart_rd_data  : std_logic_vector(7 downto 0) := (others => '0');
	signal uart_tx_ready : std_logic := '0';
	signal uart_wr_en    : std_logic := '0';
	signal uart_wr_data  : std_logic_vector(7 downto 0) := x"00";

	
	signal tx_fifo_ov, tx_fifo_un, rx_fifo_ov, rx_fifo_un : std_logic := '0';

    
	signal udb_master_data : udb_master := udb_master_init;
	signal udb_slave_data : udb_slave := udb_slave_init;
     
begin

	uart_sb_inst : entity work.uart_debugger_switchbox
    generic map(
        NUM_SLAVES      =>      NUM_SLAVES,
        NUM_SLAVES_LOG2 => NUM_SLAVES_LOG2
    
    )
	port map(
        clk => clk,
		udb_mm_i   => udb_master_data,
		udb_mm_o   => udb_slave_data,
        
        udb_sb_addr_o => udb_sb_addr,
        udb_sb_data_o => udb_sb_wr_data,
        udb_wr_reqs_o => udb_sb_wr_reqs,
        udb_rd_reqs_o => udb_sb_rd_reqs,
        
        udb_sb_data_i => udb_sb_rd_data,
        udb_wr_acks_i => udb_sb_wr_acks,
        udb_rd_acks_i => udb_sb_rd_acks
        
        
	);
	
	uart_db_inst : entity work.uart_debugger
    generic map(
        TIMEOUT_MAX => CLKRATE
    )
	port map(
		clk        => clk,
		rx_valid   => uart_rx_valid,
		rx_rd_en   => uart_rd_en,
		rx_rd_data => uart_rd_data,
		tx_ready   => uart_tx_ready,
		tx_wr_en   => uart_wr_en,
		tx_wr_data => uart_wr_data,
		udb_mm_o   => udb_master_data,
		udb_mm_i   => udb_slave_data
	);

    uart_fifo_status(3) <= tx_fifo_ov;
    uart_fifo_status(2) <= tx_fifo_un;
    uart_fifo_status(1) <= rx_fifo_ov;
    uart_fifo_status(0) <= rx_fifo_un;

	uart_inst : entity work.uart
	generic map(
		CLKRATE  =>  CLKRATE,
		BAUDRATE => BAUDRATE,
		DATA_SIZE =>       8,
		FIFO_SIZE =>      16
	)
	port map(
		clk        => clk,
		rx         => rx,
		tx         => tx,
		rx_valid   => uart_rx_valid,
		rx_full    => open,
		rx_rd_en   => uart_rd_en,
		rx_rd_data => uart_rd_data,
		rx_fifo_ov => rx_fifo_ov,
		rx_fifo_un => rx_fifo_un,
		tx_ready   => uart_tx_ready,
		tx_empty   => open,
		tx_wr_en   => uart_wr_en,
		tx_wr_data => uart_wr_data,
		tx_fifo_ov => tx_fifo_ov,
		tx_fifo_un => tx_fifo_un
	);

	
end arch;