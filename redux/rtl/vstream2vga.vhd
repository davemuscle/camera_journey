library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Converts a (axi) video stream to VGA interface sync markers 
--This is to be used at the end of the video pipeline

entity vstream2vga is
	generic(
		DATA_WIDTH   : integer   := 8;
		SYNC_POL     : std_logic := '0';
	    h_active 	 : integer   := 1920;
	    h_frontporch : integer   := 88;
	    h_syncwidth  : integer   := 44;
	    h_backporch  : integer   := 148;
	    h_total      : integer   := 2200;
	    v_active     : integer   := 1080;
	    v_frontporch : integer   := 4;
	    v_syncwidth  : integer   := 5;
	    v_backporch  : integer   := 36;
	    v_total		 : integer   := 1125
	);
	port(
		clk   : in std_logic;
		reset : in std_logic;
		
		--input data
		data_in  : in std_logic_vector(DATA_WIDTH-1 downto 0);
		valid_in : in std_logic;
		sof_in   : in std_logic;
		eol_in   : in std_logic;
		
		--output data
		data_out : out std_logic_vector(DATA_WIDTH-1 downto 0);
		hsync    : out std_logic := '0';
		vsync    : out std_logic := '0';
		de       : out std_logic := '0';
		
		--status bit
		sync_error : out std_logic := '0'
		

        );
end vstream2vga;

architecture str of vstream2vga is 
	
	signal count_enable : std_logic := '0';
	signal h_count, v_count : integer range 0 to 4096 := 0;
	signal data_in_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal sof_in_dly, eol_in_dly : std_logic := '0';
	signal reset_sync, reset_meta : std_logic := '0';
    signal self_reset : std_logic := '0';
    
begin

	process(clk)
	begin
		--pixel clock rising edge
		if(rising_edge(clk)) then
            reset_meta <= reset or self_reset;
			reset_sync <= reset_meta;
            
			--turn enable at the start of the first valid frame
			--------------------------------------------
			if(valid_in = '1' and sof_in = '1') then
				count_enable <= '1';
				h_count <= 0;
				v_count <= 0;
			end if;
			-------------------------------------------
			
			--data in reg is aligned with the count updating
			data_in_reg <= data_in;			
			
			sof_in_dly <= sof_in;
			eol_in_dly <= eol_in;
			
			if(count_enable = '1') then
				if(sof_in_dly = '0' and h_count = 0 and v_count = 0) then
					sync_error <= '1';
                    self_reset <= '1';
				end if;
				
				if(eol_in_dly = '0' and h_count = h_active-1 and v_count < v_active) then
					sync_error <= '1';
                    self_reset <= '1';
				end if;
			end if;
			--------------------------------------------
			
			if(count_enable = '1') then
				--increment counts
				if(h_count = h_total-1) then
					--reset
					h_count <= 0;
		
					if(v_count = v_total-1) then
						v_count <= 0;
					else
						v_count <= v_count + 1;
					end if;
				else
					h_count <= h_count + 1;
				end if;
			end if;
	
			--------------------------------------------
			
			--update sync markers and DE bit
			data_out <= data_in_reg;
			
			if(count_enable = '1') then
				--hsync
				if(h_count < h_active + h_frontporch) then
					hsync <= not SYNC_POL;
				elsif(h_count >= h_active + h_frontporch + h_syncwidth) then
					hsync <= not SYNC_POL;
				else
					hsync <= SYNC_POL;
				end if;
				--vsync
				if(v_count < v_active + v_frontporch) then
					vsync <= not SYNC_POL;
				elsif(v_count >= v_active + v_frontporch + v_syncwidth) then
					vsync <= not SYNC_POL;
				else
					vsync <= SYNC_POL;
				end if;
				
				--de
				if(h_count < h_active and v_count < v_active) then
					de <= '1';
				else
					de <= '0';
				end if;
			end if;
	
			
	
			--------------------------------------------
			if(reset_sync = '1') then
				count_enable <= '0';
				h_count <= 0;
				v_count <= 0;
				sync_error <= '0';
                vsync <= not SYNC_POL;
                hsync <= not SYNC_POL;
                de <= '0';
                sof_in_dly <= '0';
                eol_in_dly <= '0';
                self_reset <= '0';
			end if;
			--------------------------------------------
			
		end if;
	
	end process;

	

end str;