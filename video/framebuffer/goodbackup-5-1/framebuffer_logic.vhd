library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
	
entity framebuffer_logic is
	generic(
        PIXEL_WIDTH : integer := 8;
		DATA_WIDTH  : integer := 128;
		h_active    : integer := 1920;
		v_active    : integer := 1080;
		h_blank     : integer := 280;
		v_blank     : integer := 45
	);
	port(

		--input stream side (upstream)
		upstream_clk   : in  std_logic;
		pixel_in        : in  std_logic_vector(PIXEL_WIDTH-1 downto 0);
		pixel_in_valid  : in  std_logic;
		pixel_in_sof    : in  std_logic;
		pixel_in_eol    : in  std_logic;
		
		--output stream side (downstream)
		downstream_clk  : in  std_logic;
		pixel_out        : out std_logic_vector(PIXEL_WIDTH-1 downto 0) := (others => '0');
		pixel_out_valid  : out std_logic := '0';
		pixel_out_sof    : out std_logic := '0';
		pixel_out_eol    : out std_logic := '0';
		
        --memory side
		mem_clk         : in  std_logic;
        --memory upstream transfer control signals
        mem_uline_loaded     : out std_logic := '0';
        mem_uline_loaded_sof : out std_logic := '0';
        --upstream fifo to memory
        mem_ufifo_rd_en   : in  std_logic;
        mem_ufifo_rd_data : out std_logic_vector(DATA_WIDTH-1 downto 0);
        --memory downstream transfer control signals
        mem_dvideo_en        : in  std_logic;
        mem_dreq_line        : out std_logic;
        mem_dreq_line_sof    : out std_logic;
        --memory to downstream fifo
        mem_dfifo_wr_en   : in std_logic;
        mem_dfifo_wr_data : in std_logic_vector(DATA_WIDTH-1 downto 0);
        
        reset             : in std_logic;
        --FIFO Status
        ufifo_ov_sticky   : out std_logic := '0';
        ufifo_un_sticky   : out std_logic := '0';
        dfifo_ov_sticky   : out std_logic := '0';
        dfifo_un_sticky   : out std_logic := '0'
	);
end framebuffer_logic;

architecture arch of framebuffer_logic is 

	--Constants
    constant PACK_RATIO : integer := DATA_WIDTH/PIXEL_WIDTH;
    constant PACK_RATIO_LOG2 : integer := integer(ceil(log2(real(PACK_RATIO))));
	constant FIFO_SIZE : integer := 4*h_active/PACK_RATIO;
    --Upstream Signals
    signal unum_pixels_in_line           : integer range 0 to 4095 := 0;
    signal usync                         : std_logic := '0';
    signal usync_snoop_en                : std_logic := '0';
    signal usync_line_ready              : std_logic := '0';
    signal unum_lines_in_buffer          : integer range 0 to 4095 := 0;
    signal upixel_in_valid_dly            : std_logic := '0';
    signal upixel_in_dly                  : std_logic_vector(PIXEL_WIDTH-1 downto 0) := (others => '0');
    type   pixel_array_t is array(0 to PACK_RATIO-1) of std_logic_vector(PIXEL_WIDTH-1 downto 0);
    signal upixel_array : pixel_array_t := (others => (others => '0'));
    signal uline_loaded                  : std_logic := '0';
    signal ufirst_line                   : std_logic := '0';
    signal uline_loaded_sof              : std_logic := '0';
    signal upack_cnt                     : integer range 0 to PACK_RATIO-1 := 0;
    signal upack_done                    : std_logic := '0';
    --Upstream Debug Registers
    --signal ufifo_ov_sticky : std_logic := '0';
    --signal ufifo_un_sticky : std_logic := '0';
    --Upstream FIFO Signals
    signal ufifo_wr_en   : std_logic := '0';
    signal ufifo_wr_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal ufifo_ov      : std_logic := '0';
    signal ufifo_un      : std_logic := '0';
    signal ufifo_rd_en   : std_logic := '0';
    signal ufifo_rd_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    --Downstream Video Setup Signals
    signal dvideo_hcnt     : integer range 0 to 4095 := 0;
    signal dvideo_vcnt     : integer range 0 to 4095 := 0;
    signal dvideo_vcnt_pre : integer range 0 to 4095 := 4095;
    signal dreq_line     : std_logic := '0';
    signal dreq_line_sof : std_logic := '0';
    signal dfirst_line : std_logic := '0';
    signal dline_read_en : std_logic := '0';
    signal dline_read_en_dly : std_logic := '0';
    signal dline_loaded : std_logic := '0';
    signal dline_loaded_sof : std_logic := '0';
    signal mem_dvideo_en_meta : std_logic := '0';
    signal mem_dvideo_en_sync : std_logic := '0';
    signal dnum_pixels_in_line : integer range 0 to 4095 := 0;
    signal dpack_cnt : integer range 0 to PACK_RATIO-1 := 0;
    signal dvideo_req_en : std_logic := '0';
    --Downstream FIFO Signals
    signal dfifo_wr_en   : std_logic := '0';
    signal dfifo_wr_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal dfifo_ov      : std_logic := '0';
    signal dfifo_un      : std_logic := '0';
    signal dfifo_rd_en   : std_logic := '0';
    signal dfifo_rd_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal dsync : std_logic := '0';
    signal dfifo_rd_en_dly : std_logic := '0';
    signal dpixel_array : pixel_array_t := (others => (others => '0'));
    signal dvalid_pre : std_logic_vector(3 downto 0) := (others => '0');
    signal dlast_pixel_dly  : std_logic_vector(3 downto 0) := (others => '0');
    signal dfirst_pixel_dly : std_logic_vector(3 downto 0) := (others => '0');
    --Downstream Debug Registers
    --signal dfifo_ov_sticky : std_logic := '0';
    --signal dfifo_un_sticky : std_logic := '0';
    --Reset Signals
    signal ureset_meta, ureset_sync : std_logic := '0';
    signal ureset : std_logic;
    signal dreset_meta, dreset_sync : std_logic := '0';
    signal dreset : std_logic := '0';

begin    
    ----------------------------------------------------------------------
    -- Upstream FIFO Loading and Pixel Packing                           *
    ----------------------------------------------------------------------
    -- Pack input pixels of PIXEL_WIDTH into data vectors of DATA_WIDTH  *
    -- This will increase the throughput of the memory interface         *
    -- Write data into the FIFO                                          *
    -- Signal that a line has been loaded and is ready to be sent over   *
    -- Signal as well if it is the first line in the video frame         *
    ----------------------------------------------------------------------
    process(upstream_clk)
    begin
        if(rising_edge(upstream_clk)) then
            --Delay
            upixel_in_valid_dly <= pixel_in_valid;
            upixel_in_dly       <= pixel_in;
            --Pixel Packing
            upixel_array(0)     <= upixel_in_dly;
            upixel_array(1 to PACK_RATIO-1) <= upixel_array(0 to PACK_RATIO-2);
            --Pulse the line loaded signals
            uline_loaded     <= '0';
            uline_loaded_sof <= '0';
            --Mask only the lower bits of the count for the packing feature
            --This is written kind of in a funky way so that GHDL doesn't give me truncation warnings
            upack_cnt <= to_integer(to_unsigned(unum_pixels_in_line,12)(PACK_RATIO_LOG2-1 downto 0));
            --Pulse the pack done
            upack_done <= '0';
            if(usync_snoop_en = '1' and upack_cnt = PACK_RATIO-1) then
                --Set pack done when the count has reach PACK_RATIO-1
                upack_done <= '1';
            end if;
            --Latch the enable when we see a SOF
            if(pixel_in_sof = '1' and pixel_in_valid = '1') then
                usync_snoop_en      <= '1';
                unum_pixels_in_line <= unum_pixels_in_line + 1;
                ufirst_line         <= '1';
            end if;
            --Monitor pixel inputs
            if(pixel_in_valid = '1' and usync_snoop_en = '1') then
                --Increase the number of pixels we have received
                unum_pixels_in_line <= unum_pixels_in_line + 1;
                --If it's the end of a frame and we have the right number of pixels -> send to memory
                --if(pixel_in_eol = '1' and unum_pixels_in_line = h_active-1) then
                if(pixel_in_eol = '1') then
                    --Reset the count
                    unum_pixels_in_line <= 0;
                    --Signal whether this is the first line in a frame or not
                    if(ufirst_line = '1') then
                        uline_loaded_sof <= '1';
                    else
                        uline_loaded <= '1';
                    end if;
                    --Check how many lines we've loaded
                    if(unum_lines_in_buffer >= v_active-1) then
                        --If the right amount, just reset count
                        unum_lines_in_buffer <= 0;
                    else
                        --If not enough, increment count
                        unum_lines_in_buffer <= unum_lines_in_buffer + 1;
                    end if;
                end if;
                --Clear the ufirst_line signal when we receive an EOL
                if(pixel_in_eol = '1') then
                    ufirst_line <= '0';
                end if;
            end if;
            ureset_meta <= reset;
            ureset_sync <= ureset_meta;
            ureset      <= ureset_sync;
            --Upstream Reset
            if(ureset = '1') then
                usync_snoop_en       <= '0';
                unum_lines_in_buffer <= 0;
                unum_pixels_in_line  <= 0;
                ufirst_line          <= '0';
                upack_done           <= '0';
                upack_cnt            <= 0;
                uline_loaded         <= '0';
                uline_loaded_sof     <= '0';
                upixel_in_valid_dly  <= '0';
            end if;
        end if;
    end process;
    -------------------
    -- Upstream Debug *
    -------------------
    process(upstream_clk)
    begin
        if(rising_edge(upstream_clk)) then
            if(ufifo_ov = '1') then
                ufifo_ov_sticky <= '1';
            end if;
            if(ufifo_un = '1') then
                ufifo_un_sticky <= '1';
            end if;
            if(ureset = '1') then
                ufifo_ov_sticky <= '0';
                ufifo_un_sticky <= '0';
            end if;
        end if;
    end process;
    -----------------------------
    -- Upstream FIFO Write Side *
    -----------------------------
    process(upixel_array)
    begin
        --This better synthesize to a bunch of wires!
        for i in 0 to PACK_RATIO-1 loop
            ufifo_wr_data(((i+1)*PIXEL_WIDTH)-1 downto i*PIXEL_WIDTH) <= upixel_array(i);
        end loop;
    end process;
    ufifo_wr_en <= upack_done;
    ------------------
    -- Upstream FIFO *
    ------------------
	upstream_fifo_inst : entity work.async_fifo
	generic map(
		gDEPTH => FIFO_SIZE, 
		gWIDTH => DATA_WIDTH, 
		gOREGS => 0
	)
	port map(
		wr_clk  => upstream_clk, 
		wr_en   => ufifo_wr_en,
		wr_data => ufifo_wr_data,
		rd_clk  => mem_clk,
		rd_en   => ufifo_rd_en,
		rd_data => ufifo_rd_data,
		reset   => reset,
		ff      => open,
		fe      => open,
		ov      => ufifo_ov,
		un      => ufifo_un
	);
    ------------------------------------------------------------------------------
    -- Upstream FIFO Read Side, these go straight to the native memory interface *
    ------------------------------------------------------------------------------
    mem_ufifo_rd_data <= ufifo_rd_data;
    ufifo_rd_en       <= mem_ufifo_rd_en;
    --------------------------------------------
    -- Upstream to Memory CLK CDC              *
    --------------------------------------------
    -- Handshake based pulse synchronizer      *
    -- From edn.com -> synchronizer techniques * 
    --------------------------------------------
    pulse_sync_inst1 : entity work.pulse_sync_handshake
    port map(
        clk_a   => upstream_clk,
        pulse_a => uline_loaded,
        busy_a  => open,
        clk_b   => mem_clk,
        pulse_b => mem_uline_loaded
    );
    pulse_sync_inst2 : entity work.pulse_sync_handshake
    port map(
        clk_a   => upstream_clk,
        pulse_a => uline_loaded_sof,
        busy_a  => open,
        clk_b   => mem_clk,
        pulse_b => mem_uline_loaded_sof
    );
    --------------------------------------------------------------------------------------
    -- Downstream Video Timing                                                           *
    --------------------------------------------------------------------------------------
    -- Standard VGA timing                                                               *
    -- Creates pulses for requesting lines from the memory arbiter, as well as pulses    *
    -- for outputting the final video data.                                              *
    --------------------------------------------------------------------------------------
    process(downstream_clk)
    begin
        if(rising_edge(downstream_clk)) then
            --Dual flop sync
            mem_dvideo_en_meta <= mem_dvideo_en;
            mem_dvideo_en_sync <= mem_dvideo_en_meta;
            --Enable VGA Timing
            if(mem_dvideo_en_sync = '1') then
                if(dvideo_hcnt = h_active + h_blank - 1) then
                    dvideo_hcnt <= 0;
                    dvideo_vcnt_pre <= dvideo_vcnt;
                    if(dvideo_vcnt = v_active + v_blank - 1) then
                        dvideo_vcnt <= 0;
                    else
                        dvideo_vcnt <= dvideo_vcnt + 1;
                    end if;
                else
                    dvideo_hcnt <= dvideo_hcnt + 1;
                end if;
            else
                dvideo_hcnt <= 0;
                dvideo_vcnt <= 0;
                dvideo_vcnt_pre <= 4095;
            end if;
            --Request video lines from the memory interface with pulses
            dreq_line        <= '0';
            dreq_line_sof    <= '0';
            dline_loaded     <= '0';
            dline_loaded_sof <= '0';
            if(mem_dvideo_en_sync = '1') then
                if(dvideo_hcnt = 0 and dvideo_vcnt = 0) then
                    dreq_line_sof <= '1';
                elsif(dvideo_hcnt = 0 and dvideo_vcnt < v_active) then
                    dreq_line     <= '1';
                end if;
                --This creates a latency of one line, IE:
                --hcnt = 0, vcnt = 0 -> Read first line
                --hcnt = 0, vcnt = 1 -> Read second line, first line guaranteed to be in FIFO, provide pulse for SOF
                --hcnt = 0, vcnt = 2 -> Read third line, second line in FIFO, provide line pulse
                if(dvideo_hcnt = 0 and dvideo_vcnt_pre = 0) then
                    dline_loaded_sof <= '1';
                elsif(dvideo_hcnt = 0 and dvideo_vcnt_pre < v_active) then
                    dline_loaded <= '1';
                end if;
            end if;
            --Reset
            dreset_meta <= reset;
            dreset_sync <= dreset_meta;
            dreset      <= dreset_sync;
            if(dreset = '1') then
                dvideo_hcnt      <= 0;
                dvideo_vcnt      <= 0;
                dvideo_vcnt_pre  <= 4095;
                mem_dvideo_en_meta <= '0';
                mem_dvideo_en_sync <= '0';
                dreq_line        <= '0';
                dreq_line_sof    <= '0';
                dline_loaded     <= '0';
                dline_loaded_sof <= '0';
            end if;
        end if;
    end process;
    --------------------------------------------
    -- Downstream to Memory CLK CDC            *
    --------------------------------------------
    -- Handshake based pulse synchronizer      *
    -- From edn.com -> synchronizer techniques * 
    --------------------------------------------
    pulse_sync_inst3 : entity work.pulse_sync_handshake
    port map(
        clk_a   => downstream_clk,
        pulse_a => dreq_line,
        busy_a  => open,
        clk_b   => mem_clk,
        pulse_b => mem_dreq_line
    );
    pulse_sync_inst4 : entity work.pulse_sync_handshake
    port map(
        clk_a   => downstream_clk,
        pulse_a => dreq_line_sof,
        busy_a  => open,
        clk_b   => mem_clk,
        pulse_b => mem_dreq_line_sof
    );
    --------------------------------------------------------------------------------------
    -- Downstream Video Output                                                           *
    --------------------------------------------------------------------------------------
    -- After we receive a pulse from the memory interface telling us the line is loaded, *
    -- unpack and output the pixels.                                                     *
    --------------------------------------------------------------------------------------
    process(downstream_clk)
    begin
        if(rising_edge(downstream_clk)) then
            --When the line loaded pulse ticks, we enable reading the entire line
            if(dline_loaded = '1' or dline_loaded_sof = '1')then
                dline_read_en <= '1';
                dnum_pixels_in_line <= 0;
            end if;
            if(dline_loaded_sof = '1') then
                dfirst_line <= '1';
            end if;
            --Delay read enable
            dline_read_en_dly <= dline_read_en;
            --Increment pixel count
            if(dline_read_en = '1') then
                if(dnum_pixels_in_line = h_active-1) then
                    --Deassert dline_read_en at the end of the line
                    --Edge case for hblank = 0, just keep it asserted between lines
                    --Not handling the case where hblank = 0 and vblank /= 0 -> that is stupid
                    --You either include blanking, or you don't
                    if(h_blank /= 0 and v_blank /= 0) then
                        dline_read_en     <= '0';
                        dline_read_en_dly <= '0';
                    end if;
                    dnum_pixels_in_line <= 0;
                    dlast_pixel_dly(0) <= '1';
                elsif(dnum_pixels_in_line = 0 and dfirst_line = '1') then
                    dfirst_pixel_dly(0) <= '1';
                    dnum_pixels_in_line <= dnum_pixels_in_line + 1;
                    dfirst_line <= '0';
                else
                    dnum_pixels_in_line <= dnum_pixels_in_line + 1;
                end if;
            end if;
            
            --Mask only the lower bits of the count for the packing feature
            --This is written kind of in a funky way so that GHDL doesn't give me truncation warnings
            dpack_cnt <= to_integer(to_unsigned(dnum_pixels_in_line,12)(PACK_RATIO_LOG2-1 downto 0));
            
            dfifo_rd_en <= '0';
            if(dline_read_en_dly = '1' and dpack_cnt = 0) then
                --Read from FIFO
                dfifo_rd_en <= '1';
            end if;
            dfifo_rd_en_dly <= dfifo_rd_en;
            if(dfifo_rd_en_dly = '1') then
                for i in 0 to PACK_RATIO-1 loop
                    dpixel_array(i) <= dfifo_rd_data(((i+1)*PIXEL_WIDTH)-1 downto i*PIXEL_WIDTH);
                end loop;
            else
                dpixel_array(1 to PACK_RATIO-1) <= dpixel_array(0 to PACK_RATIO-2);
            end if;
            dvalid_pre(0) <= dline_read_en;
            dvalid_pre(3 downto 1) <= dvalid_pre(2 downto 0);
            pixel_out_valid <= dvalid_pre(3);
            --Shift out the pixels from the packed word
            pixel_out <= dpixel_array(PACK_RATIO-1);
            --SOF signal
            dfirst_pixel_dly(3 downto 1) <= dfirst_pixel_dly(2 downto 0);
            if(dvalid_pre(3) = '1' and dfirst_pixel_dly(3) = '1') then
                pixel_out_sof <= '1';
                dfirst_pixel_dly <= (others => '0');
            else
                pixel_out_sof <= '0';
            end if;
            --EOL signal
            dlast_pixel_dly(3 downto 1) <= dlast_pixel_dly(2 downto 0);
            if(dvalid_pre(3) = '1' and dlast_pixel_dly(3) = '1') then
                pixel_out_eol <= '1';
                dlast_pixel_dly <= (others => '0');
            else
                pixel_out_eol <= '0';
            end if;
            --Reset
            if(dreset = '1') then
                pixel_out_eol       <= '0';
                pixel_out_sof       <= '0';
                pixel_out_valid     <= '0';
                dpack_cnt           <= 0;
                dvalid_pre          <= (others => '0');
                dline_read_en       <= '0';
                dfirst_line         <= '0';
                dnum_pixels_in_line <= 0;
                dlast_pixel_dly     <= (others => '0');
                dline_read_en_dly   <= '0';
                dfifo_rd_en         <= '0';
                dfifo_rd_en_dly     <= '0';
                dfirst_pixel_dly    <= (others => '0');
            end if;
        end if;
    end process;
    --------------------
    -- Downstream FIFO *
    --------------------
    dfifo_wr_en   <= mem_dfifo_wr_en;
    dfifo_wr_data <= mem_dfifo_wr_data;
	downstream_fifo_inst : entity work.async_fifo
	generic map(
		gDEPTH => FIFO_SIZE, 
		gWIDTH => DATA_WIDTH, 
		gOREGS => 0
	)
	port map(
		wr_clk  => mem_clk, 
		wr_en   => dfifo_wr_en,
		wr_data => dfifo_wr_data,
		rd_clk  => downstream_clk,
		rd_en   => dfifo_rd_en,
		rd_data => dfifo_rd_data,
		reset   => reset,
		ff      => open,
		fe      => open,
		ov      => dfifo_ov,
		un      => dfifo_un
	);
    ---------------------
    -- Downstream Debug *
    ---------------------
    process(downstream_clk)
    begin
        if(rising_edge(downstream_clk)) then
            if(dfifo_ov = '1') then
                dfifo_ov_sticky <= '1';
            end if;
            if(dfifo_un = '1') then
                dfifo_un_sticky <= '1';
            end if;
            if(dreset = '1') then
                dfifo_ov_sticky <= '0';
                dfifo_un_sticky <= '0';
            end if;
        end if;
    end process;

    
end arch;