library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

--Multi-bit vector mux sync between cross domains
--Meant for slow control signals

entity vector_mux_sync is
    generic(
        DATA_WIDTH : integer := 32;
    );
	port(
        valid_a : in  std_logic;                                -- async to clk_b
        data_a  : in  std_logic_vector(DATA_WIDTH-1 downto 0);  -- async to clk_b
        clk_b   : in  std_logic;
        valid_b : out std_logic := '0';
        data_b  : out std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0')
	);
end vector_mux_sync;

architecture bhv of vector_mux_sync is 
    signal valid_a_b1  : std_logic := '0';
    signal valid_a_b2  : std_logic := '0';
	signal data_recirc : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
begin
    --Destination Domain
    process(clk_b)
    begin
        if(rising_edge(clk_b)) then
            valid_a_b1 <= valid_a;
            valid_a_b2 <= valid_a_b2;
            if(valid_a_b2 = '1') then
                data_recirc <= data_a;
            else
                data_recirc <= data_recirc;
            end if;       
            valid_b <= valid_a_b2;
        end if;
    end process;
    data_b <= data_recirc;
end bhv;		

