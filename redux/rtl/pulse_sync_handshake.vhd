library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

--Handshake Based Pulse Synchronizer
--From edn.com, "synchronizer techniques for multi clock domain socs fpgas"

--Pulse on clk domain A gets sync'd to clk domain B

entity pulse_sync_handshake is
	port(
		clk_a   : in  std_logic;
        pulse_a : in  std_logic;
        busy_a  : out std_logic := '0';
        clk_b   : in  std_logic;
        pulse_b : out std_logic := '0'
	);
end pulse_sync_handshake;

architecture bhv of pulse_sync_handshake is 
    
    signal a1 : std_logic := '0';
    signal a2 : std_logic := '0';
    signal a3 : std_logic := '0';
    signal b1 : std_logic := '0';
    signal b2 : std_logic := '0';
    signal b3 : std_logic := '0';
	
begin
    --Source Domain
    process(clk_a)
    begin
        if(rising_edge(clk_a)) then
            if(pulse_a = '1') then
                a1 <= '1';
            else
                if(a3 = '1') then
                    a1 <= '0';
                else
                    a1 <= a1;
                end if;
            end if;
            a2 <= b2;
            a3 <= a2;
            busy_a <= a3 or a1;
        end if;
    end process;
    --Destination Domain
    process(clk_b)
    begin
        if(rising_edge(clk_b)) then
            b1 <= a1;
            b2 <= b1;
            b3 <= b2;
            pulse_b <= b2 and not b3;
        end if;
    end process;
end bhv;		

