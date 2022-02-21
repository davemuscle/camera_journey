library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

--Video Pattern Generator
--Synthesizable with multiple output options
--Base cases that this module should provide:

--  Vertical Color Bars = 0 
--  Horizontal Color Bars = 1
--  Checkerboard = 2
--  RGB Image from .txt file (sim only) = 3

--Output format includes RAW and RGB

entity pattern_generator is
	generic(
        H_ACTIVE : integer := 1920;
        V_ACTIVE : integer := 1080;
        SIM      : boolean := TRUE
	);
	port(
		clk      : in std_logic;
		enable   : in std_logic;
        i_file   : in string;
        pattern  : in std_logic_vector(1 downto 0);

        --input stream
        sof_i : in std_logic;
        eol_i : in std_logic;
        vld_i : in std_logic;
        
        --color data
		rgb      : out std_logic_vector(23 downto 0) := (others => '0');
        raw_BGGR : out std_logic_vector( 7 downto 0) := (others => '0');
		raw_GBRG : out std_logic_vector( 7 downto 0) := (others => '0');
        raw_GRBG : out std_logic_vector( 7 downto 0) := (others => '0');
        raw_RGGB : out std_logic_vector( 7 downto 0) := (others => '0');
        
        --video stream info
		sof_o : out std_logic := '0';
		eol_o : out std_logic := '0';
		vld_o : out std_logic := '0'

        );
end pattern_generator;

architecture arch of pattern_generator is 

    constant VERT_MARKER : unsigned(11 downto 0) := to_unsigned(V_ACTIVE/8,12);
    constant HORZ_MARKER : unsigned(11 downto 0) := to_unsigned(H_ACTIVE/8,12);

    signal horz_marker_cnt : unsigned(11 downto 0) := (others => '0');
    signal vert_marker_cnt : unsigned(11 downto 0) := (others => '0');

    signal column_cnt : unsigned(2 downto 0) := (others => '0');
    signal row_cnt    : unsigned(2 downto 0) := (others => '0');
    
    signal img_read_en : std_logic := '0';
    signal file_sync   : std_logic := '0';

    signal pattern_0_rgb : std_logic_vector(23 downto 0) := (others => '0');
    signal pattern_1_rgb : std_logic_vector(23 downto 0) := (others => '0');
    signal pattern_2_rgb : std_logic_vector(23 downto 0) := (others => '0');
    signal pattern_3_rgb : std_logic_vector(23 downto 0) := (others => '0');

    constant LATENCY : integer := 3;
    
    signal sof_metadata : std_logic_vector(LATENCY-1 downto 0) := (others => '0');
    signal eol_metadata : std_logic_vector(LATENCY-1 downto 0) := (others => '0');
    signal vld_metadata : std_logic_vector(LATENCY-1 downto 0) := (others => '0');
    
    constant COLOR_RGB_WHITE  : std_logic_vector(23 downto 0) := x"F8F8F8";
    constant COLOR_RGB_YELLOW : std_logic_vector(23 downto 0) := x"F8F800";
    constant COLOR_RGB_CYAN   : std_logic_vector(23 downto 0) := x"00F8F8";
    constant COLOR_RGB_GREEN  : std_logic_vector(23 downto 0) := x"00F800";
    constant COLOR_RGB_PURPLE : std_logic_vector(23 downto 0) := x"F800F8";
    constant COLOR_RGB_BLUE   : std_logic_vector(23 downto 0) := x"0000F8";
    constant COLOR_RGB_RED    : std_logic_vector(23 downto 0) := x"F80000";
    constant COLOR_RGB_BLACK  : std_logic_vector(23 downto 0) := x"080808";

    signal odd_col : std_logic := '0';
    signal odd_row : std_logic := '0';

    signal odd_col_0 : std_logic := '0';
    signal odd_row_0 : std_logic := '0';
    signal odd_col_1 : std_logic := '0';
    signal odd_row_1 : std_logic := '0';
    signal odd_col_2 : std_logic := '0';
    signal odd_row_2 : std_logic := '0';
    
    signal color_out : std_logic_vector(23 downto 0) := (others => '0');
    
    signal sof_en : std_logic := '0';
    
    signal col_row : std_logic_vector(1 downto 0) := (others => '0');
    signal first : std_logic := '0';
begin    

    --provide counters for pattern logic
    process(clk)
    begin
        if(rising_edge(clk)) then
            if(enable = '1' and sof_en = '1') then
                if(vld_i = '1') then
                    if(first = '1') then
                        horz_marker_cnt <= (others => '0');
                        column_cnt <= (others => '0');
                        odd_col_0 <= '0';
                        first <= '0';
                    else
                        horz_marker_cnt <= horz_marker_cnt + 1;
                        odd_col_0 <= not odd_col_0;
                    end if;
                    if(eol_i = '1') then
                        first <= '1';
                        vert_marker_cnt <= vert_marker_cnt + 1;
                        odd_row_0 <= not odd_row_0;
                        odd_col_0 <= '0';
                        if(vert_marker_cnt = VERT_MARKER) then
                            row_cnt <= row_cnt + 1;
                            vert_marker_cnt <= (others => '0');
                        end if;
                    end if;      
                    if(horz_marker_cnt = HORZ_MARKER) then
                        column_cnt <= column_cnt+1;
                        horz_marker_cnt <= (others => '0');
                    end if;
                    
                end if;
                --should get synth'd out in HW
                img_read_en <= vld_i;
                file_sync   <= sof_i;
            end if;

            if(sof_i = '1') then
                odd_row_0  <= '0';
                odd_col_0  <= '0';
                sof_en     <= '1';

                horz_marker_cnt <= (others => '0');
                vert_marker_cnt <= (others => '0');
                column_cnt      <= (others => '0');
                row_cnt         <= (others => '0');

                img_read_en <= vld_i;
                file_sync   <= sof_i;
            end if;
            
            if(enable = '0') then
                sof_en <= '0';
            end if;
            
            if(pattern /= "11") then
                img_read_en <= '0';
                file_sync   <= '0';
            end if;
            
        end if;
    end process;
    
    --image from text file generation
    GEN_IMG : if(SIM=TRUE) generate 
        img_reader_inst : entity work.image_reader
        port map(
            clk    => clk,
            i_file => i_file,
            enable => img_read_en,
            sync   => file_sync,
            rgb    => pattern_3_rgb
        );
    end generate GEN_IMG;

    col_row(1) <= column_cnt(0);
    col_row(0) <= row_cnt(0);

    --pattern generation
    process(clk)
    begin
        if(rising_edge(clk)) then
            case column_cnt is
                when "000"  => pattern_0_rgb <= COLOR_RGB_WHITE ;
                when "001"  => pattern_0_rgb <= COLOR_RGB_YELLOW;
                when "010"  => pattern_0_rgb <= COLOR_RGB_CYAN  ;
                when "011"  => pattern_0_rgb <= COLOR_RGB_GREEN ;
                when "100"  => pattern_0_rgb <= COLOR_RGB_PURPLE;
                when "101"  => pattern_0_rgb <= COLOR_RGB_RED   ;
                when "110"  => pattern_0_rgb <= COLOR_RGB_BLUE  ;
                when others => pattern_0_rgb <= COLOR_RGB_BLACK ;    
            end case;
            case row_cnt is
                when "000"  => pattern_1_rgb <= COLOR_RGB_WHITE ;
                when "001"  => pattern_1_rgb <= COLOR_RGB_YELLOW;
                when "010"  => pattern_1_rgb <= COLOR_RGB_CYAN  ;
                when "011"  => pattern_1_rgb <= COLOR_RGB_GREEN ;
                when "100"  => pattern_1_rgb <= COLOR_RGB_PURPLE;
                when "101"  => pattern_1_rgb <= COLOR_RGB_RED   ;
                when "110"  => pattern_1_rgb <= COLOR_RGB_BLUE  ;
                when others => pattern_1_rgb <= COLOR_RGB_BLACK ;    
            end case;
            case col_row is
                when "00"   => pattern_2_rgb <= COLOR_RGB_WHITE;
                when "01"   => pattern_2_rgb <= COLOR_RGB_BLACK;
                when "10"   => pattern_2_rgb <= COLOR_RGB_BLACK;
                when others => pattern_2_rgb <= COLOR_RGB_WHITE;
            end case;
        end if;
    end process;

	
    --generate stream signals
    process(clk)
    begin
        if(rising_edge(clk)) then
        
            sof_metadata(0) <= sof_i;
            eol_metadata(0) <= eol_i;
            vld_metadata(0) <= vld_i;
            
            for i in 1 to LATENCY-1 loop
                sof_metadata(i) <= sof_metadata(i-1); 
                eol_metadata(i) <= eol_metadata(i-1); 
                vld_metadata(i) <= vld_metadata(i-1); 
            end loop;
            
            sof_o <= sof_metadata(LATENCY-1);
            eol_o <= eol_metadata(LATENCY-1);
            vld_o <= vld_metadata(LATENCY-1);
        
        end if;
    end process;
     
    --setup color outputs and raw data
    process(clk)
    begin
        if(rising_edge(clk)) then
        
            case pattern is
            when "00"   => color_out <= pattern_0_rgb;
            when "01"   => color_out <= pattern_1_rgb;
            when "10"   => color_out <= pattern_2_rgb;
            when others => color_out <= pattern_3_rgb;
            end case;
            
            rgb <= color_out;
            
            odd_col_1 <= odd_col_0;
            odd_row_1 <= odd_row_0;
            --odd_col_2 <= odd_col_1;
            --odd_row_2 <= odd_row_1;
            
            odd_col <= odd_col_1;
            odd_row <= odd_row_1;
            
            
            --setup raw outputs
            --possible setups for odds/evens:
            --[B G \ G R] 
            --[G B \ R G]
            --[G R \ B G]
            --[R G \ G B]
            if(odd_row = '0' and odd_col = '0') then
                raw_BGGR <= color_out( 7 downto  0);
                raw_GBRG <= color_out(15 downto  8);
                raw_GRBG <= color_out(15 downto  8);
                raw_RGGB <= color_out(23 downto 16);
            elsif(odd_row = '0' and odd_col = '1') then
                raw_BGGR <= color_out(15 downto  8);
                raw_GBRG <= color_out( 7 downto  0);
                raw_GRBG <= color_out(23 downto 16);
                raw_RGGB <= color_out(15 downto  8);
            elsif(odd_row = '1' and odd_col = '0') then
                raw_BGGR <= color_out(15 downto  8);
                raw_GBRG <= color_out(23 downto 16);
                raw_GRBG <= color_out( 7 downto  0);
                raw_RGGB <= color_out(15 downto  8);
            else
                raw_BGGR <= color_out(23 downto 16);
                raw_GBRG <= color_out(15 downto  8);
                raw_GRBG <= color_out(15 downto  8);
                raw_RGGB <= color_out( 7 downto  0);
            end if;           
            
        end if;    
    end process;

end arch;