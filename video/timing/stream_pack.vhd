library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
--Dave Muscle
--Buffers video to provide packed streaming
--Eg: Video stream of 8 bits gets converted to 256 bits by buffering 32 pixels

--Will probably only work if blanking is provided

--Rolls up to have the latest pixel be in the LSB

entity stream_pack is
    generic(
        INPUT_WIDTH  : integer := 8;
        OUTPUT_WIDTH : integer := 256;
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
end stream_pack;

architecture arch of stream_pack is 
    
    constant RATIO : integer := OUTPUT_WIDTH/INPUT_WIDTH;
    type     pack_t  is array(0 to RATIO-1) of std_logic_vector(INPUT_WIDTH-1 downto 0);
    signal   pack  : pack_t := (others => (others => '0'));
    signal   pack_cnt : integer range 0 to RATIO-1 := 0;
    
    signal first : std_logic := '0';
    signal enable : std_logic := '0';
    
    signal fifo_wr_en   : std_logic := '0';
    signal fifo_rd_en   : std_logic := '0';
    signal fifo_wr_data : std_logic_vector(OUTPUT_WIDTH-1 downto 0) := (others => '0');
    signal fifo_rd_data : std_logic_vector(OUTPUT_WIDTH-1 downto 0) := (others => '0');

    constant O_H_ACTIVE : integer := integer(ceil(real(H_ACTIVE)/(real(RATIO))));
    signal   ocnt : integer range 0 to O_H_ACTIVE-1 := 0;
    
    signal sof_enable : std_logic := '0';
    
begin

    process(clk)
    begin
        if(rising_edge(clk)) then

            --On a valid pixel, place in shift register
            if(vld_i = '1') then
                pack(0) <= dat_i;
                for i in 1 to RATIO-1 loop
                    pack(i) <= pack(i-1);
                end loop;
            end if;
            fifo_wr_en <= '0';
            --Count how many pixels have been packed
            if(vld_i = '1') then
                if(pack_cnt = RATIO-1) then
                    pack_cnt <= 0;
                else
                    pack_cnt <= pack_cnt + 1;
                end if;
                if(pack_cnt = RATIO-2) then
                    fifo_wr_en <= '1';
                end if;
                if(sof_i = '1' or first = '1') then
                    first <= '0';
                    pack_cnt <= 0;
                end if;
                if(sof_i = '1') then
                    sof_enable <= '1';
                end if;
                if(eol_i = '1') then
                    first  <= '1';
                    enable <= '1';
                    ocnt   <= 0;
                end if;
            end if;
            sof_o <= '0';
            eol_o <= '0';
            vld_o <= '0';
            --Read out all the packed up data
            if(enable = '1') then
                vld_o <= '1';
                if(ocnt = 0) then
                    sof_o      <= sof_enable;
                    sof_enable <= '0';
                end if;
                if(ocnt = O_H_ACTIVE-1) then
                    enable <= '0';
                    ocnt   <= 0;
                    eol_o  <= '1';
                else
                    ocnt <= ocnt + 1;
                end if;
            end if;
            --Reset
            if(reset = '1') then
                pack_cnt <= 0;
                first    <= '0';
                enable   <= '0';
                ocnt     <= 0;
            end if;
        end if;
    end process;

    --Roll up array into vector
    process(pack)
    begin
        for i in 0 to RATIO-1 loop
            fifo_wr_data((INPUT_WIDTH*(i+1))-1 downto INPUT_WIDTH*i) <= pack(i);
        end loop;
    end process;

    --Assign some signals
    fifo_rd_en <= enable;
    dat_o      <= fifo_rd_data;

    --Instantiate FIFO
    fifo_inst : entity work.sync_fifo
    generic map(
        gDEPTH => H_ACTIVE,
        gWIDTH => OUTPUT_WIDTH,
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