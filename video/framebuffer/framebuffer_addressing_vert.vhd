library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
	
--Provides different vertical addressing modes for reading the framebuffer

--The datamover/arbiter combo always reads a full line of video from the framebuffer
--So, this block only handles different vertical addressing modes to provide effects like:
    --Splitscreen (width-wise)
    --Vertical flip
    --Vertical mirror
    --Vertical scroll

--AXI addresses are in terms of bytes
    
entity framebuffer_addressing_vert is
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
        
        --user control
        bypass           : in std_logic;
        splitscreen      : in std_logic;
        splitscreen_type : in std_logic_vector(5 downto 0); --1 for splitscreen of 2, 0x3F for 64
        flip             : in std_logic;
        mirror           : in std_logic;
        scroll           : in std_logic;
        scroll_offset    : in std_logic_vector(11 downto 0);

        --arbiter status
        first                : in std_logic;
        frame_num_read       : in integer range 0 to 3;

        --datamover signals from arbiter
        arbiter_go           : in   std_logic;
        arbiter_dir          : in   std_logic;
        arbiter_busy         : out  std_logic := '0';
        arbiter_done         : out  std_logic := '0';
        arbiter_timed_out    : out  std_logic := '0';
        arbiter_transfer_len : in   std_logic_vector(15 downto 0);
        arbiter_addr         : in   std_logic_vector(31 downto 0);
        
        --datamover signals to datamover
        datamove_go           : out std_logic := '0';
        datamove_dir          : out std_logic := '0';
        datamove_busy         : in  std_logic;
        datamove_done         : in  std_logic;
        datamove_timed_out    : in  std_logic;
        datamove_transfer_len : out std_logic_vector(15 downto 0) := (others => '0');
        datamove_addr         : out std_logic_vector(31 downto 0) := (others => '0')
        
        
	);
end framebuffer_addressing_vert;

architecture arch of framebuffer_addressing_vert is 

    --How many bytes are in a pixel
    constant PIXEL_BYTE_SIZE : integer := PIXEL_WIDTH/8;
    --How many bytes are in a line
    constant LINE_SIZE_BYTES : integer := h_active*PIXEL_BYTE_SIZE;
    --How many bytes are in exactly one frame
    constant FRAME_SIZE_BYTES : integer := h_active*v_active*PIXEL_BYTE_SIZE;
    --Rounding the frame size
    constant FRAME_SIZE_BYTES_LOG2 : integer := integer(ceil(log2(real(FRAME_SIZE_BYTES))));
    constant FRAME_SIZE_BYTES_NP2  : integer := 2**FRAME_SIZE_BYTES_LOG2;

    constant FRAME0_START : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(0*FRAME_SIZE_BYTES_NP2,32));
    constant FRAME1_START : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(1*FRAME_SIZE_BYTES_NP2,32));
    constant FRAME2_START : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(2*FRAME_SIZE_BYTES_NP2,32));

    constant FRAME0_END : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(1*FRAME_SIZE_BYTES+0*FRAME_SIZE_BYTES_NP2,32));
    constant FRAME1_END : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(1*FRAME_SIZE_BYTES+1*FRAME_SIZE_BYTES_NP2,32));
    constant FRAME2_END : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(1*FRAME_SIZE_BYTES+2*FRAME_SIZE_BYTES_NP2,32));

    constant FRAME0_LAST   : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned((v_active-1)*LINE_SIZE_BYTES+0*FRAME_SIZE_BYTES_NP2,32));
    constant FRAME1_LAST   : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned((v_active-1)*LINE_SIZE_BYTES+1*FRAME_SIZE_BYTES_NP2,32));
    constant FRAME2_LAST   : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned((v_active-1)*LINE_SIZE_BYTES+2*FRAME_SIZE_BYTES_NP2,32));

    type state_t is (RESET, IDLE,
                     FLIP_SETUP1, FLIP_SETUP,
                     SCROLL_SETUP1, SCROLL_SETUP2, SCROLL_SETUP3,
                     SPLIT_SETUP1, SPLIT_SETUP2, SPLIT_SETUP3, SPLIT_SETUP3_1, SPLIT_SETUP4
                    );
    signal state : state_t := IDLE;
    
    
    signal arbiter_addr_lock : std_logic_vector(31 downto 0)     := (others => '0');
    signal arbiter_addr_sof_lock : std_logic_vector(31 downto 0) := (others => '0');
    signal arbiter_addr_end_lock : std_logic_vector(31 downto 0) := (others => '0');
    signal arbiter_addr_last_lock : std_logic_vector(31 downto 0) := (others => '0');
    signal arbiter_addr_no_offset : std_logic_vector(31 downto 0) := (others => '0');
    signal arbiter_addr_adj       : std_logic_vector(31 downto 0) := (others => '0');
    
    signal line_count  : integer range 0 to 4095 := 0;
    
    --flip
    signal flip_enable : std_logic := '0';
    signal flip_addr   : std_logic_vector(31 downto 0) := (others => '0');
    
    --splitscreen
    signal splitscreen_enable : std_logic := '0';
    signal split_addr : std_logic_vector(31 downto 0) := (others => '0');
    type mark_array is array(0 to 63) of integer range 0 to 4095;
    
    function splitscreen_mark_init return mark_array is
        variable y : mark_array;
    begin
        for i in 0 to 63 loop
            y(i) := integer(ceil(real(v_active)/real(i+1)));
        end loop;
        return y;
    end function;

    signal mark_t : mark_array := splitscreen_mark_init;
    signal mark : integer range 0 to 4095 := 0;
    signal screen : integer range 0 to 4095 := 0;
    --signal screen_x_size : std_logic_vector(31 downto 0) := (others => '0');
    signal type_mult : integer range 0 to 4095 := 0;
    signal type_mult_p1 : integer range 0 to 4095 := 0;
    
    --scroll
    signal scroll_enable : std_logic := '0';
    signal scroll_addr : std_logic_vector(31 downto 0) := (others => '0');
    signal offset_to_boundary : std_logic_vector(31 downto 0) := (others => '0');
    signal scroll_offset_boundary : std_logic_vector(31 downto 0) := (others => '0');
    signal scroll_offset_fix : std_logic := '0';
    signal scroll_offset_addr : std_logic_vector(31 downto 0) := (others => '0');
    
    --mirror
    signal mirror_enable : std_logic := '0';
    
    --output signals
    constant LATENCY : integer := 11;
    signal go_pipe  : std_logic_vector(LATENCY-1 downto 0) := (others => '0');
    signal dir_pipe : std_logic_vector(LATENCY-1 downto 0) := (others => '0');
    
    signal rst_meta, rst_sync : std_logic := '0';
 
 
    signal splitscreen_type_locked : std_logic_vector(5 downto 0) := (others => '0');
    
    --signal arbiter_addr_managed : std_logic_vector(31 downto 0) := (others => '0');
    
    signal scroll_addr_no_offset : std_logic_vector(31 downto 0) := (others => '0');
    
begin    

    datamove_go           <= go_pipe(LATENCY-1)  when bypass = '0' else arbiter_go;
    datamove_dir          <= dir_pipe(LATENCY-1) when bypass = '0' else arbiter_dir;
    datamove_addr         <= flip_addr           when bypass = '0' else arbiter_addr;
    datamove_transfer_len <= arbiter_transfer_len;
    
    arbiter_busy      <= datamove_busy;
    arbiter_done      <= datamove_done;
    arbiter_timed_out <= datamove_timed_out;
    

    process(clk)
    begin
        if(rising_edge(clk)) then
        
            --Inputs
            go_pipe <= go_pipe(LATENCY-2 downto 0) & arbiter_go;
            dir_pipe <= dir_pipe(LATENCY-2 downto 0) & arbiter_dir;
            
            rst_meta <= rst;
            rst_sync <= rst_meta;

            case state is
            when RESET =>
            
                flip_enable        <= '0';
                scroll_enable      <= '0';
                splitscreen_enable <= '0';
                mirror_enable      <= '0';
                screen             <= 0;
                line_count         <= 0;
                
                go_pipe  <= (others => '0');
                dir_pipe <= (others => '0');
                
                if(rst_sync = '0') then
                    state <= IDLE;
                end if;
                    
            when IDLE =>
     
                if(arbiter_go = '1' and arbiter_dir = '1') then    
                    
                    --Latch the address we're given
                    --arbiter_addr_lock <= arbiter_addr;


                    --First line of video being requested
                    if(first = '1') then
                        
                        line_count            <= 0;
  
                        --Latch enables at the start of the frame
                        flip_enable        <= flip;
                        scroll_enable      <= scroll;
                        splitscreen_enable <= splitscreen;
                        mirror_enable      <= mirror;
                        
                        --Reset virtual screen count
                        screen <= 0;
                        
                        --Pull the splitscreen marker from a LUT
                        mark <= mark_t(to_integer(unsigned(splitscreen_type)));
                        type_mult <= to_integer(unsigned(splitscreen_type));

                        splitscreen_type_locked <= splitscreen_type;
                        scroll_offset_addr <= std_logic_vector(to_unsigned(LINE_SIZE_BYTES*to_integer(unsigned(scroll_offset)),32));

                        arbiter_addr_lock <= arbiter_addr;

                        --Some values for determining where we are in the frame buffer
                        case frame_num_read is
                        when 0 =>
                            arbiter_addr_sof_lock  <= FRAME0_START;
                            arbiter_addr_end_lock  <= FRAME0_END;
                            arbiter_addr_last_lock <= FRAME0_LAST;
                        when 1 =>
                            arbiter_addr_sof_lock  <= FRAME1_START;
                            arbiter_addr_end_lock  <= FRAME1_END;
                            arbiter_addr_last_lock <= FRAME1_LAST;
                        when 2 =>
                            arbiter_addr_sof_lock  <= FRAME2_START;
                            arbiter_addr_end_lock  <= FRAME2_END;
                            arbiter_addr_last_lock <= FRAME2_LAST;
                        when others       => end case;
    
                    end if;
                    
                    state <= SPLIT_SETUP1;
                    
                end if;
                
                --If we are writing a line of video, just jump the address 
                if(arbiter_go = '1' and arbiter_dir = '0') then
                    flip_addr           <= arbiter_addr;
                    go_pipe(LATENCY-1)  <= arbiter_go;
                    go_pipe(LATENCY-2 downto 0) <= (others => '0');
                    dir_pipe(LATENCY-1) <= arbiter_dir;
                    dir_pipe(LATENCY-2 downto 0) <= (others => '0');
                end if;
                

            when SPLIT_SETUP1 =>
                --This might not synthesize well. We'll see.
                arbiter_addr_no_offset <= std_logic_vector(unsigned(arbiter_addr_lock) - unsigned(arbiter_addr_sof_lock));
                --screen_x_size          <= std_logic_vector(to_unsigned(screen*LINE_SIZE_BYTES*mark,32));
                
                type_mult_p1 <= type_mult + 1;


                state <= SPLIT_SETUP2;
                
            when SPLIT_SETUP2 =>
            
                --arbiter_addr_adj <= std_logic_vector(unsigned(arbiter_addr_no_offset) - unsigned(screen_x_size));
                --arbiter_addr_adj <= arbiter_addr_no_offset;
                
                arbiter_addr_adj <= std_logic_vector(to_unsigned(to_integer(unsigned(arbiter_addr_no_offset))*type_mult_p1,32));

                state <= SPLIT_SETUP3;
                
            when SPLIT_SETUP3 =>
            
                state <= SPLIT_SETUP3_1;
                
            when SPLIT_SETUP3_1 =>
                
                state <= SPLIT_SETUP4;
                
            when SPLIT_SETUP4 =>
                
                if(splitscreen_enable = '1') then
                    split_addr <= std_logic_vector(unsigned(arbiter_addr_adj) + unsigned(arbiter_addr_sof_lock));
                else
                    split_addr <= arbiter_addr_lock;
                end if;
                
                state <= SCROLL_SETUP1;
     
            when SCROLL_SETUP1 =>

                --Find how far below we are from next boundary
                offset_to_boundary <= std_logic_vector(unsigned(arbiter_addr_end_lock) - unsigned(split_addr));

                state <= SCROLL_SETUP2;
                
            when SCROLL_SETUP2 =>

                if(unsigned(scroll_offset_addr) >= unsigned(offset_to_boundary)) then
                    scroll_offset_boundary <= std_logic_vector(unsigned(scroll_offset_addr) - unsigned(offset_to_boundary));
                    scroll_offset_fix <= '1';
                else
                    scroll_offset_fix <= '0';
                end if;
                
                state <= SCROLL_SETUP3;
                
            when SCROLL_SETUP3 =>
            
                if(scroll_enable = '1') then 
                    if(scroll_offset_fix = '1') then
                        scroll_addr <= std_logic_vector(unsigned(arbiter_addr_sof_lock) + unsigned(scroll_offset_boundary));
                    else
                        scroll_addr <= std_logic_vector(unsigned(split_addr) + unsigned(scroll_offset_addr));
                    end if;
                else
                    scroll_addr <= split_addr;
                end if;
                
                state <= FLIP_SETUP1;
                
            when FLIP_SETUP1 =>
            
                scroll_addr_no_offset <= std_logic_vector(unsigned(scroll_addr) - unsigned(arbiter_addr_sof_lock));
                state <= FLIP_SETUP;

            when FLIP_SETUP =>

                if(flip_enable = '1') then
                    flip_addr <= std_logic_vector(unsigned(arbiter_addr_last_lock) - unsigned(scroll_addr_no_offset)); 
                else
                    flip_addr <= scroll_addr;
                end if;
                
                --If splitscreen is enabled, check if we need to reload
                if(splitscreen_enable = '1' and line_count = mark-1) then
                
                    arbiter_addr_lock <= arbiter_addr_sof_lock;
                
                    --Increment the virtual screen count
                    screen <= screen + 1;
                    --Reset line count
                    line_count <= 0;
                    --If mirror is on, toggle the flip
                    if(mirror_enable = '1') then
                        flip_enable <= not flip_enable;
                    end if;
                else
                    --Otherwise increase line count
                    line_count <= line_count + 1;
                    arbiter_addr_lock <= std_logic_vector(unsigned(arbiter_addr_lock) + to_unsigned(LINE_SIZE_BYTES,32));
                end if;

                
                state <= IDLE;

            when others => end case;

            if(rst_sync = '1') then
                state <= RESET;
            end if;

        end if;
    end process;

end arch;