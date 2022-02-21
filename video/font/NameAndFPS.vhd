library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
--Dave Muscle

--Writes my name and some other info on the screen, as well as the FPS
--This code should be dumb and slow, as long as the msg_wr signal is timed correctly with msg_datas

use work.text_overlay_font_pkg.all;

entity NameAndFPS is
	port(
	    clk     : in std_logic;
		reset   : in std_logic;

        fps     : in integer;

        msg_wr   : out std_logic := '0';
        msg_sel  : out integer := 0;
        msg_data : out std_logic_vector(7 downto 0) := (others => '0');
        msg_h    : out integer := 0;
        msg_v    : out integer := 0
	
        );
end NameAndFPS;

architecture arch of NameAndFPS is 

    
    signal cnt : integer := 0;
    
    constant FPSString : string := "FPS: "; --5 char
    constant NameString : string := "Dave Muscle"; --11 char
    constant ProjectString : string := "Camera App"; --10 char
    constant DateString : string := "12/31/20"; --8 char
    
    signal fps_prev : integer := 0;
    
    signal   fps_byte1 : std_logic_vector(7 downto 0) := (others => '0');
    signal   fps_byte2 : std_logic_vector(7 downto 0) := (others => '0');
    constant one_over_ten : std_logic_vector(5+8-1 downto 0) := (0 => '1', 1 => '1', others => '0'); --3/32 ~ 0.1
    
        signal fps_in_vec_t    : std_logic_vector(7 downto 0);
        signal fps_fx_t        : std_logic_vector(8+5-1 downto 0);
        signal fps_mult_t      : std_logic_vector(2*(5+8)-1 downto 0);
        signal fps_b1_t,fps_b2_t : std_logic_vector(7 downto 0);
        signal fps_b1x10_t     : std_logic_vector(15 downto 0);
        signal fps_dec_t, fps_top_nib_t, fps_bot_nib_t : std_logic_vector(7 downto 0);
        signal fps_bot_dif_t : std_logic_vector(7 downto 0);
    
    constant msg_len : integer := 42+2+4;
    signal msg_cnt : integer := 0;
    signal msg_en : std_logic := '0';
    
    type msg_array_t is array(0 to msg_len-1) of std_logic_vector(7 downto 0);
    constant msg_array : msg_array_t := (
        0  => x"01",
        1  => std_logic_vector(to_unsigned(natural(character'pos('F')),8)),
        2  => std_logic_vector(to_unsigned(natural(character'pos('P')),8)),
        3  => std_logic_vector(to_unsigned(natural(character'pos('S')),8)),
        4  => std_logic_vector(to_unsigned(natural(character'pos(':')),8)),
        5  => std_logic_vector(to_unsigned(natural(character'pos(' ')),8)),
        6  => std_logic_vector(to_unsigned(natural(character'pos(' ')),8)),
        7  => std_logic_vector(to_unsigned(natural(character'pos(' ')),8)),
        8  => x"03",
        9  => x"00",
        10 => x"01",
        11 => std_logic_vector(to_unsigned(natural(character'pos('D')),8)),
        12 => std_logic_vector(to_unsigned(natural(character'pos('a')),8)),
        13 => std_logic_vector(to_unsigned(natural(character'pos('v')),8)),
        14 => std_logic_vector(to_unsigned(natural(character'pos('e')),8)),
        15 => std_logic_vector(to_unsigned(natural(character'pos(' ')),8)),
        16 => std_logic_vector(to_unsigned(natural(character'pos('M')),8)),
        17 => std_logic_vector(to_unsigned(natural(character'pos('u')),8)),
        18 => std_logic_vector(to_unsigned(natural(character'pos('s')),8)),
        19 => std_logic_vector(to_unsigned(natural(character'pos('c')),8)),
        20 => std_logic_vector(to_unsigned(natural(character'pos('l')),8)),
        21 => std_logic_vector(to_unsigned(natural(character'pos('e')),8)),
        22 => x"03",
        23 => x"00",
        24 => x"01",
        25 => std_logic_vector(to_unsigned(natural(character'pos('C')),8)),
        26 => std_logic_vector(to_unsigned(natural(character'pos('a')),8)),
        27 => std_logic_vector(to_unsigned(natural(character'pos('m')),8)),
        28 => std_logic_vector(to_unsigned(natural(character'pos('e')),8)),
        29 => std_logic_vector(to_unsigned(natural(character'pos('r')),8)),
        30 => std_logic_vector(to_unsigned(natural(character'pos('a')),8)),
        31 => std_logic_vector(to_unsigned(natural(character'pos(' ')),8)),
        32 => std_logic_vector(to_unsigned(natural(character'pos('A')),8)),
        33 => std_logic_vector(to_unsigned(natural(character'pos('p')),8)),
        34 => std_logic_vector(to_unsigned(natural(character'pos('p')),8)),
        35 => x"03",
        36 => x"00",
        37 => x"01",
        38 => std_logic_vector(to_unsigned(natural(character'pos('1')),8)),
        39 => std_logic_vector(to_unsigned(natural(character'pos('2')),8)),
        40 => std_logic_vector(to_unsigned(natural(character'pos('/')),8)),
        41 => std_logic_vector(to_unsigned(natural(character'pos('3')),8)),
        42 => std_logic_vector(to_unsigned(natural(character'pos('1')),8)),
        43 => std_logic_vector(to_unsigned(natural(character'pos('/')),8)),
        44 => std_logic_vector(to_unsigned(natural(character'pos('2')),8)),
        45 => std_logic_vector(to_unsigned(natural(character'pos('0')),8)),
        46 => x"03",
        47 => x"00"
    
    );
        
begin	
    --combinatorial because i don't care about the timing
    process(fps)
        variable fps_dec       : std_logic_vector(7 downto 0);
        variable fps_top_nib   : std_logic_vector(7 downto 0);
        variable fps_bot_nib   : std_logic_vector(7 downto 0);
        variable fps_bot_dif   : std_logic_vector(7 downto 0);
        variable fps_in_vec    : std_logic_vector(7 downto 0);
        variable fps_fx        : std_logic_vector(8+5-1 downto 0);
        variable fps_mult      : std_logic_vector(2*(5+8)-1 downto 0);
        variable fps_b1,fps_b2 : std_logic_vector(7 downto 0);
        variable fps_b1x10     : std_logic_vector(15 downto 0);
    begin

        fps_in_vec := std_logic_vector(to_unsigned(fps,fps_in_vec'length));        
        fps_fx := fps_in_vec & "00000";
        fps_mult := std_logic_vector(unsigned(fps_fx)*unsigned(one_over_ten));
        fps_b1 := fps_mult(10+8-1 downto 10);
        fps_b1x10 := std_logic_vector(unsigned(fps_b1)*to_unsigned(10,8));
        fps_b2 := std_logic_vector(unsigned(fps_in_vec)-unsigned(fps_b1x10(7 downto 0)));
        fps_bot_dif := std_logic_vector(unsigned(fps_b2)-to_unsigned(10,8));
        if(fps_b2 > x"09") then
            fps_b2 := fps_bot_dif;
            fps_b1 := std_logic_vector(unsigned(fps_b1)+1);
        end if;
        
        fps_byte1 <= fps_b1;
        fps_byte2 <= fps_b2;
        
    end process;

    process(clk)
        variable char_t : integer;
    begin
        if(rising_edge(clk)) then
    
            fps_prev <= fps;
    
            if(cnt = 5000) then
                cnt <= 5000;
            else
                cnt <= cnt + 1;
            end if;
            
            --start 
            if(cnt = 10 or fps_prev /= fps) then
                msg_en <= '1';
                msg_cnt <= 0;
            end if;
    
            if(msg_en = '1') then
                msg_wr <= '1';
                msg_data <= msg_array(msg_cnt);
                case msg_cnt is
                when 0 =>
                    msg_h <= 0;
                    msg_v <= 0;
                    msg_sel <= 0;
                when 6 =>
                    if(fps_byte1 = x"00") then
                        msg_data <= x"20"; --space 
                    else
                        msg_data <= fps_byte1 or x"30";
                    end if;
                when 7 =>
                    msg_data <= fps_byte2 or x"30";
                when 9 =>
                    msg_wr <= '0';
                when 10 =>
                    msg_h <= 0;
                    msg_v <= CHAR_HEIGHT-1;
                    msg_sel <= 1;
                when 23 =>
                    msg_wr <= '0';
                when 24 =>
                    msg_h <= 0;
                    msg_v <= 2*CHAR_HEIGHT-2;
                    msg_sel <= 2;
                when 36 =>
                    msg_wr <= '0';
                when 37 =>
                    msg_h <= 0;
                    msg_v <= 3*CHAR_HEIGHT-3;
                    msg_sel <= 3;
                when 47 =>
                    msg_wr <= '0';
                when others =>

                end case;
                if(msg_cnt = msg_len-1) then
                    msg_en <= '0';
                else
                    msg_cnt <= msg_cnt + 1;
                end if;
            end if;
    
    
            if(reset = '1') then
                msg_en <= '0';
                cnt <= 0;
                msg_wr <= '0';
                msg_cnt <= 0;
            end if;
    
        end if;
    end process;
    
end arch;
