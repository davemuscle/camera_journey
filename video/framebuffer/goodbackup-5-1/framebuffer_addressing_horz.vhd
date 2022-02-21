library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
	
--Provides different horizontal addressing modes for reading the framebuffer

--This block only handles different horizontal stream modes to provide effects like:
    --Splitscreen (length-wise)
    --Horizontal flip
    --Horizontal mirror
    --Horizontal scroll

--Wrote this a little quick: There may be some timing / functional bugs. We'll see. 
--Only simulated at 160x120 resolution so far.
    
entity framebuffer_addressing_horz is
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

        --input stream
        pixel_in_sof     : in std_logic;
        pixel_in_eol     : in std_logic;
        pixel_in_valid   : in std_logic;
        pixel_in         : in std_logic_vector(PIXEL_WIDTH-1 downto 0);
        
        --output stream
        pixel_out_sof   : out std_logic := '0';
        pixel_out_eol   : out std_logic := '0';
        pixel_out_valid : out std_logic := '0';
        pixel_out       : out std_logic_vector(PIXEL_WIDTH-1 downto 0) := (others => '0')
        
        
        
	);
end framebuffer_addressing_horz;

architecture arch of framebuffer_addressing_horz is 
    
    constant RAM_SIZE_LOG2 : integer := integer(ceil(log2(real(h_active))));
    
    --Ping Pong RAM Signals
    signal ram_wr_addr : std_logic_vector(RAM_SIZE_LOG2-1 downto 0) := (others => '0');
    signal ram_rd_addr : std_logic_vector(RAM_SIZE_LOG2-1 downto 0) := (others => '0');
    signal ram_wr_addr_full : std_logic_vector(RAM_SIZE_LOG2 downto 0) := (others => '0');
    signal ram_rd_addr_full : std_logic_vector(RAM_SIZE_LOG2 downto 0) := (others => '0');
    signal ram_wr_sel : std_logic := '0';
    signal ram_rd_sel : std_logic := '0';
    signal ram_wr_data : std_logic_vector(PIXEL_WIDTH-1 downto 0) := (others => '0');
    signal ram_rd_data : std_logic_vector(PIXEL_WIDTH-1 downto 0) := (others => '0');
    signal ram_wr_en   : std_logic := '0';
    signal ram_rd_en   : std_logic := '0';
    
    --Ping Pong Inputs Signals
    signal write_mux : std_logic := '0';
    signal read_mux  : std_logic := '0';
    
    signal pixel_out_sof_pre : std_logic := '0';
    signal pixel_out_eol_pre : std_logic := '0';
    
    signal pixel_in_sof_lvl : std_logic := '0';
    signal pixel_in_eol_dly : std_logic := '0';
    
    signal ram_rd_en_dly : std_logic := '0';
    
    type state_t is (RESET, IDLE,
                     FLIP_SETUP,
                     SCROLL_SETUP1, SCROLL_SETUP2, SCROLL_SETUP3,
                     SPLIT_SETUP1, SPLIT_SETUP2, SPLIT_SETUP3, SPLIT_SETUP4,
                     KALEIDO_SETUP,
                     CLEANUP
                    );
    signal state : state_t := IDLE;
    
    
    
    signal arbiter_addr_lock : std_logic_vector(31 downto 0)     := (others => '0');
    signal arbiter_addr_sof_lock : std_logic_vector(31 downto 0) := (others => '0');
    
    signal true_count  : integer range 0 to 4095 := 0;
    signal true_count_dly  : integer range 0 to 4095 := 0;
    signal true_count_dly_dly  : integer range 0 to 4095 := 0;
    signal true_count_dly_dly_dly  : integer range 0 to 4095 := 0;
    signal true_count_dly_dly_dly_dly  : integer range 0 to 4095 := 0;
    signal pixel_count  : integer range 0 to 4095 := 0;
    signal pixel_count_dly  : integer range 0 to 4095 := 0;
    
    --flip
    signal flip_enable : std_logic := '0';
    signal flip_addr   : std_logic_vector(RAM_SIZE_LOG2-1 downto 0) := (others => '0');
    
    signal splitscreen_enable : std_logic := '0';
    
    --scroll
    signal scroll_enable : std_logic := '0';
    signal scroll_addr : std_logic_vector(RAM_SIZE_LOG2-1 downto 0) := (others => '0');
    
    signal kaleido_enable : std_logic := '0';
    
    signal frame_num : integer range 0 to 3 := 0;
    

    signal offset_to_boundary : std_logic_vector(RAM_SIZE_LOG2-1 downto 0) := (others => '0');
    
    signal scroll_offset_boundary : std_logic_vector(RAM_SIZE_LOG2-1 downto 0) := (others => '0');
    
    signal scroll_offset_fix : std_logic := '0';
    
    signal split_addr : std_logic_vector(RAM_SIZE_LOG2-1 downto 0) := (others => '0');
    signal split_addr_unadj : std_logic_vector(RAM_SIZE_LOG2-1 downto 0) := (others => '0');
    signal split_addr_unadj2 : std_logic_vector(RAM_SIZE_LOG2-1 downto 0) := (others => '0');
    
    constant LATENCY : integer := 9;
    signal go_pipe  : std_logic_vector(LATENCY-1 downto 0) := (others => '0');
    signal dir_pipe : std_logic_vector(LATENCY-1 downto 0) := (others => '0');
    
    signal mirror_enable : std_logic := '0';
    
    type mark_array is array(0 to 63) of integer range 0 to 4095;
    
    function splitscreen_mark_init return mark_array is
        variable y : mark_array;
    begin
        for i in 0 to 63 loop
            y(i) := integer(ceil(real(h_active)/real(i+1)));
        end loop;
        return y;
    end function;
    
    signal mark_t : mark_array := splitscreen_mark_init;
    signal mark : integer range 0 to 4095 := 0;
    signal screen : integer range 0 to 4095 := 0;
   
    
    signal screen_x_size : std_logic_vector(RAM_SIZE_LOG2-1 downto 0) := (others => '0');
    
    signal type_mult : integer range 0 to 4095 := 0;
    signal type_mult2 : integer range 0 to 4095 := 0;
    
    
    signal read_go : std_logic := '0';
    constant PIPE_LENGTH : integer := 9;
    signal read_pipe : std_logic_vector(PIPE_LENGTH-1 downto 0) := (others => '0');
    
    signal rd_addr_pre_pre : std_logic_vector(RAM_SIZE_LOG2-1 downto 0) := (others => '0');
    signal rd_addr_pre : std_logic_vector(RAM_SIZE_LOG2-1 downto 0) := (others => '0');
    signal rd_addr_adj0 : std_logic_vector(RAM_SIZE_LOG2-1 downto 0) := (others => '0');
    signal rd_addr_adj1 : std_logic_vector(RAM_SIZE_LOG2-1 downto 0) := (others => '0');
    
    signal fe1, fe2, fe3, fe4, fe5, fe6, fe7 : std_logic := '0';
    
    signal rst_meta, rst_sync : std_logic := '0';

    signal scroll_offset_locked : std_logic_vector(11 downto 0) := (others => '0');
    
begin    

    process(clk)
    begin
        if(rising_edge(clk)) then
        
            rst_meta <= rst;
            rst_sync <= rst_meta;
        
            ram_wr_en <= pixel_in_valid;
            ram_wr_data <= pixel_in;
            
            if(ram_wr_en = '1') then
                ram_wr_addr <= std_logic_vector(unsigned(ram_wr_addr)+1);
            end if;
            
            if(pixel_in_sof = '1') then
                pixel_in_sof_lvl <= '1';
                
            end if;
            
            pixel_in_eol_dly <= pixel_in_eol;
            
            if(pixel_in_eol_dly = '1') then
                ram_wr_sel <= not ram_wr_sel;
                ram_wr_addr <= (others => '0');
                read_go <= '1';
            end if;
            
            if(read_go = '1') then
                ram_rd_en <= '1';
            else
                ram_rd_en <= '0';
            end if;
            
            read_pipe <= read_pipe(PIPE_LENGTH-2 downto 0) & read_go;
            
            --start of line read
            if(read_pipe(0) = '0' and read_go = '1') then
            
                true_count  <= 0;
                pixel_count <= 0;
                screen      <= 0;
                
                if(pixel_in_sof_lvl = '1') then
                    mark      <= mark_t(to_integer(unsigned(splitscreen_type)));
                    type_mult <= to_integer(unsigned(splitscreen_type));

                    flip_enable        <= flip;
                    scroll_enable      <= scroll;
                    splitscreen_enable <= splitscreen;
                    mirror_enable      <= mirror;
                
                
                    scroll_offset_locked <= scroll_offset;
                end if;
            end if;
            
            fe2 <= flip_enable;
            fe3 <= fe2;
            fe4 <= fe3;
            fe5 <= fe4;
            fe6 <= fe5;
            fe7 <= fe6;
            
            if(read_pipe(0) = '1') then
                
                --true_count <= true_count + 1;
                
                if(splitscreen_enable = '1' and pixel_count = mark-1) then
                    screen      <= screen + 1;
                    pixel_count <= 0;
                    if(mirror_enable = '1') then
                        flip_enable <= not flip_enable;
                    end if;
                else
                    pixel_count <= pixel_count + 1;
                end if;
                
                type_mult2 <= type_mult + 1;
                
                pixel_count_dly <= pixel_count;
                
            end if;
            
            if(read_pipe(1) = '1') then
                
                true_count_dly <= true_count;
                
                if(pixel_count_dly = 0) then
                    rd_addr_pre <= (others => '0');
                else
                    rd_addr_pre <= std_logic_vector(unsigned(rd_addr_pre)+1);
                end if;
            
                screen_x_size          <= std_logic_vector(to_unsigned(screen*mark,RAM_SIZE_LOG2));
            
            end if;
            
            ram_rd_en <= '0';
            
            if(read_pipe(2) = '1') then

                if(splitscreen_enable = '1') then
                    split_addr <= std_logic_vector(to_unsigned(to_integer(unsigned(rd_addr_pre))*type_mult2,RAM_SIZE_LOG2));
                else
                    split_addr <= rd_addr_pre;
                end if;
            end if;
            
            if(read_pipe(3) = '1') then
            
                offset_to_boundary <= std_logic_vector(to_unsigned(h_active,RAM_SIZE_LOG2)-unsigned(split_addr));
                split_addr_unadj <= split_addr;
                
            end if;
            
            if(read_pipe(4) = '1') then
                if(resize(unsigned(scroll_offset_locked),RAM_SIZE_LOG2) >= unsigned(offset_to_boundary)) then
                    scroll_offset_boundary <= std_logic_vector(resize(unsigned(scroll_offset_locked),RAM_SIZE_LOG2) - unsigned(offset_to_boundary));
                    scroll_offset_fix <= '1';
                else
                    scroll_offset_fix <= '0';
                end if;
                
                split_addr_unadj2 <= split_addr_unadj;
            end if;
            
            if(read_pipe(5) = '1') then
            
                if(scroll_enable = '1') then 
                    if(scroll_offset_fix = '1') then
                        scroll_addr <= std_logic_vector(to_unsigned(0,RAM_SIZE_LOG2) + unsigned(scroll_offset_boundary));
                    else
                        scroll_addr <= std_logic_vector(unsigned(split_addr_unadj2) + resize(unsigned(scroll_offset_locked),RAM_SIZE_LOG2));
                    end if;
                else
                    scroll_addr <= split_addr_unadj2;
                end if;

            end if;
            
            if(read_pipe(6) = '1') then
                
                ram_rd_en <= '1';
                
                if(fe7 = '1') then
                    ram_rd_addr <= std_logic_vector(to_unsigned(h_active-1,RAM_SIZE_LOG2) - unsigned(scroll_addr)); 
                else
                    ram_rd_addr <= scroll_addr;
                end if;
                
            end if;
            
            pixel_out_valid <= '0';
            pixel_out_eol   <= '0';
            pixel_out_sof   <= '0';


            if(read_pipe(8) = '1') then
            
                true_count <= true_count + 1;
                
                pixel_out_valid <= '1';
                
                if(true_count = h_active-1) then
                    pixel_out_eol <= '1';
                    
                    read_pipe <= (others => '0');
                    read_go   <= '0';
                    ram_rd_en <= '0';
                    
                    ram_rd_sel <= not ram_rd_sel;
                    
                end if;
                
                if(true_count = 0) then
                    pixel_out_sof <= pixel_in_sof_lvl;
                    pixel_in_sof_lvl <= '0';
                end if;
            
            end if;
            
            pixel_out <= ram_rd_data;
        
            if(bypass = '1') then
                pixel_out       <= pixel_in;
                pixel_out_valid <= pixel_in_valid;
                pixel_out_sof   <= pixel_in_sof;
                pixel_out_eol   <= pixel_in_eol;
            end if;
            
            if(rst_sync = '1') then
                ram_wr_en <= '0';
                ram_rd_en <= '0';
                
                pixel_out_valid <= '0';
                pixel_out_sof <= '0';
                pixel_out_eol <= '0';
                
                pixel_in_sof_lvl <= '0';
                
                ram_rd_sel <= '0';
                ram_wr_sel <= '0';
                
                read_pipe <= (others => '0');
                read_go <= '0';
                true_count <= 0;
                pixel_count <= 0;
                
            end if;
            
        end if;
    end process;
    

    
    ram_wr_addr_full <= ram_wr_sel & ram_wr_addr;
    ram_rd_addr_full <= ram_rd_sel & ram_rd_addr;
    
	bram_inst : entity work.inferred_ram
	generic map(
		gDEPTH => RAM_SIZE_LOG2+1,
		gWIDTH => PIXEL_WIDTH,
		gOREGS => 0
	)
	port map(
		a_clk  => clk,
		a_wr   => ram_wr_en,
		a_en   => '0',
		a_di   => ram_wr_data,
		a_do   => open,
		a_addr => ram_wr_addr_full,
		b_clk  => clk,
		b_wr   => '0',
		b_en   => ram_rd_en,
		b_di   => (others => '0'),
		b_do   => ram_rd_data,
		b_addr => ram_rd_addr_full
	);

end arch;