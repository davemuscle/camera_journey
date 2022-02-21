library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.math_real.all;

use work.axi_pkg.all;

entity axi_datamover_tb is 

end axi_datamover_tb;

architecture test of axi_datamover_tb is

    constant PIXEL_WIDTH : integer := 16;
    constant DATA_WIDTH  : integer := 512;
    constant MAX_BURST   : integer := 16;
    
    constant LINE_WIDTH : integer := 1920;
    --constant XFER_SIZE  : integer := 240;
    constant XFER_SIZE : integer := (LINE_WIDTH*PIXEL_WIDTH/8)-1;
    constant XFER_SIZE_BEATS : integer := LINE_WIDTH/(DATA_WIDTH/PIXEL_WIDTH);
    --constant XFER_SIZE  : integer := LINE_WIDTH/(DATA_WIDTH/PIXEL_WIDTH);


    --clocking
	signal clk : std_logic := '0';
	signal clk_count : integer := 0;

    signal fifo_rd_en : std_logic := '0';
    signal fifo_wr_en : std_logic := '0';
    signal fifo_rd_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal fifo_wr_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal fifo_un, fifo_ov : std_logic := '0';
    
    constant BRAM_TEST_SIZE : integer := 20;

    signal axi_m2s : axi4_m2s := axi4_m2s_init;
    signal axi_s2m : axi4_s2m := axi4_s2m_init;
    signal axi_wdata : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal axi_rdata : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    signal fifo_wr_mux : std_logic := '0';
    signal fifo_wr_bs_en   : std_logic := '0';
    signal fifo_wr_bs_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal fifo_wr_axi_en   : std_logic := '0';
    signal fifo_wr_axi_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');   
    
    signal bootstrap_go   : std_logic := '0';
    signal bootstrap_done : std_logic := '0';
    
    signal datamove_go           : std_logic := '0';
    signal datamove_dir          : std_logic := '0';
    signal datamove_busy         : std_logic := '0';
    signal datamove_done         : std_logic := '0';
    signal datamove_timed_out    : std_logic := '0';
    signal datamove_transfer_len : std_logic_vector(15 downto 0) := (others => '0');
    signal datamove_burst_len    : std_logic_vector( 7 downto 0) := (others => '0');
    signal datamove_addr         : std_logic_vector(31 downto 0) := (others => '0');
    
    signal fifo_rd_en_dly : std_logic := '0';
    signal fifo_rd_data_exp : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal fifo_wr_data_exp : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal bad_read, bad_write : std_logic := '0';
    signal mode : std_logic := '0';
    
begin

    fifo_wr_en <= fifo_wr_bs_en when fifo_wr_mux = '1' else fifo_wr_axi_en;
    fifo_wr_data <= fifo_wr_bs_data when fifo_wr_mux = '1' else fifo_wr_axi_data;

    datamove_transfer_len <= std_logic_vector(to_unsigned(XFER_SIZE,16));
    
    --Boundary check occurs on first burst
    --datamove_addr <= x"00000FC0";
    
    --Boundary check occurs on last burst
    --datamove_addr <= x"00000140";
    
    fifo_inst : entity work.sync_fifo
    generic map(
        gDEPTH => XFER_SIZE,
        gWIDTH => DATA_WIDTH,
        gOREGS => 0,
        gPF    => 0,
        gPE    => 0
    )
    port map(
        clk     => clk,
        wr_en   => fifo_wr_en  ,
        wr_data => fifo_wr_data,
        rd_en   => fifo_rd_en  ,
        rd_data => fifo_rd_data,
        ff      => open,
        fe      => open,
        pf      => open,
        pe      => open,
        ov      => fifo_ov,
        un      => fifo_un
    );

    datamover_inst : entity work.axi_datamover
	generic map(
		DATA_WIDTH     => DATA_WIDTH,
        MAX_BURST      => MAX_BURST,
        TIMEOUT_CLOCKS => 1000
	)
	port map(
        --clocks and reset -------------------------------
		clk => clk,
        rst => '0',
        --control and status
        go           => datamove_go          ,
        dir          => datamove_dir         ,
        busy         => open        ,
        done         => datamove_done        ,
        timed_out    => open   ,
        transfer_len => datamove_transfer_len,
        start_addr   => datamove_addr        ,   
        --fifo2slave -------------------------------------
        f2s_fifo_en     => fifo_rd_en,
        f2s_fifo_data   => fifo_rd_data,
        --slave2fifo -------------------------------------
        s2f_fifo_en     => fifo_wr_axi_en,
        s2f_fifo_data   => fifo_wr_axi_data,
        --axi --------------------------------------------
        axi4_m2s_o => axi_m2s,
        axi4_s2m_i => axi_s2m,
        axi4_wdata => axi_wdata,
        axi4_rdata => axi_rdata
	);



    axi_bram_inst : entity work.axi_bram_model
    generic map(
		DATA_WIDTH        => DATA_WIDTH,
        BRAM_TEST_SIZE    => BRAM_TEST_SIZE
    )
    port map(
        aclk    => clk,
        areset  => '0',
        axi4_m2s_i => axi_m2s,
        axi4_s2m_o => axi_s2m,
        axi4_wdata => axi_wdata,
        axi4_rdata => axi_rdata
        
    );

  

	clk_stim : process
	begin
		clk <= '0';
		wait for 10 ns;
		clk <= '1';
		wait for 10 ns;
	end process;
	
    assert(fifo_ov = '0') report "FIFO Overflow" severity failure;
    assert(fifo_un = '0') report "FIFO Underflow" severity failure;


	--testbench stimulus
	process(clk)
	begin
		if(rising_edge(clk)) then

            fifo_rd_en_dly <= fifo_rd_en;

            clk_count <= clk_count + 1;
            if(clk_count = 10 and bootstrap_done = '0') then
                fifo_wr_mux   <= '1';
                bootstrap_go  <= '1';
                fifo_wr_bs_en <= '1';
            end if;
            
            if(clk_count = 10 and bootstrap_done = '1') then
                datamove_dir <= mode;
                datamove_go  <= '1';
            end if;
            
            if(clk_count = 11 and bootstrap_done = '1') then
                datamove_go <= '0';
            end if;
            
            if(datamove_done = '1') then
                mode <= not mode;
                if(mode = '1') then
                    datamove_addr <= std_logic_vector(unsigned(datamove_addr)+to_unsigned(XFER_SIZE+1,32));
                    if(datamove_addr >= x"0000_1000_0000_0000") then
                        datamove_addr <= (others => '0');
                    end if;
                end if;
                clk_count <= 0;
            end if;
            
            
            if(bootstrap_go = '1') then
                fifo_wr_bs_data <= std_logic_vector(unsigned(fifo_wr_bs_data)+1);
                if(fifo_wr_bs_data = std_logic_vector(to_unsigned(XFER_SIZE_BEATS-1,DATA_WIDTH))) then
                    bootstrap_done <= '1';
                    bootstrap_go   <= '0';
                    fifo_wr_bs_en  <= '0';
                    fifo_wr_mux    <= '0';
                    clk_count <= 0;
                end if;
            end if;
            
            if(bootstrap_done = '1' and fifo_rd_en_dly = '1') then
                fifo_rd_data_exp <= std_logic_vector(unsigned(fifo_rd_data_exp)+1);
                if(fifo_rd_data_exp /= fifo_rd_data) then
                    bad_read <= '1' after 10 us;
                end if;
            end if;
            
            if(datamove_dir = '0' and datamove_done = '1') then
                fifo_wr_data_exp <= (others => '0');
            end if;

            if(datamove_dir = '1' and datamove_done = '1') then
                fifo_rd_data_exp <= (others => '0');
            end if;
            
            if(bootstrap_done = '1' and fifo_wr_en = '1') then
                fifo_wr_data_exp <= std_logic_vector(unsigned(fifo_wr_data_exp)+1);
                if(fifo_wr_data_exp /= fifo_wr_data) then
                    bad_write <= '1' after 10 us;
                end if;
            end if;
            

		end if;
	end process;

    assert(bad_read = '0') report "Bad FIFO Read" severity failure;
    assert(bad_write = '0') report "Bad FIFO Write" severity failure;

    process
    begin
		wait;
    end process;
    
end test;