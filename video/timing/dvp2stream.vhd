library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Dave Muscle
--Convert DVP to video stream

entity dvp2stream is
	generic(
        --default in camera registers are active low
        DATA_WIDTH : integer := 8;
        FRAMES_TO_LOCK : integer := 4
	);
	port(
		clk     : in std_logic;
        reset   : in std_logic;
        
		href_i  : in std_logic;
        vsync_i : in std_logic;
        data_i  : in std_logic_vector(DATA_WIDTH-1 downto 0);
        
        sof_o   : out std_logic := '0';
        eol_o   : out std_logic := '0';
        vld_o   : out std_logic := '0';
        data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0')
        
        );
end dvp2stream;

architecture arch of dvp2stream is 

    signal internal_en  : std_logic_vector(FRAMES_TO_LOCK-1 downto 0) := (others => '0');
    signal sof_seen     : std_logic := '0';
    signal href_dly     : std_logic := '0';
    signal href_dly2    : std_logic := '0';
    signal vsync_dly    : std_logic := '1';
    signal data_reg     : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if(rising_edge(clk)) then
        
            href_dly  <= href_i;
            href_dly2 <= href_dly;
            
            vsync_dly <= vsync_i;
            
            sof_o <= '0';
            
            data_reg <= data_i;
            data_o <= data_reg;
        
            if(vsync_dly = '1' and vsync_i = '0') then
                internal_en <= internal_en(FRAMES_TO_LOCK-2 downto 0) & '1'; 
                sof_seen     <= '1';
            end if;
        
            if(href_dly2 = '0' and href_dly = '1' and internal_en(FRAMES_TO_LOCK-1) = '1') then
                sof_seen <= '0';
                if(sof_seen = '1') then
                    sof_o <= '1';
                end if;
            end if;
            
            if(internal_en(FRAMES_TO_LOCK-1) = '1') then
                vld_o <= href_dly;
            else
                vld_o <= '0';
            end if;
            
            eol_o <= '0';
            if(href_dly = '1' and href_i = '0') then
                eol_o <= '1';
            end if;
            
            if(reset = '1') then
                eol_o <= '0';
                sof_o <= '0';
                vld_o <= '0';
                internal_en <= (others => '0');
                sof_seen <= '0';
            end if;
            
        end if;
    end process;


end arch;