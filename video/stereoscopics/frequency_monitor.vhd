library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
--Dave Muscle

--Measure frequency of a toggling signal

entity frequency_monitor is
    generic(
        REFCLK_CNT_MAX : integer := 10
        );
	port(
        refclk : in  std_logic;
        clk_a  : in  std_logic;
        clk_b  : in  std_logic;
        frq_a  : out std_logic_vector(31 downto 0) := (others => '0'); --refclk domain
        frq_b  : out std_logic_vector(31 downto 0) := (others => '0')  --refclk domain
        );
end frequency_monitor;

architecture arch of frequency_monitor is 

    signal refclk_cnt : unsigned(31 downto 0) := (others => '0');
    signal clk_a_cnt  : unsigned(31 downto 0) := (others => '0');
    signal clk_b_cnt  : unsigned(31 downto 0) := (others => '0');
    
    signal clk_a_cnt_l  : unsigned(31 downto 0) := (others => '0');
    signal clk_b_cnt_l  : unsigned(31 downto 0) := (others => '0');
    
    signal reload : std_logic := '0';
    signal reload_a : std_logic := '0';
    signal reload_b : std_logic := '0';
    
    signal done_a : std_logic := '0';
    signal done_b : std_logic := '0';
    
    signal vld_a : std_logic := '0';
    signal vld_b : std_logic := '0';
    
begin

    process(refclk)
    begin
        if(rising_edge(refclk)) then   
            reload <= '0';
            if(refclk_cnt >= to_unsigned(REFCLK_CNT_MAX-1,32)) then
                reload <= '1';
                refclk_cnt <= (others => '0');
            else
                refclk_cnt <= refclk_cnt + 1;
            end if;     
            if(vld_a = '1') then
                frq_a <= std_logic_vector(clk_a_cnt_l);
            end if;
            if(vld_b = '1') then
                frq_b <= std_logic_vector(clk_b_cnt_l);
            end if;
        end if;
    end process;
    
    process(clk_a)
    begin
        if(rising_edge(clk_a)) then
            done_a <= '0';
            if(reload_a = '1') then
                done_a <= '1';
                clk_a_cnt_l <= clk_a_cnt;
                clk_a_cnt <= (others => '0');
            else
                clk_a_cnt <= clk_a_cnt + 1;
            end if;
        end if;
    end process;
    
    process(clk_b)
    begin
        if(rising_edge(clk_b)) then
            done_b <= '0';
            if(reload_b = '1') then
                done_b <= '1';
                clk_b_cnt_l <= clk_b_cnt;
                clk_b_cnt <= (others => '0');
            else
                clk_b_cnt <= clk_b_cnt + 1;
            end if;
        end if;
    end process;
    
	sync1 : entity work.pulse_sync_handshake
	port map(
		clk_a   => refclk,
        pulse_a => reload,
        busy_a  => open,
        clk_b   => clk_a,
        pulse_b => reload_a
	);
    
	sync2 : entity work.pulse_sync_handshake
	port map(
		clk_a   => refclk,
        pulse_a => reload,
        busy_a  => open,
        clk_b   => clk_b,
        pulse_b => reload_b
	);
    
	sync3 : entity work.pulse_sync_handshake
	port map(
		clk_a   => clk_a,
        pulse_a => done_a,
        busy_a  => open,
        clk_b   => refclk,
        pulse_b => vld_a
	);
    
	sync4 : entity work.pulse_sync_handshake
	port map(
		clk_a   => clk_b,
        pulse_a => done_b,
        busy_a  => open,
        clk_b   => refclk,
        pulse_b => vld_b
	);
    
    
    
end arch;
