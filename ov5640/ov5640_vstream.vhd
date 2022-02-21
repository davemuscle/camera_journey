library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Convert Camera Data to Video Stream 
--Camera Datapath Consists of:
--  HREF
--  VSYNC 
--  Data7:0

--Let VSYNC reset the count values and trigger the SOF
--Let the deactivation of HREF trigger the EOL

entity ov5640_vstream is
	generic(
        --default in camera registers are active low
        HREF_POLARITY  : std_logic := '0';
        VSYNC_POLARITY : std_logic := '0';
        h_active : integer := 0;
        v_active : integer := 0
	);
	port(
		clk     : in std_logic;
        reset   : in std_logic;
		vsync   : in std_logic;
        href    : in std_logic;
        data_in : in std_logic_vector(7 downto 0);
		line_err : out std_logic := '0';
        data_out : out std_logic_vector(7 downto 0);
		valid    : out std_logic := '0';
		sof      : out std_logic := '0';
		eol      : out std_logic := '0'
        
        );
end ov5640_vstream;

architecture arch of ov5640_vstream is 

    signal sof_enable : std_logic := '0';
    signal href_dly, vsync_dly : std_logic := '0';

    signal data_reg, data_dly : std_logic_vector(7 downto 0) := (others => '0');

    signal reset_sync, reset_meta : std_logic := '0';
    
    signal vsync_gate, href_gate : std_logic := '0';
    signal gate_cnt : integer range 0 to 50000000-1 := 0;
    
    signal vsync_falling, vsync_rising : std_logic := '0';
    
    signal sof_pre : std_logic := '0';
    
    signal h_count : integer range 0 to 4095 := 0;
    signal clk_gate : std_logic := '0';
   
    signal line_enable : std_logic := '0';
    
    signal vsync_cnt : integer range 0 to 15 := 0;
    
    signal h_count_mon1, h_count_mon2 : integer range 0 to 4095 := h_active;
    signal h_count_mon_error : std_logic := '0';
    
begin

    process(clk)
    begin
        if(rising_edge(clk)) then
        
            if(gate_cnt = 1024-1) then
                gate_cnt <= 1024-1;
                clk_gate <= '1';
            else
                gate_cnt <= gate_cnt + 1;
                clk_gate <= '0';
            end if;
        
            vsync_dly <= vsync;
            href_dly  <= href;
  
            --wait for a vsync to gate the href
            if(vsync = not VSYNC_POLARITY and vsync_dly = VSYNC_POLARITY and clk_gate = '1') then
                sof_enable <= '1';
                if(vsync_cnt = 2) then
                    vsync_cnt <= 2;
                    vsync_gate <= '1';
                else
                    vsync_cnt <= vsync_cnt + 1;
                end if;
            end if;
  
            sof <= '0';
            eol <= '0';
            valid <= '0';

            data_reg <= data_in;
            data_out <= data_reg;

            if(vsync_gate = '1') then
                --monitor the counts
                if(href_dly = not HREF_POLARITY and href = HREF_POLARITY) then
                
                    line_enable <= '1';
                    h_count <= 0;
                
                    h_count_mon2 <= h_count_mon1;
                    h_count_mon1 <= 0;
                    if(h_count_mon1 /= h_count_mon2) then
                        h_count_mon_error <= '1';
                    else
                        h_count_mon_error <= '0';
                    end if;
                end if;
                
                if(href_dly = HREF_POLARITY and line_enable = '1') then
                    
                    if(h_count_mon1 = 4095) then
                        h_count_mon1 <= 0;
                    else
                        h_count_mon1 <= h_count_mon1 + 1;
                    end if;

                    
                    if(h_count = h_active-1) then
                        h_count <= 0;
                        eol <= '1';
                        line_enable <= '0';
                    else
                        h_count <= h_count+1;
                    end if;
                    
                    if(h_count = 0 and sof_enable = '1') then
                        sof_enable <= '0';
                        sof <= '1';
                    end if;
                    
                    valid <= '1';
                end if;
                
                
            end if;

            
            reset_meta <= reset;
            reset_sync <= reset_meta;
            
            if(reset_sync = '1') then
                h_count <= 0;
                eol <= '0';
                sof <= '0';
                line_enable <= '0';
                valid <= '0';
                sof_enable <= '0';
                vsync_gate <= '0';
                vsync_cnt <= 0;
                gate_cnt <= 0;
                clk_gate <= '0';
                vsync_dly <= '0';
                href_dly <= '0';
            end if;
        
        end if;
    end process;

    line_err <= h_count_mon_error;

end arch;