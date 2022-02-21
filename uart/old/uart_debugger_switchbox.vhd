library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

use work.uart_debugger_pkg.all;

--The switchbox organizes the virtual address into evenly aligned pages specified by a generic

--For timing, put false paths on udb_sb_data_o and udb_sb_addr_o
--Dual-flop syncs use to synchronize the req and ack signals 

entity uart_debugger_switchbox is
    generic(
        NUM_SLAVES : integer := 16;
        NUM_SLAVES_LOG2 : integer := 4
    );
	port(
    
        --clock to uart debugger
        clk : in std_logic;
    
		--Memory mapped record
		udb_mm_i : in  udb_master;
		udb_mm_o : out udb_slave;
        
        --Output Address
        udb_sb_addr_o : out std_logic_vector(15 downto 0);
        udb_sb_data_o : out std_logic_vector(31 downto 0);
        udb_wr_reqs_o : out std_logic_vector(NUM_SLAVES-1 downto 0);
        udb_rd_reqs_o : out std_logic_vector(NUM_SLAVES-1 downto 0);
        
        --Input Acks and Read Data
        udb_sb_data_i : in std_logic_vector(32*NUM_SLAVES - 1 downto 0);
        udb_wr_acks_i : in  std_logic_vector(NUM_SLAVES-1 downto 0);
        udb_rd_acks_i : in  std_logic_vector(NUM_SLAVES-1 downto 0)
        
	
	);
end uart_debugger_switchbox;

architecture bhv of uart_debugger_switchbox is 

    signal udb_dbg_main_addr : std_logic_vector(15 downto 0) := (others => '0');
    signal udb_dbg_addr_mask : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(2**(16-NUM_SLAVES_LOG2)-1,16));
    signal udb_dbg_main_page : std_logic_vector(NUM_SLAVES_LOG2-1 downto 0) := (others => '0');
    signal page_num : integer := 0;
    
    signal udb_dbg_wr_req, udb_dbg_rd_req : std_logic := '0';
    signal udb_dbg_wr_ack, udb_dbg_rd_ack : std_logic := '0';

    signal wr_ack_meta, wr_ack_sync : std_logic := '0';
    signal rd_ack_meta, rd_ack_sync : std_logic := '0';

begin

    udb_dbg_main_addr <= udb_mm_i.addr;
    udb_dbg_main_page <= udb_dbg_main_addr(16-1 downto 16 - NUM_SLAVES_LOG2);
    page_num <= to_integer(unsigned(udb_dbg_main_page));

    udb_dbg_wr_req <= udb_mm_i.wr_req;
    udb_dbg_rd_req <= udb_mm_i.rd_req;
    
    udb_sb_data_o <= udb_mm_i.wr_data;
    --mask out the address bits used for selecting the page
    --now, the address is offset to zero, and the register file is chosen by muxing the wr and rd reqs
    udb_sb_addr_o <= udb_dbg_main_addr and udb_dbg_addr_mask;
    
    --assign outputs to be sent to the udb_mm_o record, which flows back to the debugger
    process(page_num, udb_sb_data_i, udb_wr_acks_i, udb_rd_acks_i)
    begin
    
        udb_mm_o.rd_data <= udb_sb_data_i((page_num+1)*32-1 downto page_num*32);
        --udb_mm_o.wr_ack  <= udb_wr_acks_i(page_num);
        --udb_mm_o.rd_ack  <= udb_rd_acks_i(page_num);
        
    end process;
   
   --add two clocks to sync the single bits for the acks
   --these are levels and act as a handshake for the transaction
    process(clk)
    begin
        if(rising_edge(clk)) then
        
            wr_ack_meta  <= udb_wr_acks_i(page_num);
            wr_ack_sync  <= wr_ack_meta;
            
            rd_ack_meta  <= udb_rd_acks_i(page_num);
            rd_ack_sync  <= rd_ack_meta;
            
        end if;
    end process;
    
    udb_mm_o.wr_ack <= wr_ack_sync;
    udb_mm_o.rd_ack <= rd_ack_sync;
    
   
   --assign outputs for the wr and rd requests based on address
    process(page_num, udb_dbg_wr_req, udb_dbg_rd_req)
    begin
        
        udb_wr_reqs_o <= (others => '0');
        udb_wr_reqs_o(page_num) <= udb_dbg_wr_req;
        
        udb_rd_reqs_o <= (others => '0');
        udb_rd_reqs_o(page_num) <= udb_dbg_rd_req;
    
    end process;
end bhv;		

