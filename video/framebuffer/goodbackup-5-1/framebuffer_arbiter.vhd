library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
	
--Manages and arbitrates moving lines of video data to the memory interface
--Works in a triple buffering fashion

--AXI addresses are in terms of bytes
    
entity framebuffer_arbiter is
	generic(
        PIXEL_WIDTH : integer := 8;
		DATA_WIDTH  : integer := 128;
		h_active    : integer := 1920;
        v_active    : integer := 1080

	);
	port(
        --clock and reset
		clk : in std_logic;
        rst : in std_logic;
        
        --user status
        read_time     : out std_logic_vector(11 downto 0) := (others => '0');
        write_time    : out std_logic_vector(11 downto 0) := (others => '0');
        request_error : out std_logic := '0';
        load_error    : out std_logic := '0';
        timeout_error : out std_logic := '0';
        
        --memory signals to framebuffer logic
        mem_uline_loaded      : in  std_logic;
        mem_uline_loaded_sof  : in  std_logic;
        mem_dvideo_en         : out std_logic := '0';
        mem_dreq_line         : in  std_logic;
        mem_dreq_line_sof     : in  std_logic;

        --optional addressing status signals
        first                 : out std_logic := '0';
        frame_num_read        : out integer range 0 to 3 := 0;
        
        --control signals to axi datamover
        datamove_go           : out std_logic := '0';
        datamove_dir          : out std_logic := '0';
        datamove_busy         : in  std_logic;
        datamove_done         : in  std_logic;
        datamove_timed_out    : in  std_logic;
        datamove_transfer_len : out std_logic_vector(15 downto 0) := (others => '0');
        datamove_addr         : out std_logic_vector(31 downto 0) := (others => '0')
	);
end framebuffer_arbiter;

architecture arch of framebuffer_arbiter is 

    --How many bytes are in a pixel
    constant PIXEL_BYTE_SIZE : integer := PIXEL_WIDTH/8;
    --How many bytes are in a line
    constant LINE_SIZE_BYTES : integer := h_active*PIXEL_BYTE_SIZE;
    --How many bytes are in exactly one frame
    constant FRAME_SIZE_BYTES : integer := h_active*v_active*PIXEL_BYTE_SIZE;
    --Rounding the frame size
    constant FRAME_SIZE_BYTES_LOG2 : integer := integer(ceil(log2(real(FRAME_SIZE_BYTES))));
    constant FRAME_SIZE_BYTES_NP2  : integer := 2**FRAME_SIZE_BYTES_LOG2;

    --triple buffering
    signal frame_num, frame_num_prev ,frame_num_locked : integer range 0 to 3 := 0;
    --framebuffer byte address boundaries
    constant FRAME0_START : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(0*FRAME_SIZE_BYTES_NP2,32));
    constant FRAME1_START : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(1*FRAME_SIZE_BYTES_NP2,32));
    constant FRAME2_START : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(2*FRAME_SIZE_BYTES_NP2,32));
    --address signals for axi transactions
    signal write_addr : std_logic_vector(31 downto 0) := (others => '0');
    signal read_addr  : std_logic_vector(31 downto 0) := (others => '0');
    --levels based off pulses from framebuffer logic
    signal write_first_line : std_logic := '0';
    signal write_a_line     : std_logic := '0';
    signal read_first_line  : std_logic := '0';
    signal read_a_line      : std_logic := '0';
    --delayed enable signals
    signal write_first_line_p : std_logic := '0';
    signal write_a_line_p     : std_logic := '0';
    signal read_first_line_p  : std_logic := '0';
    signal read_a_line_p      : std_logic := '0';

    --state machine
    type state_t is (RESET, IDLE,
                     SETUP_M2S, WAIT_M2S, DONE_M2S,
                     SETUP_S2M, WAIT_S2M, DONE_S2M
                    );
    signal state : state_t := IDLE;
    --enable downstream video
    signal vid_en : std_logic := '0';
    --bit for delay within sm
    signal state_dly : std_logic := '0';

    --counters for frame tracking
    signal write_line_count : integer range 0 to 4095 := 0;

    --error monitoring
    --main error I'm concerned with is not being able to read data fast enough
    signal timer_cnt         : std_logic_vector(11 downto 0) := (others => '0');
    constant ones            : std_logic_vector(11 downto 0) := (others => '1');

    signal mode : std_logic := '0'; --0 for normal, 1 for first
    signal write_mode : std_logic := '0'; --0 for normal, 1 for first
    signal write_mode_p : std_logic := '0'; --0 for normal, 1 for first
    signal read_mode  : std_logic := '0'; --0 for normal, 1 for first
    signal read_mode_p  : std_logic := '0'; --0 for normal, 1 for first
    
    signal read_a_line_clr     : std_logic := '0';
    signal read_first_line_clr : std_logic := '0';
    signal write_a_line_clr     : std_logic := '0';
    signal write_first_line_clr : std_logic := '0';
    
    signal rst_meta, rst_sync : std_logic := '0';
    
begin    
    
    --Constant
    datamove_transfer_len <= std_logic_vector(to_unsigned(LINE_SIZE_BYTES,16));

    --Downstream video enable
    mem_dvideo_en <= vid_en;
    
    frame_num_read <= frame_num_locked;
    
    ----------------------------------------------------------------------
    -- Arbiter Logic and State Machine                                   *
    ----------------------------------------------------------------------
    -- Take in pulses from the FIFO logic, convert them to levels        *
    -- Use them in the state machine to arbitrate writing and reading    *
    -- lines of video to the memory interface over the AXI bus.          *
    ----------------------------------------------------------------------
    process(clk)
    begin
        if(rising_edge(clk)) then
        
            rst_meta <= rst;
            rst_sync <= rst_meta;
        
            if(write_a_line = '0' and write_a_line_p = '1') then
                write_a_line   <= '1';
                write_mode     <= write_mode_p;
                write_a_line_p <= '0';
            end if;
            if(write_a_line_clr = '1') then
                if(write_a_line_p = '1') then
                    write_a_line <= '1';
                    write_mode <= write_mode_p;
                    write_a_line_p <= '0';
                else
                    write_a_line <= '0';
                end if;
            end if;
            if(mem_uline_loaded = '1' or mem_uline_loaded_sof = '1') then
                write_a_line_p <= '1';
                if(write_a_line_p = '1') then
                    load_error <= '1';
                end if;
            end if;
            if(mem_uline_loaded = '1') then
                write_mode_p <= '0';
            end if;
            if(mem_uline_loaded_sof = '1') then
                write_mode_p <= '1';
            end if;

            if(read_a_line = '0' and read_a_line_p = '1') then
                read_a_line   <= '1';
                read_mode     <= read_mode_p;
                read_a_line_p <= '0';
            end if;
            if(read_a_line_clr = '1') then
                if(read_a_line_p = '1') then
                    read_a_line <= '1';
                    read_mode <= read_mode_p;
                    read_a_line_p <= '0';
                else
                    read_a_line <= '0';
                end if;
            end if;
            if(mem_dreq_line = '1' or mem_dreq_line_sof = '1') then
                read_a_line_p <= '1';
                if(read_a_line_p = '1') then
                    request_error <= '1';
                end if;
            end if;
            if(mem_dreq_line = '1') then
                read_mode_p <= '0';
            end if;
            if(mem_dreq_line_sof = '1') then
                read_mode_p <= '1';
            end if;
            --State Machine Defaults
            datamove_go <= '0';
            if(timer_cnt /= ones) then
                timer_cnt <= std_logic_vector(unsigned(timer_cnt) + 1);
            end if;
            write_a_line_clr     <= '0';
            write_first_line_clr <= '0';
            read_a_line_clr      <= '0';
            read_first_line_clr  <= '0';
            case state is
            when RESET =>
                read_addr        <= (others => '0');
                write_addr       <= (others => '0');
                write_line_count <= 0;
                write_a_line     <= '0';
                write_first_line <= '0';
                read_a_line      <= '0';
                read_first_line  <= '0';
                read_a_line_p    <= '0';
                read_first_line_p <= '0';
                write_a_line_p <= '0';
                write_first_line_p <= '0';
                frame_num        <= 0;
                frame_num_prev   <= 0;
                frame_num_locked <= 0;
                vid_en           <= '0';
                request_error    <= '0';
                load_error       <= '0';
                timeout_error    <= '0';
                first            <= '0';
                write_mode       <= '0';
                
                datamove_dir  <= '0';
                datamove_go   <= '0';
                
                if(rst_sync = '0') then
                    state            <= IDLE;
                end if;
            when IDLE =>
                if(write_a_line = '1' or write_first_line = '1') then
                    state <= SETUP_M2S;
                    if(write_mode = '1') then
                        case frame_num is 
                        when 0 => write_addr <= FRAME0_START;
                        when 1 => write_addr <= FRAME1_START;
                        when 2 => write_addr <= FRAME2_START;
                        when others => 
                        end case;
                    end if;
                end if;
                if(read_a_line = '1' or read_first_line = '1') then
                    state <= SETUP_S2M;
                    if(read_mode = '1') then
                        frame_num_locked <= frame_num_prev;
                        case frame_num_prev is 
                        when 0 => read_addr <= FRAME0_START;
                        when 1 => read_addr <= FRAME1_START;
                        when 2 => read_addr <= FRAME2_START;
                        when others => 
                        end case;
                    end if;
                end if;

            when SETUP_M2S =>
                if(datamove_busy = '0') then
                    first         <= write_mode;
                    datamove_dir  <= '0';
                    datamove_go   <= '1';
                    datamove_addr <= write_addr;
                    state <= WAIT_M2S;
                end if;
                timer_cnt <= (others => '0');
            when WAIT_M2S =>
                if(datamove_done = '1') then
                    if(datamove_timed_out = '1') then
                        timeout_error <= '1';
                    end if;
                    
                    write_a_line_clr <= '1';
                    
                    state <= DONE_M2S;
                end if;
            when DONE_M2S =>
                write_line_count <= write_line_count + 1;
                write_addr <= std_logic_vector(unsigned(write_addr) + to_unsigned(LINE_SIZE_BYTES,32));
                write_time <= timer_cnt;
                if(write_line_count = v_active-1) then
                    write_line_count <= 0;
                    --swap frames
                    --only change to a buffer not being used
                    frame_num_prev <= frame_num;
                    vid_en <= '1';
                    case frame_num is 
                    when 0 => 
                        if(frame_num_locked /= 1) then
                            --normal
                            frame_num <= 1;
                        else
                            frame_num <= 2;
                        end if;
                    when 1 => 
                        if(frame_num_locked /= 2) then
                            --normal
                            frame_num <= 2;
                        else
                            frame_num <= 0;
                        end if;
                    when 2 => 
                        if(frame_num_locked /= 0) then
                            --normal
                            frame_num <= 0;
                        else
                            frame_num <= 1;
                        end if;
                    when others => 
                    end case;
                end if;

                state <= IDLE;
            when SETUP_S2M =>
                if(datamove_busy = '0') then
                    first         <= read_mode;
                    datamove_dir  <= '1';
                    datamove_go   <= '1';
                    datamove_addr <= read_addr;
                    state <= WAIT_S2M;
                end if;
                timer_cnt <= (others => '0');
            when WAIT_S2M =>
                if(datamove_done = '1') then
                    if(datamove_timed_out = '1') then
                        timeout_error <= '1';
                    end if;

                    read_a_line_clr <= '1';
                    
                    state <= DONE_S2M;
                end if;
            when DONE_S2M =>
                read_addr <= std_logic_vector(unsigned(read_addr) + to_unsigned(LINE_SIZE_BYTES,32));
                read_time <= timer_cnt;
                state <= IDLE;
            when others =>
            end case;
            --Jump state to reset
            if(rst_sync = '1') then
                state <= RESET;
            end if;
        end if;
    end process;

end arch;