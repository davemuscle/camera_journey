library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

--Camera Video Stimulus

entity camera_stim is
	generic(
        USE_BLANKING : boolean := false;
        USE_IMG_FILE : boolean := false;
        i_file       : string;
        v_file       : string;
	    h_active 	 : integer := 1920;
	    h_total      : integer := 2200;
	    v_active     : integer := 1080;
	    v_total		 : integer := 1125;
        v_sync_spot  : integer := 1100;
        num_images   : integer := 16
	);
	port(
		clk      : in std_logic;
		enable   : in std_logic;
        pattern  : in std_logic_vector(1 downto 0);
        movement : in std_logic;
        
        --color data
		rgb      : out std_logic_vector(23 downto 0);
        raw_BGGR : out std_logic_vector(7 downto 0);
		raw_GBRG : out std_logic_vector(7 downto 0);
        raw_GRBG : out std_logic_vector(7 downto 0);
        raw_RGGB : out std_logic_vector(7 downto 0);
        
        --video stream info
		href  : out std_logic := '0';
        vsync : out std_logic := '0';
        sof   : out std_logic := '0';
        eol   : out std_logic := '0';
        valid : out std_logic := '0'

        );
end camera_stim;

architecture arch of camera_stim is 

	signal h_cnt : integer range 0 to 16383 := 0;
	signal v_cnt : integer range 0 to 16383 := 0;

    signal h_cmp, v_cmp : integer range 0 to 16383 := 0;

    signal h_cnt_vec, v_cnt_vec : std_logic_vector(13 downto 0) := (others => '0');
    signal odd_row, odd_col : std_logic_vector(0 downto 0) := "0";

    signal red, grn, blu : std_logic_vector(7 downto 0) := (others => '0');
    
    type vert_markers_t is array(0 to 8) of integer range 0 to 16383;
    signal vert_markers : vert_markers_t := (0 => 0*v_active/8,
                                             1 => 1*v_active/8,
                                             2 => 2*v_active/8,
                                             3 => 3*v_active/8,
                                             4 => 4*v_active/8,
                                             5 => 5*v_active/8,
                                             6 => 6*v_active/8,
                                             7 => 7*v_active/8,
                                             8 =>   v_active
    );
    type horz_markers_t is array(0 to 8) of integer range 0 to 16383;
    signal horz_markers : horz_markers_t := (0 => 0*h_active/8,
                                             1 => 1*h_active/8,
                                             2 => 2*h_active/8,
                                             3 => 3*h_active/8,
                                             4 => 4*h_active/8,
                                             5 => 5*h_active/8,
                                             6 => 6*h_active/8,
                                             7 => 7*h_active/8,
                                             8 =>   h_active
    );

    signal horz_red, horz_blu, horz_grn : std_logic_vector(7 downto 0) := (others => '0');
    signal vert_red, vert_blu, vert_grn : std_logic_vector(7 downto 0) := (others => '0');
    
    signal img_red, img_blu, img_grn : std_logic_vector(7 downto 0) := (others => '0');
    signal img_rgb : std_logic_vector(23 downto 0) := (others => '0');
    
    signal pixel_cnt : integer := 0;
    signal pixel_cnt_vec : std_logic_vector(23 downto 0) := (others => '0');
    signal valid_pre, sof_pre, eol_pre : std_logic := '0';

    signal img_read : std_logic := '0';
    signal img_read_en : std_logic := '0';
    signal file_sync  : std_logic := '0';

    signal sof_dly, valid_dly, eol_dly : std_logic := '0';
    
    signal href_pre, href_dly : std_logic := '0';
    signal vsync_pre, vsync_dly : std_logic := '0';
    
    signal vid_red, vid_blu, vid_grn : std_logic_vector(7 downto 0) := (others => '0');
    signal vid_rgb : std_logic_vector(23 downto 0) := (others => '0');
    
    signal vid_read_en : std_logic := '0';
    
    signal vid_read_cnt : integer := 0;
    
    file img_file : text;-- open read_mode is i_file;
    signal sync_dly : std_logic := '0';

    type img_file_t is file of integer;
    
    signal vid_rgb_dly : std_logic_vector(23 downto 0) := (others => '0');
    
    signal odd_row_dly, odd_col_dly : std_logic_vector(0 downto 0) := (others => '0');
    signal odd_row_x, odd_col_x : std_logic_vector(0 downto 0) := (others => '0');
    
begin

    --use blanking or don't
    h_cmp <= h_total when USE_BLANKING = true else h_active;
    v_cmp <= v_total when USE_BLANKING = true else v_active;
    
    --vga counting
    process(clk)
    begin
        if(rising_edge(clk)) then

            if(enable = '1') then
                if(h_cnt = h_cmp-1) then
                    h_cnt <= 0;
                    if(v_cnt = v_cmp-1) then
                        v_cnt <= 0;
                    else
                        v_cnt <= v_cnt + 1;
                    end if;
                else
                    h_cnt <= h_cnt + 1;
                end if;
            else
                h_cnt <= 0;
                v_cnt <= 0;
            end if;
     
        end if;
    end process;
    
    --frame movement updates
    process(clk)
        file data_in : text;
        variable file_status : file_open_status;
        variable img_line : line;
        variable img_value : integer;
    begin
        if(rising_edge(clk)) then

            if(enable = '1') then
            
                if(h_cnt = 0 and v_cnt = 0 and pattern = "10") then
                    file_sync <= '1';
                end if;
                if(h_cnt = h_active-1 and v_cnt = v_active-1 and pattern = "10") then
                    file_sync <= '0';
                end if;
                
                if(h_cnt < h_active and v_cnt < v_active and pattern = "10") then
                    img_read_en <= '1';
                else
                    img_read_en <= '0';
                end if;
            
                if(pattern = "11" and vid_read_cnt = 0) then
                    file_close(data_in);
                    file_open(file_status,data_in,v_file,read_mode);
                end if;
            
                if(h_cnt < h_active and v_cnt < v_active and pattern = "11" and vid_read_cnt /= (h_active*v_active*num_images)-1) then

                    readline(data_in, img_line);
                    read(img_line, img_value);
                    vid_rgb <= std_logic_vector(to_unsigned(img_value,24));
                    vid_read_cnt <= vid_read_cnt + 1;
                else
                    vid_rgb <= (others => '0');
                end if;
                
                if(vid_read_cnt = h_active*v_active*num_images-1) then
                    file_close(data_in);
                end if;
                
                --this condition signals the last pixel in the frame
                if(h_cnt = h_active-1 and v_cnt = v_active-1) then
                

                    if(movement = '1') then
                        --move the markers around
                        for i in 0 to 8 loop
                            if(horz_markers(i) = h_active) then
                                horz_markers(i) <= 0;
                            else
                                horz_markers(i) <= horz_markers(i) + 1;
                            end if;
                            
                            if(vert_markers(i) = v_active) then
                                vert_markers(i) <= 0;
                            else
                                vert_markers(i) <= vert_markers(i) + 1;
                            end if;
                            
                        end loop;
                        
                        
                    end if;
                   
                end if;
            else
                file_sync   <= '0';
                img_read_en <= '0';
                vid_read_cnt <= 0;
            end if;       
     
        end if;
    end process;

    --pixel reading from image file
    GEN_IMG : if(USE_IMG_FILE = true) generate
    
        --img_read_en <= '1' when (h_cnt < h_active and v_cnt < v_active and pattern = "10" and enable = '1') else '0';
    
        img_reader_inst : entity work.image_reader
        port map(
            clk    => clk,
            i_file => i_file,
            sync   => file_sync,
            enable => img_read_en,
            rgb    => img_rgb

        );
    
    end generate GEN_IMG;

    --pixel determination for movement
    process(clk)
    begin
        if(rising_edge(clk)) then
    
            --vertical color bars
            if(((h_cnt >= horz_markers(0) and h_cnt < horz_markers(1)) and horz_markers(1) > horz_markers(0)) or
               ((h_cnt >= horz_markers(0) or  h_cnt < horz_markers(1)) and horz_markers(1) < horz_markers(0))) then
                --white
                vert_red <= (others => '1');
                vert_grn <= (others => '1');
                vert_blu <= (others => '1');
            elsif(((h_cnt >= horz_markers(1) and h_cnt < horz_markers(2)) and horz_markers(2) > horz_markers(1)) or
                  ((h_cnt >= horz_markers(1) or  h_cnt < horz_markers(2)) and horz_markers(2) < horz_markers(1))) then
                --yellow
                vert_red <= (others => '1');
                vert_grn <= (others => '1');
                vert_blu <= (others => '0');
            elsif(((h_cnt >= horz_markers(2) and h_cnt < horz_markers(3)) and horz_markers(3) > horz_markers(2)) or
                  ((h_cnt >= horz_markers(2) or  h_cnt < horz_markers(3)) and horz_markers(3) < horz_markers(2))) then
                --cyan
                vert_red <= (others => '0');
                vert_grn <= (others => '1');
                vert_blu <= (others => '1');
            elsif(((h_cnt >= horz_markers(3) and h_cnt < horz_markers(4)) and horz_markers(4) > horz_markers(3)) or
                  ((h_cnt >= horz_markers(3) or  h_cnt < horz_markers(4)) and horz_markers(4) < horz_markers(3))) then
                --green
                vert_red <= (others => '0');
                vert_grn <= (others => '1');
                vert_blu <= (others => '0');
            elsif(((h_cnt >= horz_markers(4) and h_cnt < horz_markers(5)) and horz_markers(5) > horz_markers(4)) or
                  ((h_cnt >= horz_markers(4) or  h_cnt < horz_markers(5)) and horz_markers(5) < horz_markers(4))) then
                --purple
                vert_red <= (others => '1');
                vert_grn <= (others => '0');
                vert_blu <= (others => '1');
            elsif(((h_cnt >= horz_markers(5) and h_cnt < horz_markers(6)) and horz_markers(6) > horz_markers(5)) or
                  ((h_cnt >= horz_markers(5) or  h_cnt < horz_markers(6)) and horz_markers(6) < horz_markers(5))) then
                --red
                vert_red <= (others => '1');
                vert_grn <= (others => '0');
                vert_blu <= (others => '0');
            elsif(((h_cnt >= horz_markers(6) and h_cnt < horz_markers(7)) and horz_markers(7) > horz_markers(6)) or
                  ((h_cnt >= horz_markers(6) or  h_cnt < horz_markers(7)) and horz_markers(7) < horz_markers(6))) then
                --blue
                vert_red <= (others => '0');
                vert_grn <= (others => '0');
                vert_blu <= (others => '1');
            else
                --black
                vert_red <= (others => '0');
                vert_grn <= (others => '0');
                vert_blu <= (others => '0');
            end if;
            
            --horizontal color bars
            if(((v_cnt >= vert_markers(0) and v_cnt < vert_markers(1)) and vert_markers(1) > vert_markers(0)) or
                  ((v_cnt >= vert_markers(0) or  v_cnt < vert_markers(1)) and vert_markers(1) < vert_markers(0))) then
                --white
                horz_red <= (others => '1');
                horz_grn <= (others => '1');
                horz_blu <= (others => '1');
            elsif(((v_cnt >= vert_markers(1) and v_cnt < vert_markers(2)) and vert_markers(2) > vert_markers(1)) or
                  ((v_cnt >= vert_markers(1) or  v_cnt < vert_markers(2)) and vert_markers(2) < vert_markers(1))) then
                --yellow
                horz_red <= (others => '1');
                horz_grn <= (others => '1');
                horz_blu <= (others => '0');
            elsif(((v_cnt >= vert_markers(2) and v_cnt < vert_markers(3)) and vert_markers(3) > vert_markers(2)) or
                  ((v_cnt >= vert_markers(2) or  v_cnt < vert_markers(3)) and vert_markers(3) < vert_markers(2))) then
                --cyan
                horz_red <= (others => '0');
                horz_grn <= (others => '1');
                horz_blu <= (others => '1');
            elsif(((v_cnt >= vert_markers(3) and v_cnt < vert_markers(4)) and vert_markers(4) > vert_markers(3)) or
                  ((v_cnt >= vert_markers(3) or  v_cnt < vert_markers(4)) and vert_markers(4) < vert_markers(3))) then
                --green
                horz_red <= (others => '0');
                horz_grn <= (others => '1');
                horz_blu <= (others => '0');
            elsif(((v_cnt >= vert_markers(4) and v_cnt < vert_markers(5)) and vert_markers(5) > vert_markers(4)) or
                  ((v_cnt >= vert_markers(4) or  v_cnt < vert_markers(5)) and vert_markers(5) < vert_markers(4))) then
                --purple
                horz_red <= (others => '1');
                horz_grn <= (others => '0');
                horz_blu <= (others => '1');
            elsif(((v_cnt >= vert_markers(5) and v_cnt < vert_markers(6)) and vert_markers(6) > vert_markers(5)) or
                  ((v_cnt >= vert_markers(5) or  v_cnt < vert_markers(6)) and vert_markers(6) < vert_markers(5))) then
                --red
                horz_red <= (others => '1');
                horz_grn <= (others => '0');
                horz_blu <= (others => '0');
            elsif(((v_cnt >= vert_markers(6) and v_cnt < vert_markers(7)) and vert_markers(7) > vert_markers(6)) or
                  ((v_cnt >= vert_markers(6) or  v_cnt < vert_markers(7)) and vert_markers(7) < vert_markers(6))) then
                --blue
                horz_red <= (others => '0');
                horz_grn <= (others => '0');
                horz_blu <= (others => '1');
            else
                --black
                horz_red <= (others => '0');
                horz_grn <= (others => '0');
                horz_blu <= (others => '0');
            end if;
            
        end if;
    end process;
	
    --generate stream signals
    process(clk)

    begin
        if(rising_edge(clk)) then
            
            sof_pre <= '0';
            eol_pre <= '0';
            valid_pre <= '0';
            
            href_pre <= '0';
            vsync_pre <= '0';
            
            if(enable = '1') then

                if(h_cnt < h_active and v_cnt < v_active) then
                    href_pre <= '1';
                end if;

                if(v_cnt = v_sync_spot) then
                    vsync_pre <= '1';
                end if;

            
                if(h_cnt = h_active-1 and v_cnt < v_active) then
                    eol_pre <= '1';
                end if;
            
                if(h_cnt < h_active and v_cnt < v_active) then
                    valid_pre <= '1';
                    pixel_cnt <= pixel_cnt + 1;

                end if;
                
                if(h_cnt = 0 and v_cnt = 0) then
                    sof_pre <= '1';
                    pixel_cnt <= 0;
                end if;
                
            
                
            end if;
            
            h_cnt_vec <= std_logic_vector(to_unsigned(h_cnt,h_cnt_vec'length));
            v_cnt_vec <= std_logic_vector(to_unsigned(v_cnt,v_cnt_vec'length));

        end if;
    end process;
    

    
    img_red <= img_rgb(23 downto 16);
    img_grn <= img_rgb(15 downto 8);
    img_blu <= img_rgb(7 downto 0);
    
    vid_red <= vid_rgb_dly(23 downto 16);
    vid_grn <= vid_rgb_dly(15 downto 8);
    vid_blu <= vid_rgb_dly(7 downto 0);
    
    
    pixel_cnt_vec <= std_logic_vector(to_unsigned(pixel_cnt,24));
    
    --setup rgb and stream outputs
    process(clk)
    begin
        if(rising_edge(clk)) then
        
            vid_rgb_dly <= vid_rgb;
        
            sof_dly <= sof_pre;
            eol_dly <= eol_pre;
            valid_dly <= valid_pre;
            
            href_dly <= href_pre;
            vsync_dly <= vsync_pre;
            
            
            
            if(pattern = "01" or pattern = "00") then
                sof <= sof_pre;
                eol <= eol_pre;
                valid <= valid_pre;
                
                href <= href_pre;
                vsync <= vsync_pre;
                
            else
                sof <= sof_dly;
                eol <= eol_dly;
                valid <= valid_dly;
                
                href <= href_dly;
                vsync <= vsync_dly;
                
            end if;
        
            --designators for determining bayer filter data
            odd_row_x <= v_cnt_vec(0 downto 0);
            odd_col_x <= h_cnt_vec(0 downto 0);
            
            odd_row_dly <= odd_row_x;
            odd_col_dly <= odd_col_x;
        
            case pattern is
            when "00" =>
                red <= vert_red;
                blu <= vert_blu;
                grn <= vert_grn;
            when "01" =>
                red <= horz_red;
                blu <= horz_blu;
                grn <= horz_grn;
            when "10" =>
                red <= img_red;
                blu <= img_blu;
                grn <= img_grn;
            when others =>
                red <= vid_red;
                blu <= vid_blu;
                grn <= vid_grn;
            end case;
        end if;
    
    end process;

    odd_row <= odd_row_x when (pattern = "00" or pattern = "01") else odd_row_dly;
    odd_col <= odd_col_x when (pattern = "00" or pattern = "01") else odd_col_dly;

    --setup raw outputs
    --possible setups for odds/evens:
    --[B G \ G R] 
    --[G B \ R G]
    --[G R \ B G]
    --[R G \ G B]
    process(red,grn,blu,odd_row,odd_col)
    begin
        if(odd_row = "0" and odd_col = "0") then
            raw_BGGR <= blu;
            raw_GBRG <= grn;
            raw_GRBG <= grn;
            raw_RGGB <= red;
        elsif(odd_row = "0" and odd_col = "1") then
            raw_BGGR <= grn;
            raw_GBRG <= blu;
            raw_GRBG <= red;
            raw_RGGB <= grn;
        elsif(odd_row = "1" and odd_col = "0") then
            raw_BGGR <= grn;
            raw_GBRG <= red;
            raw_GRBG <= blu;
            raw_RGGB <= grn;
        else
            raw_BGGR <= red;
            raw_GBRG <= grn;
            raw_GRBG <= grn;
            raw_RGGB <= blu;
        end if;
    end process;
    
    rgb <= red & grn & blu;

end arch;