library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

--AXI Master, designed for writing into AXI memory
--Reads a selectable amount of data into a FIFO from a slave
--Writes a selectable amount of data into a slave from a FIFO

-- Does not use strb, id, cache, prot, lock (basic AXI only) 
-- Tie the strobe bits to 1
-- Cache and prot are tied to constant
-- Lock is tied to 0

use work.axi_pkg.all;

entity axi_datamover is
	generic(
		DATA_WIDTH     : integer := 128;
        MAX_BURST      : integer := 16;
        TIMEOUT_CLOCKS : integer := 50000
	);
	port(
        --clocks and reset -------------------------------
		clk : in std_logic;
        rst : in std_logic;
        --control and status
        go           : in std_logic; -- pulse
        dir          : in std_logic; -- 0 for fifo2slave, 1 for slave2fifo 
        busy         : out std_logic := '0';
        done         : out std_logic := '0';
        timed_out    : out std_logic := '0';
        transfer_len : in  std_logic_vector(15 downto 0);  --how many bytes to transfer on go (0 for 1 byte)
        start_addr   : in  std_logic_vector(31 downto 0); --starting address of the transaction
        --fifo2slave -------------------------------------
        f2s_fifo_en     : out std_logic := '0';
        f2s_fifo_data   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        --slave2fifo -------------------------------------
        s2f_fifo_en     : out std_logic := '0';
        s2f_fifo_data   : out std_logic_vector(DATA_WIDTH-1 downto 0);
        --axi --------------------------------------------
        axi4_m2s_o : out axi4_m2s := axi4_m2s_init;
        axi4_s2m_i : in  axi4_s2m := axi4_s2m_init;
        axi4_wdata : out std_logic_vector(DATA_WIDTH-1 downto 0);
        axi4_rdata : in  std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end axi_datamover;

architecture arch of axi_datamover is 
    --How many bytes are in a data beat
    constant BEAT_BYTE_SIZE      : integer := DATA_WIDTH/8;
    constant BEAT_BYTE_SIZE_LOG2 : integer := integer(ceil(log2(real(BEAT_BYTE_SIZE))));
    --How many bytes are in a burst
    constant BURST_BYTE_SIZE      : integer := MAX_BURST*BEAT_BYTE_SIZE;
    constant BURST_BYTE_SIZE_LOG2 : integer := integer(ceil(log2(real(BURST_BYTE_SIZE))));
    --Log2 of the maximum burst length
    constant BURST_SIZE_LOG2      : integer := integer(ceil(log2(real(MAX_BURST))));
    --A mask for for calculating the number of remainder bursts
    constant BEAT_CALC_MASK : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(MAX_BURST-1,16));
    --Address that sits right on the 4kB boundary for comparisons
    constant BOUNDARY_ADDR : std_logic_vector(12 downto 0) := (12 => '1', others => '0');
    --Calculations for determining remainders and full bursts
    signal num_beats_to_transfer : integer := 0;
    signal num_full_bursts       : integer := 0;
    signal num_remainder_beats   : integer := 0;
    signal num_beats             : integer := 0;
    --Burst and beat cnts for transfer loop
    signal burst_cnt             : integer := 0;
    signal beat_cnt              : integer := 0;
    --Enable Signals for SM
    signal final_burst       : std_logic := '0';
    signal boundary_burst    : std_logic := '0';
    signal boundary_beat_cnt : integer := 0;
    --Address and beat signals for determining boundary lines
    signal addr_bytes_to_4kB : std_logic_vector(12 downto 0) := (others => '0');
    signal beats_to_4kB      : integer := 0;
    --address signals for axi transactions
    signal addr             : std_logic_vector(31 downto 0) := (others => '0');
    signal transfer_len_reg : std_logic_vector(16 downto 0) := (others => '0');
    signal dir_reg          : std_logic := '0';
    signal active_burst_len : std_logic_vector(7 downto 0) := (others => '0');
    --state machines
    type state_t is (RESET, IDLE, TIMEOUT, BURST_LOAD, BOUNDARY_CHECK,
                     WRITE_SETUP, WRITE_LOOP, WRITE_DONE, 
                     READ_SETUP,  READ_LOOP,  READ_DONE,
                     FLUSH
                    );
    signal state : state_t := IDLE;
    --bit for delay within sm
    signal state_dly   : std_logic := '0';
    signal go_dly      : std_logic := '0';
    signal done_dly    : std_logic := '0';
    signal timeout_dly : std_logic := '0';
    --timeouts for axi transactions
    signal timeout_cnt : integer range 0 to TIMEOUT_CLOCKS-1 := 0;
    --AXI Constants 
    constant AXI_CACHE : std_logic_vector(3 downto 0) := "0011";
    constant AXI_PROT  : std_logic_vector(2 downto 0) := "010";
    --AXI signals
    signal awlen   : std_logic_vector( 7 downto 0) := (others => '0');
    signal awaddr  : std_logic_vector(31 downto 0) := (others => '0');
    signal awvalid : std_logic := '0';
    signal awready : std_logic := '0';
    signal arlen   : std_logic_vector( 7 downto 0) := (others => '0');
    signal araddr  : std_logic_vector(31 downto 0) := (others => '0');
    signal arvalid : std_logic := '0';
    signal arready : std_logic := '0';
    signal wvalid : std_logic := '0';
    signal wlast  : std_logic := '0';
    signal wready : std_logic := '0';
    signal wdata  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal bvalid : std_logic := '0';
    signal bready : std_logic := '0';
    signal bresp  : std_logic_vector(1 downto 0) := (others => '0');
    signal rlast  : std_logic := '0';
    signal rvalid : std_logic := '0';
    signal rready : std_logic := '0';
    signal rresp  : std_logic_vector(1 downto 0) := (others => '0');
    signal rdata  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    --FIFO rd enable
    signal fifo_rd_en_gen : std_logic := '0';
    signal fifo_rd_en : std_logic := '0';
    
    signal rst_meta, rst_sync : std_logic := '0';
    
    signal flush_cnt : integer range 0 to 63 := 0;
    
begin
    
    --Number of beats to move
    --transfer_len_reg is the number of bytes to move (1 for 1 byte, max 65536)
    num_beats_to_transfer <= to_integer(((unsigned(transfer_len_reg))+1) srl BEAT_BYTE_SIZE_LOG2);

    --Number for how many full beats we have to run
    num_full_bursts <= to_integer(to_unsigned(num_beats_to_transfer,17) srl BURST_SIZE_LOG2);

    --Beat size of the remainder burst
    --(0 for no remainder, 1 for 1 remainder beat, etc...)
    num_remainder_beats <= num_beats_to_transfer - to_integer(to_unsigned(num_full_bursts,16) sll BURST_SIZE_LOG2);
    

    --Calculate how many bytes we have to transfer to hit the 4kB boundary
    addr_bytes_to_4kB <= std_logic_vector(unsigned(BOUNDARY_ADDR)-unsigned('0' & addr(11 downto 0)));
    --Convert the number of bytes into number of beats to hit the 4kB boundary
    beats_to_4kB      <= to_integer(unsigned(addr_bytes_to_4kB) srl BEAT_BYTE_SIZE_LOG2);
    

    
    --AXI AW Signals to Port
    axi4_m2s_o.awcache <= AXI_CACHE;
    axi4_m2s_o.awprot  <= AXI_PROT;
    axi4_m2s_o.awid    <= (others => '0');
    axi4_m2s_o.awlock  <= (others => '0');
    axi4_m2s_o.awburst <= "01"; --INC
    axi4_m2s_o.awsize  <= std_logic_vector(to_unsigned(BEAT_BYTE_SIZE_LOG2,3));
    axi4_m2s_o.awlen   <= std_logic_vector(unsigned(active_burst_len));
    axi4_m2s_o.awaddr  <= awaddr;
    axi4_m2s_o.awvalid <= awvalid;
    awready            <= axi4_s2m_i.awready;
    
    --AXI W Signals to Port
    axi4_m2s_o.wlast  <= wlast;
    axi4_m2s_o.wvalid <= wvalid;
    axi4_m2s_o.wid    <= (others => '0');
    wready            <= axi4_s2m_i.wready;
    axi4_wdata        <= wdata;
    
    --AXI B Signals to Port
    axi4_m2s_o.bready <= bready;
    bvalid            <= axi4_s2m_i.bvalid;
    bresp             <= axi4_s2m_i.bresp;
    
    --AXI AR Signals to Port
    axi4_m2s_o.arcache <= AXI_CACHE;
    axi4_m2s_o.arprot  <= AXI_PROT;
    axi4_m2s_o.arid    <= (others => '0');
    axi4_m2s_o.arlock  <= (others => '0');
    axi4_m2s_o.arburst <= "01"; --INC
    axi4_m2s_o.arsize  <= std_logic_vector(to_unsigned(BEAT_BYTE_SIZE_LOG2,3));
    axi4_m2s_o.arlen   <= std_logic_vector(unsigned(active_burst_len));
    axi4_m2s_o.araddr  <= araddr;
    axi4_m2s_o.arvalid <= arvalid;
    arready            <= axi4_s2m_i.arready;

    --AXI R Signals to Port
    axi4_m2s_o.rready <= rready;
    rvalid            <= axi4_s2m_i.rvalid;
    rresp             <= axi4_s2m_i.rresp;
    rlast             <= axi4_s2m_i.rlast;
    rdata             <= axi4_rdata;

    --Other AXI assignments from state machine
    awaddr <= addr;
    araddr <= addr;
    awlen  <= std_logic_vector(unsigned(active_burst_len));
    arlen  <= std_logic_vector(unsigned(active_burst_len));
    
    --FIFO assignments
    s2f_fifo_en   <= rready and rvalid;
    s2f_fifo_data <= rdata;
    wdata         <= f2s_fifo_data;
    fifo_rd_en_gen <= (wready and wvalid) when beat_cnt /= 1 else '0';
    f2s_fifo_en   <= fifo_rd_en_gen or fifo_rd_en;
    
    ----------------------------------------------------------------------
    -- State Machines for both directions of dataflow                    *
    ----------------------------------------------------------------------
    -- Only handles one direction at a time                              *
    -- No complicated queuing done, just monitor busy/done bits          *
    -- Does not use strb, id, cache, prot, lock (basic AXI only)         *
    ----------------------------------------------------------------------
    process(clk)
    begin
        if(rising_edge(clk)) then

            rst_meta <= rst;
            rst_sync <= rst_meta;

            --Delay
            go_dly <= go;
            done <= '0';
            timed_out <= '0';
            
            --Default to zero for SM
            state_dly   <= '0';
            arvalid     <= '0';
            rready      <= '0';
            done_dly    <= '0';
            timeout_dly <= '0';
            awvalid     <= '0';
            fifo_rd_en  <= '0';
            bready      <= '0';
            
            if(state = IDLE) then
                busy <= '0';
            else 
                busy <= '1';
            end if;

            --State Machine
            case state is
            when RESET =>
                wvalid <= '0';
                
                if(rst_sync = '0') then
                    flush_cnt <= 0;
                    --state <= FLUSH;
                    state <= IDLE; --not a bug, just trying to see if cold reset fixes HPS
                end if;
                
            --when FLUSH =>
            --    
            --    --Cyclone 5 Hack? 
            --    --HPS SDRAM controller is being funky after reset
            --    rready <= '1';
            --    wvalid <= '1';
            --    wlast  <= '1';
            --    bready <= '1';
            --    if(flush_cnt = 63) then
            --        flush_cnt <= 0;
            --        state <= IDLE;
            --        rready <= '0';
            --        wvalid <= '0';
            --        wlast  <= '0';
            --        bready <= '0';
            --    else
            --        flush_cnt <= flush_cnt+1;
            --    end if;
               
            when IDLE =>
                --Idle state
                if(go_dly = '0' and go = '1') then
                    --latch in request parameters
                    addr             <= start_addr;
                    transfer_len_reg <= '0' & transfer_len;
                    
                    dir_reg          <= dir;
                    state_dly        <= '1';
                end if;
                
                if(state_dly = '1') then
                    --transaction loop is starting
                    
                    burst_cnt <= num_full_bursts;
                    beat_cnt  <= MAX_BURST;
                    
                    state <= BURST_LOAD;
                end if;

            when BURST_LOAD =>
                
                final_burst <= '0';
                
                if(burst_cnt /= 0) then
                    beat_cnt  <= MAX_BURST;
                    burst_cnt <= burst_cnt - 1;
                    if(burst_cnt = 1 and num_remainder_beats = 0) then
                        final_burst <= '1';
                    end if;
                elsif(burst_cnt = 0 and num_remainder_beats /= 0) then
                    beat_cnt <= num_remainder_beats;
                    final_burst <= '1';
                end if;
       
                state <= BOUNDARY_CHECK;
                
            when BOUNDARY_CHECK =>
            
                boundary_burst <= '0';
                if(beats_to_4kB < beat_cnt) then
                    boundary_burst    <= '1';
                    beat_cnt          <= beats_to_4kB;
                    boundary_beat_cnt <= beat_cnt - beats_to_4kB;
                end if;
                
                if(dir_reg = '0') then
                    state <= WRITE_SETUP;
                else
                    state <= READ_SETUP;
                end if;
                
            when READ_SETUP =>
                --Read Setup State
                --Setup the burst on the AXI bus
                active_burst_len <= std_logic_vector(to_unsigned(beat_cnt-1,8));
                arvalid <= '1';
                state_dly <= '1';
                if(state_dly = '1' and arready = '1') then
                    state <= READ_LOOP;
                    rready <= '1';
                    timeout_cnt <= 0;
                    arvalid <= '0';
                elsif(state_dly = '1' and arready = '0') then
                    timeout_cnt <= timeout_cnt + 1;
                end if;
            when READ_LOOP =>
                --Wait for valid data on the axi bus
                rready <= '1';
                if(rvalid = '1') then
                    addr <= std_logic_vector(unsigned(addr) + to_unsigned(BEAT_BYTE_SIZE,32));
                    timeout_cnt <= 0;
                    if(rlast = '1') then
                        state <= READ_DONE;
                        rready <= '0';
                        timeout_cnt <= 0;
                    end if;
                else
                    timeout_cnt <= timeout_cnt + 1;
                end if;
            when READ_DONE => 
            
                if(final_burst = '1' and boundary_burst = '0') then
                    done <= '1';
                    busy <= '0';
                    final_burst <= '0';
                    state <= IDLE;         
                elsif(final_burst = '0' and boundary_burst = '0') then
                    state <= BURST_LOAD;
                elsif(boundary_burst = '1') then
                    boundary_burst <= '0';
                    beat_cnt <= boundary_beat_cnt;
                    state <= READ_SETUP;           
                end if;

            when WRITE_SETUP =>
                active_burst_len <= std_logic_vector(to_unsigned(beat_cnt-1,8));
                awvalid <= '1';
                state_dly <= '1';
                if(state_dly = '1' and awready = '1') then
                    state <= WRITE_LOOP;
                    timeout_cnt <= 0;
                    --setup the fifo read
                    fifo_rd_en <= '1';
                    if(beat_cnt = 1) then
                        wlast <= '1';
                    end if;
                    awvalid <= '0';
                elsif(state_dly = '1' and awready = '0') then
                    timeout_cnt <= timeout_cnt + 1;
                end if;

            when WRITE_LOOP =>
                if(wready = '1' and wvalid = '1') then
                    --transfer has occurred
                    timeout_cnt <= 0;
                    wvalid   <= '0';
                    beat_cnt <= beat_cnt - 1;
                    addr <= std_logic_vector(unsigned(addr) + to_unsigned(BEAT_BYTE_SIZE,32));
                    if(beat_cnt = 1) then
                        state <= WRITE_DONE;
                        bready <= '1';
                        timeout_cnt <= 0;
                        wvalid      <= '0';
                        wlast       <= '0';

                    elsif(beat_cnt = 2) then
                        wlast <= '1';
                    end if;
                else
                    timeout_cnt <= timeout_cnt + 1;
                end if;
                if(fifo_rd_en = '1' or fifo_rd_en_gen = '1') then
                    wvalid <= '1';
                end if;

            when WRITE_DONE =>
                bready <= '1';
                if(bvalid = '1') then
                    if(final_burst = '1' and boundary_burst = '0') then
                        done <= '1';
                        busy <= '0';
                        final_burst <= '0';
                        state <= IDLE;         
                    elsif(final_burst = '0' and boundary_burst = '0') then
                        state <= BURST_LOAD;
                    elsif(boundary_burst = '1') then
                        boundary_burst <= '0';
                        beat_cnt <= boundary_beat_cnt;
                        state <= WRITE_SETUP;           
                    end if;
                end if;

            when TIMEOUT =>
                timed_out <= '1';
                done    <= '1';
                busy    <= '0';
                state <= IDLE;
            when others => end case;
            
            if(timeout_cnt = TIMEOUT_CLOCKS-1) then
                state <= TIMEOUT;
            end if;

        end if;
    end process;


end arch;