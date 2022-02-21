library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Dave Muscle
--Converts video stream to DVP stream

--Vsync = active low
--Href = active high

entity stream2dvp is
    generic(
        DATA_WIDTH : integer := 8
    );
	port(
		clk      : in std_logic;
		reset    : in std_logic;
        
        sof_i  : in std_logic;
        eol_i  : in std_logic;
        vld_i  : in std_logic;
        data_i : in std_logic_vector(DATA_WIDTH-1 downto 0);
        
        href_o  : out std_logic := '0';
        vsync_o : out std_logic := '1';
        data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0')
        
    );
end stream2dvp;

architecture arch of stream2dvp is 

    signal internal_en : std_logic := '0';
    
    signal vld_dly : std_logic_vector(3 downto 0) := (others => '0');
    
    type data_array_t is array(0 to 3) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal data_dly : data_array_t := (others => (others => '0'));
    
begin

    process(clk)
    begin
        if(rising_edge(clk)) then

            
            vsync_o <= not sof_i;
            if(sof_i = '1') then
                internal_en <= '1';
            end if;
            
            vld_dly(0)  <= vld_i;
            data_dly(0) <= data_i;
            
            for i in 1 to 3 loop
                vld_dly(i)  <= vld_dly(i-1);
                data_dly(i) <= data_dly(i-1);
            end loop;
            
            data_o <= data_dly(3);
            
            if(internal_en = '1') then
                href_o <= vld_dly(3);
            end if;
            
            if(reset = '1') then
                href_o      <= '0';
                vsync_o     <= '1';
                internal_en <= '0';
            end if;
            
        end if;
    end process;

end arch;