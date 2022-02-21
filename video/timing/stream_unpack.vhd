library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Dave Muscle
--Buffers video to provide unpacked streaming
--Eg: Video stream of 256 bits gets converted to 8 bits by buffering 32 pixels

--Will probably only work if blanking is provided

--Expecting the first pixel to be in the MSB

entity stream_unpack is
    generic(
        INPUT_WIDTH  : integer := 256;
        OUTPUT_WIDTH : integer := 8;
        H_ACTIVE     : integer := 160
        
    );
	port(
		clk      : in  std_logic;
		reset    : in  std_logic;
        
        fifo_ov  : out std_logic;
        fifo_un  : out std_logic;
        
        sof_i    : in  std_logic;
        eol_i    : in  std_logic;
        vld_i    : in  std_logic;
        dat_i    : in  std_logic_vector(INPUT_WIDTH-1 downto 0);
        
        sof_o    : out std_logic := '0';
        eol_o    : out std_logic := '0';
        vld_o    : out std_logic := '0';
        dat_o    : out std_logic_vector(OUTPUT_WIDTH-1 downto 0)
    );
end stream_unpack;

architecture arch of stream_unpack is 
    
    constant RATIO : integer := INPUT_WIDTH/OUTPUT_WIDTH;
    type     unpack_t  is array(0 to RATIO-1) of std_logic_vector(OUTPUT_WIDTH-1 downto 0);
    signal   unpack  : unpack_t := (others => (others => '0'));
    signal   unpack_cnt : integer range 0 to RATIO-1 := 0;
    
    signal first : std_logic := '0';
    signal enable : std_logic := '0';
    
    signal fifo_wr_en   : std_logic := '0';
    signal fifo_rd_en   : std_logic := '0';
    signal fifo_wr_data : std_logic_vector(INPUT_WIDTH-1 downto 0) := (others => '0');
    signal fifo_rd_data : std_logic_vector(INPUT_WIDTH-1 downto 0) := (others => '0');

    signal   ocnt : integer range 0 to H_ACTIVE-1 := 0;
    
    signal sof_enable : std_logic := '0';
    signal enable_dly : std_logic := '0';
    signal fifo_rd_en_dly : std_logic := '0';
begin

    process(clk)
    begin
        if(rising_edge(clk)) then

            --Level for sof output
            if(sof_i = '1' and vld_i = '1') then
                sof_enable <= '1';
            end if;
            
            fifo_rd_en <= '0';
            
            --Read the first pixel
            if(eol_i = '1' and vld_i = '1') then
                enable <= '1';
                unpack_cnt <= 0;
                fifo_rd_en <= '1';
                ocnt <= 0;
            end if;
                        
            enable_dly <= enable;
          
            for i in 0 to RATIO-2 loop
                unpack(i+1) <= unpack(i);
            end loop;
            fifo_rd_en_dly <= fifo_rd_en;
            if(fifo_rd_en_dly = '1') then
                for i in 0 to RATIO-1 loop
                    unpack(i) <= fifo_rd_data((OUTPUT_WIDTH*(i+1))-1 downto OUTPUT_WIDTH*i);
                end loop;
            end if;
            
            sof_o <= '0';
            eol_o <= '0';
            vld_o <= '0';
          
            if(enable_dly = '1') then
                if(unpack_cnt = RATIO-1) then
                    unpack_cnt <= 0;
                else
                    unpack_cnt <= unpack_cnt + 1;
                end if;
                if(unpack_cnt = RATIO-2) then
                    fifo_rd_en <= '1';
                end if;
                vld_o <= '1';
                if(sof_enable = '1' and ocnt = 0) then
                    sof_o <= '1';
                    sof_enable <= '0';
                end if;
                if(ocnt = H_ACTIVE-2) then
                    fifo_rd_en <= '0';
                end if;
                if(ocnt = H_ACTIVE-1) then
                    eol_o <= '1';
                    ocnt <= 0;
                    enable <= '0';
                    enable_dly <= '0';
                    fifo_rd_en <= '0';
                else
                    ocnt <= ocnt + 1;
                end if;
            end if;
            
            if(reset = '1') then
                sof_enable <= '0';
                enable <= '0';
                enable_dly <= '0';
                unpack_cnt <= 0;
                ocnt <= 0;
                
            end if;

        end if;
    end process;
    
    dat_o <= unpack(RATIO-1);

    --On a valid packed pixel, write into FIFO
    fifo_wr_en   <= vld_i;
    fifo_wr_data <= dat_i;

    --Instantiate FIFO
    fifo_inst : entity work.sync_fifo
    generic map(
        gDEPTH => H_ACTIVE,
        gWIDTH => INPUT_WIDTH,
        gOREGS => 0,
        gPF    => 0,
        gPE    => 0
    )
    port map(
        clk     => clk,
        reset   => reset,
        wr_en   => fifo_wr_en,
        wr_data => fifo_wr_data,
        rd_en   => fifo_rd_en,
        rd_data => fifo_rd_data,
        
        ff => open,
        fe => open,
        pf => open,
        pe => open,
        ov => fifo_ov,
        un => fifo_un
    
    );
    

end arch;