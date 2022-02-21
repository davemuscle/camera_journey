library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
	
--Designed specfiically for axi3 but is hopefully compatible with axi4
--AXI3 slave
--Also not really tested in HW, meant more for simulation bus testing

--AxSIZE is excluded since I'm always transferring the full data width (hardcode to datawidth)
--  Make sure to shift over the address for this since I think axi is expecting byte address
--AxBURST is excluded since I'm always incrementing (hardcode it to 0b01)
--Strobes kept off, but always tie them to 1

--Addresses are in terms of bytes

use work.axi_pkg.all;

entity axi_bram_model is
	generic(
		DATA_WIDTH  : integer := 128;
        BRAM_TEST_SIZE : integer := 20
	);
	port(
        aclk : in std_logic;
        areset : in std_logic;
        
        axi4_m2s_i : in  axi4_m2s := axi4_m2s_init;
        axi4_s2m_o : out axi4_s2m := axi4_s2m_init;
        axi4_wdata : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        axi4_rdata : out std_logic_vector(DATA_WIDTH-1 downto 0)
        
	);
end axi_bram_model;

architecture arch of axi_bram_model is 

    constant BYTE_SIZE : integer := DATA_WIDTH/8;
    constant SHIFT     : integer := integer(ceil(log2(real(BYTE_SIZE))));
    signal WR_BURST_SIZE_BYTES : integer := 0;
    signal RD_BURST_SIZE_BYTES : integer := 0;
    signal WR_ADDR_BASE : std_logic_vector(15 downto 0) := (others => '0');
    signal RD_ADDR_BASE : std_logic_vector(15 downto 0) := (others => '0');
    signal WR_ADDR_ADJ : std_logic_vector(15 downto 0) := (others => '0');
    signal RD_ADDR_ADJ : std_logic_vector(15 downto 0) := (others => '0');
    
    type ram_t is array(0 to (2**BRAM_TEST_SIZE)-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    shared variable ram : ram_t := (others => (others => '0'));

    signal awready_t, wready_t, arready_t : std_logic := '1';

    signal write_in_prog, read_in_prog : std_logic := '0';
    
    signal wr_addr_start : std_logic_vector(31 downto 0) := (others => '0');
    signal rd_addr_start : std_logic_vector(31 downto 0) := (others => '0');
    signal wr_length     : std_logic_vector(7 downto 0);
    signal rd_length     : std_logic_vector(7 downto 0);
    
    signal rvalid_t : std_logic := '0';
    
    signal read_done : std_logic := '0';
    signal temp : std_logic := '0';

    signal awaddr  : std_logic_vector(31 downto 0) := (others => '0');
    signal awlen   : std_logic_vector(7 downto 0) := (others => '0');
    signal awvalid : std_logic;
    signal awready : std_logic;
    signal wdata   : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal wlast   : std_logic;
    signal wvalid  : std_logic;
    signal wready  : std_logic;
    signal bvalid  : std_logic;
    signal bready  : std_logic;
    signal araddr  : std_logic_vector(31 downto 0) := (others => '0');
    signal arlen   : std_logic_vector(7 downto 0) := (others => '0');
    signal arvalid : std_logic;
    signal arready : std_logic;
    signal rdata   : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal rlast   : std_logic;
    signal rvalid  : std_logic;
    signal rready  : std_logic;
    signal bresp   : std_logic_vector(1 downto 0) := (others => '0');
    
    signal rd_assert_en, wr_assert_en : std_logic := '0';
    signal rd_assert_dly : std_logic_vector(15 downto 0) := (others => '0');
    signal wr_assert_dly : std_logic_vector(15 downto 0) := (others => '0');
    
begin    
    
    --Simulation Stuff
    --Assert for attempting to cross 4kB boundaries
    WR_BURST_SIZE_BYTES <= to_integer(unsigned(awlen)+1)*BYTE_SIZE;
    RD_BURST_SIZE_BYTES <= to_integer(unsigned(arlen)+1)*BYTE_SIZE;
    
    WR_ADDR_BASE <= x"0" & awaddr(11 downto 0); 
    RD_ADDR_BASE <= x"0" & araddr(11 downto 0); 
    
    WR_ADDR_ADJ  <= std_logic_vector(unsigned(WR_ADDR_BASE)+to_unsigned(WR_BURST_SIZE_BYTES,16));
    RD_ADDR_ADJ  <= std_logic_vector(unsigned(RD_ADDR_BASE)+to_unsigned(RD_BURST_SIZE_BYTES,16));
    
    process(aclk)
    begin
        if(rising_edge(aclk)) then
        if(awvalid = '1') then
            if(WR_ADDR_ADJ > x"1000") then
                wr_assert_en <= '1';
                --assert false report "Bad Write Boundary Cross In Axi BRAM Model" severity failure;
            end if;
        end if;
        if(arvalid = '1') then
            if(RD_ADDR_ADJ > x"1000") then
                rd_assert_en <= '1';
                --assert false report "Bad Read Boundary Cross In Axi BRAM Model" severity failure;
            end if;
        end if;
        end if;
    end process;
    

    --AXI AW Signals to Port
    awlen   <= axi4_m2s_i.awlen   ;
    awaddr  <= axi4_m2s_i.awaddr  ;
    awvalid <= axi4_m2s_i.awvalid ;
    axi4_s2m_o.awready <= awready;
    
    --AXI W Signals to Port
    wlast  <= axi4_m2s_i.wlast  ;
    wvalid <= axi4_m2s_i.wvalid ;
    axi4_s2m_o.wready <= wready;
    wdata <= axi4_wdata;
    
    --AXI B Signals to Port
    bready <= axi4_m2s_i.bready;
    axi4_s2m_o.bvalid <= bvalid;
    axi4_s2m_o.bresp <= bresp;
    
    --AXI AR Signals to Port

    arlen   <= axi4_m2s_i.arlen   ;
    araddr  <= axi4_m2s_i.araddr  ;
    arvalid <= axi4_m2s_i.arvalid ;
    axi4_s2m_o.arready <= arready;

    --AXI R Signals to Port
    rready <= axi4_m2s_i.rready;
    axi4_s2m_o.rvalid <= rvalid;
    axi4_s2m_o.rlast  <= rlast;
    axi4_rdata <= rdata;


    awready <= awready_t;
    wready  <= wready_t;
    arready <= arready_t;
    rvalid <= rvalid_t;

    process(aclk)
    begin
        if(rising_edge(aclk)) then
            awready_t <= '0';
            wready_t <= '0';
            arready_t <= '0';
            rlast <= '0';
            bvalid <= '1';
            
            wr_assert_dly <= wr_assert_dly(14 downto 0) & wr_assert_en;
            rd_assert_dly <= rd_assert_dly(14 downto 0) & rd_assert_en;
            if(wr_assert_dly(15) = '1') then
                assert false report "Bad Write Boundary Cross In Axi BRAM Model" severity failure;
            end if;
            if(rd_assert_dly(15) = '1') then
                assert false report "Bad Read Boundary Cross In Axi BRAM Model" severity failure;
            end if;
            
            if(awvalid = '1' and arvalid = '0' and read_in_prog = '0') then
                awready_t <= '1';
            end if;
            --Write Address Sequence
            if(awready_t = '1' and awvalid = '1' and arvalid = '0') then
                write_in_prog <= '1';
                read_in_prog <= '0';
                awready_t <= '0';
                wready_t  <= '0';
                arready_t <= '0';
                --Convert byte address to words
                wr_addr_start <= std_logic_vector(unsigned(awaddr) srl SHIFT);
                wr_length <= awlen;
            end if;
            --Do a transfer, then check the wr_length == 0
            --This makes it so that wr_length=0 is for a BURST of 1 
            if(write_in_prog = '1') then
                wready_t <= '1';
                if(wready_t = '1' and wvalid = '1') then
                    --write beat
                    if(wr_length = x"00" and wlast = '1') then
                        write_in_prog <= '0';
                        wready_t <= '0';
                    else
                        wr_length <= std_logic_vector(unsigned(wr_length)-1);
                    end if;
                    wr_addr_start <= std_logic_vector(unsigned(wr_addr_start) + 1);
                    ram(to_integer(unsigned(wr_addr_start))) := wdata;
                end if;
            end if;
            if(arvalid = '1' and write_in_prog = '0' and read_in_prog = '0') then
                arready_t <= '1';
            end if;
            if(arready_t = '1' and arvalid = '1') then
                write_in_prog <= '0';
                read_in_prog <= '1';
                awready_t <= '0';
                wready_t  <= '0';
                arready_t <= '0';
                rd_addr_start <= std_logic_vector(unsigned(araddr) srl SHIFT);
                rd_length <= arlen;
                read_done <= '1';
            end if;
            --Read Transfers
            if(read_in_prog = '1') then
                rdata  <= ram(to_integer(unsigned(rd_addr_start)));
                rvalid_t <= read_done;
                read_done <= '1';
                if(rd_length = x"00") then
                    rlast <= '1';
                end if;
                if(rvalid_t = '1' and rready = '1') then
                    --read beat
                    rvalid_t <= '0';
                    if(rd_length = x"00") then
                        read_in_prog <= '0';
                        rvalid_t <= '0';
                    else
                        rd_length <= std_logic_vector(unsigned(rd_length)-1);
                    end if;
                    read_done <= '0';
                    rd_addr_start <= std_logic_vector(unsigned(rd_addr_start)+1);
                end if;
            end if;
            
            if(areset = '1') then
                write_in_prog <= '0';
                read_in_prog  <= '0';
                rvalid_t <= '0';
                rlast    <= '0';
                awready_t  <= '0';
                wready_t <= '0';
                arready_t <= '0';
                read_done <= '0';
                bvalid <= '0';
            end if;
            
        end if;
    end process;
    
end arch;