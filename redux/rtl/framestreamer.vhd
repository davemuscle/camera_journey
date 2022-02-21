library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
	
use work.axi_pkg.all;
    
entity framestreamer is
	generic(
        PIXEL_WIDTH  : integer := 32;
		DATA_WIDTH   : integer := 256;
        XFER_TIMEOUT : integer := 1000;
        MAX_BURST    : integer := 8
	);
	port(

        --software / user control. pixel clock domain
        h_active      : in std_logic_vector(11 downto 0); --pclk domain
        v_active      : in std_logic_vector(11 downto 0); --pclk domain
        h_total       : in std_logic_vector(11 downto 0); --pclk domain
        v_total       : in std_logic_vector(11 downto 0); --pclk domain
        frame_offsets : in std_logic_vector(95 downto 0); --aclk domain
        frame_active  : in std_logic_vector( 2 downto 0); --aclk domain
        output_enable : in std_logic;                     --pclk domain
        
        --status
        fifo_ov        : out std_logic := '0';
        fifo_un        : out std_logic := '0';
        datamove_error : out std_logic := '0';
        
		--output stream side
		pclk          : in  std_logic;
        preset        : in  std_logic;
		pixel_out     : out std_logic_vector(PIXEL_WIDTH-1 downto 0) := (others => '0');
		pixel_out_sof : out std_logic := '0';
		pixel_out_eol : out std_logic := '0';
		pixel_out_vld : out std_logic := '0';
	
        --axi master to read framebuffer memory
        aclk       : in  std_logic;
        areset     : in  std_logic;
        axi4_m2s_o : out axi4_m2s := axi4_m2s_init;
        axi4_s2m_i : in  axi4_s2m := axi4_s2m_init;
        axi4_wdata : out std_logic_vector(DATA_WIDTH-1 downto 0);
        axi4_rdata : in  std_logic_vector(DATA_WIDTH-1 downto 0)
  
	);
end framestreamer;

architecture str of framestreamer is 

	constant FIFO_SIZE  : integer := 2*4096/(DATA_WIDTH/PIXEL_WIDTH);
    constant PACK_RATIO : integer := DATA_WIDTH/PIXEL_WIDTH;
    constant BYTES_PER_PIXEL : integer := PIXEL_WIDTH/8;
    constant BYTES_PER_PIXEL_SHIFT : integer := integer(ceil(log2(real(BYTES_PER_PIXEL))));
    signal frame_offset_0 : std_logic_vector(31 downto 0) := (others => '0');
    signal frame_offset_1 : std_logic_vector(31 downto 0) := (others => '0');
    signal frame_offset_2 : std_logic_vector(31 downto 0) := (others => '0');
    signal frame_step     : std_logic_vector(31 downto 0) := (others => '0'); --number of bytes per line

    signal hcnt : unsigned(11 downto 0) := (others => '0');
    signal vcnt : unsigned(11 downto 0) := (others => '0');
 
    signal fifo_wr_en   : std_logic := '0';
    signal fifo_wr_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal fifo_rd_en   : std_logic := '0';
    signal fifo_rd_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    
    signal datamove_go           : std_logic := '0';
    signal datamove_dir          : std_logic := '0';
    signal datamove_busy         : std_logic := '0';
    signal datamove_done         : std_logic := '0';
    signal datamove_timed_out    : std_logic := '0';
    signal datamove_transfer_len : std_logic_vector(15 downto 0) := (others => '0');
    signal datamove_addr         : std_logic_vector(31 downto 0) := (others => '0');
    
    signal datamove_request          : std_logic := '0';
    signal datamove_request_sync     : std_logic := '0';
    signal datamove_request_sof      : std_logic := '0';
    signal datamove_request_sync_sof : std_logic := '0';   
    
    signal async_reset : std_logic := '0';
    
    signal ov, un : std_logic := '0';
    signal ov_s,un_s : std_logic := '0';
    signal data_error : std_logic := '0';
    
    signal line_read_pulse     : std_logic := '0';
    signal line_read_pulse_sof : std_logic := '0';
    signal line_read_reg   : std_logic := '0';
    signal line_read_sof   : std_logic := '0';
    signal pcnt : unsigned(11 downto 0) := (others => '0');
    signal packnum : unsigned(11 downto 0) := (others => '0');
    signal fifo_rd_en_dly : std_logic := '0';
    signal fifo_rd_en_dly_lvl : std_logic := '0';
    signal fifo_rd_en_dly_dly : std_logic := '0';
    
    type pixel_buffer_t is array(0 to PACK_RATIO-1) of std_logic_vector(PIXEL_WIDTH-1 downto 0);
    signal pixel_buffer : pixel_buffer_t := (others => (others => '0'));
    
    signal h_active_32 : unsigned(31 downto 0) := (others => '0');
    
begin    

    --Video Timing
    process(pclk)
    begin
        if(rising_edge(pclk)) then
            --standard VGA counting
            if(output_enable = '1') then
                if(hcnt = unsigned(h_total)-1) then
                    hcnt <= (others => '0');
                    if(vcnt = unsigned(v_total)-1) then
                        vcnt <= (others => '0');
                    else
                        vcnt <= vcnt + 1;
                    end if;
                else
                    hcnt <= hcnt + 1;
                end if;
            else
                hcnt <= (others => '0');
                vcnt <= (others => '0');
            end if;
        end if;
    end process;
    
    --Number of bytes in a line
    h_active_32 <= x"00000" & unsigned(h_active);
    frame_step <= std_logic_vector(h_active_32 sll BYTES_PER_PIXEL_SHIFT);
    --Starting addresses of each frame for the triple bufferer
    frame_offset_0 <= frame_offsets(31 downto  0);
    frame_offset_1 <= frame_offsets(63 downto 32);
    frame_offset_2 <= frame_offsets(95 downto 64);
    
    --Controls for requesting datamove and line reading
    process(pclk)
    begin
        if(rising_edge(pclk)) then
            datamove_request     <= '0';
            datamove_request_sof <= '0';
            line_read_pulse      <= '0';
            line_read_pulse_sof  <= '0';
            if(output_enable = '1') then
                if(hcnt = x"000" and vcnt < unsigned(v_active)) then
                    --request datemove
                    datamove_request <= '1';
                    if(vcnt = x"000") then
                        datamove_request     <= '0';
                        datamove_request_sof <= '1';
                    end if;
                end if;
                if(hcnt = unsigned(h_total)-1 and vcnt < unsigned(v_active)) then
                    line_read_pulse <= '1';
                    if(vcnt = x"000") then
                        --setting both pulses at the same time since they're on the same clock domain
                        line_read_pulse_sof <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    --CDC for pulse
    pulse_sync_inst1 : entity work.pulse_sync_handshake
    port map(
        clk_a   => pclk,
        pulse_a => datamove_request,
        busy_a  => open,
        clk_b   => aclk,
        pulse_b => datamove_request_sync
    );
    pulse_sync_inst2 : entity work.pulse_sync_handshake
    port map(
        clk_a   => pclk,
        pulse_a => datamove_request_sof,
        busy_a  => open,
        clk_b   => aclk,
        pulse_b => datamove_request_sync_sof
    );
    
    --Driver for AXI Datamover
    datamove_transfer_len <= std_logic_vector(unsigned(frame_step(15 downto 0))-1);
    process(aclk)
    begin
        if(rising_edge(aclk)) then
            datamove_go <= datamove_request_sync or datamove_request_sync_sof;
            if(datamove_request_sync = '1') then
                --increment the address by the number of bytes in a line
                --the assumes the lines are packed within the framebuffer memory
                datamove_addr <= std_logic_vector(unsigned(datamove_addr)+unsigned(frame_step));
            end if;
            if(datamove_request_sync_sof = '1') then
                --set the address to the start of the active buffer
                case frame_active is
                when "010"   => datamove_addr <= frame_offset_1;
                when "100"   => datamove_addr <= frame_offset_2;
                when others  => datamove_addr <= frame_offset_0;
                end case;
            end if;
            data_error <= '0';
            if(datamove_go = '1' and datamove_busy = '1') then
                data_error <= '1';
            end if;
        end if;
    end process;
    
    --Datamover instantiation. AXI memory to FIFO
    datamover_inst : entity work.axi_datamover
	generic map(
		DATA_WIDTH     => DATA_WIDTH,
        MAX_BURST      => MAX_BURST,
        TIMEOUT_CLOCKS => XFER_TIMEOUT
	)
	port map(
        --clocks and reset -------------------------------
		clk => aclk,
        rst => areset,
        --control and status
        go           => datamove_go          ,
        dir          => '1'                  ,
        busy         => datamove_busy        ,
        done         => datamove_done        ,
        timed_out    => datamove_timed_out   ,
        transfer_len => datamove_transfer_len,
        start_addr   => datamove_addr        ,   
        --fifo2slave -------------------------------------
        f2s_fifo_en     => open,
        f2s_fifo_data   => (others => '0'),
        --slave2fifo -------------------------------------
        s2f_fifo_en     => fifo_wr_en,
        s2f_fifo_data   => fifo_wr_data,
        --axi --------------------------------------------
        axi4_m2s_o => axi4_m2s_o,
        axi4_s2m_i => axi4_s2m_i,
        axi4_wdata => axi4_wdata,
        axi4_rdata => axi4_rdata
	);
    
    async_reset <= preset or areset;
    
    --Async FIFO to hold downstream packed pixels
	downstream_fifo_inst : entity work.async_fifo
	generic map(
		gDEPTH => FIFO_SIZE, 
		gWIDTH => DATA_WIDTH, 
		gOREGS => 0
	)
	port map(
		wr_clk  => aclk, 
		wr_en   => fifo_wr_en,
		wr_data => fifo_wr_data,
		rd_clk  => pclk,
		rd_en   => fifo_rd_en,
		rd_data => fifo_rd_data,
		reset   => async_reset,
		ff      => open,
		fe      => open,
		ov      => ov,
		un      => un
	);
    
    assert(ov = '0')report "Framestreamer FIFO Overflow"  severity failure;
    assert(un = '0')report "Framestreamer FIFO Underflow" severity failure;
    process(pclk)
    begin
        if(rising_edge(pclk)) then
            if(ov = '1') then
                ov_s <= '1';
            end if;
            if(un = '1') then
                un_s <= '1';
            end if;
            if(data_error ='1') then
                datamove_error <= '1';
            end if;
            if(async_reset = '1') then
                ov_s <= '0';
                un_s <= '0';
                datamove_error <= '0';
            end if;
        end if;
    end process;
    --Line reading and pixel unpacking
    process(pclk)
    begin
        if(rising_edge(pclk)) then
            if(line_read_pulse = '1') then
                --set level and reload counter
                line_read_reg <= '1';
                pcnt <= (others => '0');
                packnum <= (others => '0');
            end if;
            if(line_read_pulse_sof = '1') then
                --extra signal for generating metadata
                line_read_sof <= '1';
            end if;
            
            --read from FIFO
            fifo_rd_en <= '0';
            fifo_rd_en_dly <= fifo_rd_en;
            fifo_rd_en_dly_dly <= fifo_rd_en_dly;
            
            if(line_read_reg = '1') then
                packnum <= packnum + 1;
            end if;
            
            if(line_read_reg = '1' and packnum = x"000" and pcnt < unsigned(h_active)-to_unsigned(PACK_RATIO,12)) then
                fifo_rd_en <= '1';
            end if;
            
            if(line_read_reg = '1' and packnum = to_unsigned(PACK_RATIO-1,12)) then
                packnum <= (others => '0');
            end if;

            for i in 0 to PACK_RATIO-2 loop
                pixel_buffer(i) <= pixel_buffer(i+1);
            end loop;
            
            pixel_out <= pixel_buffer(0);

            if(fifo_rd_en_dly = '1') then
                for i in 0 to PACK_RATIO-1 loop
                    pixel_buffer(i) <= fifo_rd_data(PIXEL_WIDTH*(i+1)-1 downto PIXEL_WIDTH*i);
                end loop;
            end if;
            
            pixel_out_sof <= '0';
            pixel_out_eol <= '0';
            
            if(fifo_rd_en_dly = '1') then
                fifo_rd_en_dly_lvl <= '1';
            end if;
            
            if(fifo_rd_en_dly_lvl = '1') then
                pcnt <= pcnt + 1;
                if(pcnt = unsigned(h_active)-1) then
                    pixel_out_eol <= '1';
                end if;
                if(pcnt = unsigned(h_active)) then
                    pixel_out_eol <= '0';
                    pixel_out_sof <= '0';
                    pixel_out_vld <= '0';
                    line_read_reg <= '0';
                    fifo_rd_en <= '0';
                    fifo_rd_en_dly <= '0';
                    fifo_rd_en_dly_dly <= '0';
                    fifo_rd_en_dly_lvl <= '0';
                end if;
            end if;
            
            if(fifo_rd_en_dly_dly = '1') then
                pixel_out_vld <= '1';

                if(line_read_sof = '1') then
                    pixel_out_sof <= '1';
                    line_read_sof <= '0';
                end if;

            end if;
            
        end if;
    end process;

    
end str;