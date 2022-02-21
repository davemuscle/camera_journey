library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
--Dave Muscle

--Two streams on two different clocks go to one stream on the first clock

--Provides buffering to hold a few lines

entity stream_combiner is
	generic(
        DATA_WIDTH    : integer := 8;
		H_ACTIVE      : integer := 1920;
		LINES_IN_FIFO : integer := 4
		);
	port(
	    clk_a      : in  std_logic;
	    clk_b      : in  std_logic;
		reset      : in  std_logic;
        fifo_error : out std_logic := '0';
        
        sof_a_i : in std_logic;
        eol_a_i : in std_logic;
        vld_a_i : in std_logic;
        dat_a_i : in std_logic_vector(DATA_WIDTH-1 downto 0);
        
        sof_b_i : in std_logic;
        eol_b_i : in std_logic;
        vld_b_i : in std_logic;
        dat_b_i : in std_logic_vector(DATA_WIDTH-1 downto 0);
        
        sof_o   : out std_logic := '0';
        eol_o   : out std_logic := '0';
        vld_o   : out std_logic := '0';
        dat_o   : out std_logic_vector(2*DATA_WIDTH-1 downto 0)
       
        );
end stream_combiner;

architecture arch of stream_combiner is 



    --FIFO signals
    signal a_fifo_wr_en : std_logic := '0';
    signal a_fifo_rd_en : std_logic := '0';
    signal a_fifo_wr_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal a_fifo_rd_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    signal b_fifo_wr_en : std_logic := '0';
    signal b_fifo_rd_en : std_logic := '0';
    signal b_fifo_wr_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal b_fifo_rd_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    signal a_ov, a_un, b_ov, b_un : std_logic := '0';
    signal fifo_error_t : std_logic := '0';
    
    --Queue signals
    constant QUEUE_ZEROS        : std_logic_vector(LINES_IN_FIFO-1 downto 0) := (others => '0');
    signal   a_queue            : std_logic_vector(LINES_IN_FIFO-1 downto 0) := (others => '0');
    signal   b_queue            : std_logic_vector(LINES_IN_FIFO-1 downto 0) := (others => '0');
    signal   a_queue_sof_error  : std_logic := '0';
    signal   b_queue_sof_error  : std_logic := '0';
    signal   a_queue_line_error : std_logic := '0';
    signal   b_queue_line_error : std_logic := '0';

    --Stream signals
    signal read_go : std_logic := '0';
    signal rd_cnt : unsigned(11 downto 0) := (others => '0');
    
    signal sof_a_latch : std_logic := '0';
    signal sof_b_latch : std_logic := '0';
    
    signal sof_b_i_sync : std_logic := '0';
    signal eol_b_i_sync : std_logic := '0';
    
    
begin

    a_fifo_wr_en <= vld_a_i;
    b_fifo_wr_en <= vld_b_i;
    
    a_fifo_rd_en <= read_go;
    b_fifo_rd_en <= read_go;

    a_fifo_wr_data <= dat_a_i;
    b_fifo_wr_data <= dat_b_i;
    
    dat_o <= b_fifo_rd_data & a_fifo_rd_data;

    process(clk_a)
    begin
        if(rising_edge(clk_a)) then

            --Reset the queue when we receive a SOF
            --The queue should be empty anyways
            if(sof_a_i = '1') then
                a_queue <= (others => '0');
                if(a_queue /= QUEUE_ZEROS) then
                    a_queue_sof_error <= '1';
                end if;
                sof_a_latch <= '1';
            end if;

            if(sof_b_i_sync = '1') then
                b_queue <= (others => '0');
                if(b_queue /= QUEUE_ZEROS) then
                    b_queue_sof_error <= '1';
                end if;
                sof_b_latch <= '1';
            end if;

            --Add to the queue when we receive an EOL
            if(eol_a_i = '1') then
                a_queue <= a_queue(LINES_IN_FIFO-2 downto 0) & '1';
                --If we are pushing an active line out of the queue, error
                if(a_queue(LINES_IN_FIFO-1) = '1') then
                    a_queue_line_error <= '1';
                end if;
            end if;

            if(eol_b_i_sync = '1') then
                b_queue <= b_queue(LINES_IN_FIFO-2 downto 0) & '1';
                --If we are pushing an active line out of the queue, error
                if(b_queue(LINES_IN_FIFO-1) = '1') then
                    b_queue_line_error <= '1';
                end if;
            end if;

            if(a_queue(0) = '1' and b_queue(0) = '1') then
                read_go <= '1';
                rd_cnt <= (others => '0');
                if(eol_a_i = '1') then
                    --Patch: No change
                    a_queue <= a_queue;
                else
                    a_queue <= '0' & a_queue(LINES_IN_FIFO-1 downto 1);
                end if;
                if(eol_b_i_sync = '1') then
                    --Patch: no change
                    b_queue <= b_queue;
                else
                    b_queue <= '0' & b_queue(LINES_IN_FIFO-1 downto 1);
                end if;
            end if;
              
            sof_o <= '0';
            vld_o <= '0';
            eol_o <= '0';
            
            --Read from both FIFOs to align the streams
            if(read_go = '1') then
                rd_cnt <= rd_cnt + 1;

                if(sof_a_latch = '1' and sof_b_latch = '1') then
                    sof_o <= '1';
                    sof_a_latch <= '0';
                    sof_b_latch <= '0';
                end if;
                
                vld_o <= '1';
                
                if(rd_cnt = to_unsigned(H_ACTIVE-1,12)) then
                    eol_o <= '1';
                    read_go <= '0';
                end if;
            end if;

            if(fifo_error_t = '1') then
                fifo_error <= '1';
            end if;
            
            if(reset = '1') then
                rd_cnt      <= (others => '0');
                sof_a_latch <= '0';
                sof_b_latch <= '0';
                read_go     <= '0';
                fifo_error  <= '0';
                a_queue     <= (others => '0');
                b_queue     <= (others => '0');
                a_queue_sof_error <= '0';
                b_queue_sof_error <= '0';
                a_queue_line_error <= '0';
                b_queue_line_error <= '0';
            end if;
            
        end if;
    end process;
    
	sof_sync : entity work.pulse_sync_handshake
	port map(
		clk_a   => clk_b,
        pulse_a => sof_b_i,
        busy_a  => open,
        clk_b   => clk_a,
        pulse_b => sof_b_i_sync
	);
    
	eol_sync : entity work.pulse_sync_handshake
	port map(
		clk_a   => clk_b,
        pulse_a => eol_b_i,
        busy_a  => open,
        clk_b   => clk_a,
        pulse_b => eol_b_i_sync
	);
    

	stream_a_fifo_inst : entity work.async_fifo
	generic map(
		gDEPTH => LINES_IN_FIFO*h_active, 
		gWIDTH => DATA_WIDTH, 
		gOREGS => 0
	)
	port map(
		wr_clk  => clk_a, 
		wr_en   => a_fifo_wr_en,
		wr_data => a_fifo_wr_data,
		rd_clk  => clk_a,
		rd_en   => a_fifo_rd_en,
		rd_data => a_fifo_rd_data,
		reset   => reset,
		ff      => open,
		fe      => open,
		ov      => a_ov,
		un      => a_un
	);

	stream_b_fifo_inst : entity work.async_fifo
	generic map(
		gDEPTH => LINES_IN_FIFO*h_active, 
		gWIDTH => DATA_WIDTH, 
		gOREGS => 0
	)
	port map(
		wr_clk  => clk_b, 
		wr_en   => b_fifo_wr_en,
		wr_data => b_fifo_wr_data,
		rd_clk  => clk_a,
		rd_en   => b_fifo_rd_en,
		rd_data => b_fifo_rd_data,
		reset   => reset,
		ff      => open,
		fe      => open,
		ov      => b_ov,
		un      => b_un
	);
    
    fifo_error_t <= a_ov or a_un or b_ov or b_un;
    
end arch;
