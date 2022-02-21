library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Dave Muscle

--Video Timing Generator
--12 bit vectors for screen width
--Meant to be as the main timing controller for a video system
--Eg: Use the SOF, EOL, and valid signals to drive and sync video modules

entity video_timing_generator is
    generic(
        H_ACTIVE : integer := 1920;
        H_TOTAL  : integer := 2200;
        V_ACTIVE : integer := 1080;
        V_TOTAL  : integer := 1125
    );
	port(
		clk      : in std_logic;
		enable   : in std_logic;
        
        sof : out std_logic := '0';
        eol : out std_logic := '0';
        vld : out std_logic := '0'
    );
end video_timing_generator;

architecture arch of video_timing_generator is 
    
    signal h_cnt : unsigned(11 downto 0) := (others => '0');
    signal v_cnt : unsigned(11 downto 0) := (others => '0');

    constant U_H_ACTIVE : unsigned(11 downto 0) := to_unsigned(H_ACTIVE - 1, 12);
    constant U_H_TOTAL  : unsigned(11 downto 0) := to_unsigned(H_TOTAL  - 1, 12);
    constant U_V_ACTIVE : unsigned(11 downto 0) := to_unsigned(V_ACTIVE - 1, 12);
    constant U_V_TOTAL  : unsigned(11 downto 0) := to_unsigned(V_TOTAL  - 1, 12);

begin

    process(clk)
    begin
        if(rising_edge(clk)) then
            --defaults
            sof   <= '0';
            eol   <= '0';
            vld   <= '0';
            --counters
            if(enable = '1') then
                --screen counting
                if(h_cnt = U_H_TOTAL) then
                    h_cnt <= (others => '0');
                    if(v_cnt = U_V_TOTAL) then
                        v_cnt <= (others => '0');
                    else
                        v_cnt <= v_cnt+1;
                    end if;
                else
                    h_cnt <= h_cnt+1;
                end if;
                --eol generation
                if(h_cnt = U_H_ACTIVE and v_cnt <= U_V_ACTIVE) then
                    eol <= '1';
                end if;
                --sof generation
                if(h_cnt = x"000" and v_cnt = x"000") then
                    sof <= '1';
                end if;
                --valid generation
                if(h_cnt <= U_H_ACTIVE and v_cnt <= U_V_ACTIVE) then
                    vld <= '1';
                end if;
            else
                h_cnt <= (others => '0');
                v_cnt <= (others => '0');
            end if;
        end if;
    end process;

end arch;