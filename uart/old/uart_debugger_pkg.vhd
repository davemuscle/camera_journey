library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Contains records for the UART debugger

package uart_debugger_pkg is

	type udb_master is record
		addr    : std_logic_vector(15 downto 0);
		wr_req  : std_logic;
		wr_data : std_logic_vector(31 downto 0);
		rd_req  : std_logic;
	end record udb_master;
	
	type udb_slave is record
		wr_ack  : std_logic;
		rd_ack  : std_logic;
		rd_data : std_logic_vector(31 downto 0);
	end record udb_slave;

	constant udb_master_init : udb_master := (
		addr    => (others => '0'),
		wr_req  => '0',
		wr_data => (others => '0'),
		rd_req  => '0'
	);
	
	constant udb_slave_init : udb_slave := (
		wr_ack  => '0',
		rd_ack  => '0',
		rd_data => (others => '0')
	);
	
end uart_debugger_pkg;