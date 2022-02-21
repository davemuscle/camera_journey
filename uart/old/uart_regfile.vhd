library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

use work.uart_debugger_pkg.all;

entity uart_regfile is
    generic(
        REGFILE_ADDR_SIZE : std_logic_vector(15 downto 0);
        USE_BRAM          : boolean;
        REG_WIDTH         : integer
    );
	port(
		clk   : in std_logic;

		--Memory mapped record
		udb_mm_i : in  udb_master;
		udb_mm_o : out udb_slave;
        
        user_logic_wr_en   : in  std_logic;
        user_logic_rd_en   : in  std_logic;
        user_logic_addr    : in  std_logic_vector(15 downto 0);
        user_logic_wr_data : in  std_logic_vector(REG_WIDTH-1 downto 0);
        user_logic_rd_data : out std_logic_vector(REG_WIDTH-1 downto 0);
        user_logic_tick    : out std_logic;
        user_logic_tick_addr : out std_logic_vector(15 downto 0);
        user_logic_tick_data : out std_logic_vector(REG_WIDTH-1 downto 0) := (others => '0')
	
	);
end uart_regfile;

architecture bhv of uart_regfile is 
	
    constant REGFILE_SIZE : integer := to_integer(unsigned(REGFILE_ADDR_SIZE));
    constant LAST_REG : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(REGFILE_SIZE-1,16));
    type reg_array is array(0 to REGFILE_SIZE-1) of std_logic_vector(REG_WIDTH-1 downto 0);
    signal regs : reg_array := (others => (others => '0'));

    signal wra : std_logic := '0';
    signal ena : std_logic := '0';
    signal wrb : std_logic := '0';
    signal enb : std_logic := '0';

    signal addra : std_logic_vector(REGFILE_SIZE-1 downto 0) := (others => '0');
    signal addrb : std_logic_vector(REGFILE_SIZE-1 downto 0) := (others => '0');

    signal data_wr_a : std_logic_vector(REG_WIDTH-1 downto 0) := (others => '0');
    signal data_rd_a : std_logic_vector(REG_WIDTH-1 downto 0) := (others => '0');

    signal data_wr_b : std_logic_vector(REG_WIDTH-1 downto 0) := (others => '0');
    signal data_rd_b : std_logic_vector(REG_WIDTH-1 downto 0) := (others => '0');
   
    signal uart_wr_done, uart_rd_done : std_logic := '0';
    signal wr_ack, rd_ack : std_logic := '0';
    signal tick : std_logic := '0';
    
    signal wr_req_meta, wr_req_sync : std_logic := '0';
    signal rd_req_meta, rd_req_sync : std_logic := '0';
    
begin

    user_logic_tick <= tick;

    udb_mm_o.wr_ack <= wr_ack;
    udb_mm_o.rd_ack <= rd_ack;

    process(clk)
    begin
        if(rising_edge(clk)) then
        
            --dual flop sync for the request signals
            --these are levels that coordinate a handshake
            wr_req_meta <= udb_mm_i.wr_req;
            wr_req_sync <= wr_req_meta;
            
            rd_req_meta <= udb_mm_i.rd_req;
            rd_req_sync <= rd_req_meta;     
            
        
        
            --debugger write logic
            if(wr_req_sync = '1' and uart_wr_done = '0' and wra = '0') then
                wra <= '1';
            end if;
            
            tick <= '0';
            
            if(wra = '1') then
                wra <= '0';
                uart_wr_done <= '1';
                tick <= '1';
                user_logic_tick_addr <= udb_mm_i.addr;
                user_logic_tick_data <= data_wr_a;
            end if;
            
            if(wr_req_sync = '1' and uart_wr_done = '1') then
                wr_ack <= '1';
            end if;
            
            if(wr_req_sync = '0') then
                wr_ack <= '0';
                uart_wr_done <= '0';
            end if;
            
            --debugger read logic
            if(rd_req_sync = '1' and uart_rd_done = '0' and ena = '0') then
                ena <= '1';
            end if;
            
            if(ena = '1') then
                ena <= '0';
                uart_rd_done <= '1';
            end if;
            
            if(rd_req_sync = '1' and uart_rd_done = '1') then
                rd_ack <= '1';
            end if;
            
            if(rd_req_sync = '0') then
                rd_ack <= '0';
                uart_rd_done <= '0';
            end if;
            
            --if the udb address extends past the number available number of registers, do nothing and timeout
            if(udb_mm_i.addr > LAST_REG) then
                wra <= '0';
                ena <= '0';
                wr_ack <= '0';
                rd_ack <= '0';
            end if;
            
            --registers using LUTS
            if(USE_BRAM = false) then
            
                if(wra = '1') then
                    regs(to_integer(unsigned(addra))) <= data_wr_a;  
                end if;
            
                if(ena = '1') then
                    data_rd_a <= regs(to_integer(unsigned(addra)));
                end if;
                
                if(wrb = '1') then 
                    regs(to_integer(unsigned(addrb))) <= data_wr_b;
                end if;
                
                if(enb = '1') then
                    data_rd_b <= regs(to_integer(unsigned(addrb)));
                end if;
                
            end if;
        
        
        end if;
    end process;

    data_wr_a <= udb_mm_i.wr_data(REG_WIDTH-1 downto 0);
    addra     <= udb_mm_i.addr(REGFILE_SIZE-1 downto 0);
    udb_mm_o.rd_data(REG_WIDTH-1 downto 0) <= data_rd_a;

    wrb <= user_logic_wr_en;
    enb <= user_logic_rd_en;
    data_wr_b <= user_logic_wr_data;
    user_logic_rd_data <= data_rd_b;
    addrb <= user_logic_addr(REGFILE_SIZE-1 downto 0);

    PLACE_BRAM_REGS: if USE_BRAM = true generate 
       
        bram_reg_inst : entity work.inferred_ram
        generic map(
            gDEPTH => REGFILE_SIZE,
            gWIDTH => REG_WIDTH,
            gOREGS => 0
        )
        port map(
            a_clk  => clk,
            a_wr   => wra,
            a_en   => ena,
            a_di   => data_wr_a,
            a_do   => data_rd_a,
            a_addr => addra,
            b_clk  => clk,
            b_wr   => wrb,
            b_en   => enb,
            b_di   => data_wr_b,
            b_do   => data_rd_b,
            b_addr => addrb
        );
    end generate PLACE_BRAM_REGS;
   

end bhv;		

