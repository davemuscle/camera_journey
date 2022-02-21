library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;

entity stream_combiner_tb is 

end stream_combiner_tb;

architecture test of stream_combiner_tb is
    
    constant clk_a_period : time := (1 sec / (2*84000000));
    --constant clk_b_period : time := (1 sec / (2*84000020));
    constant clk_b_period : time := (1 sec / (2*83989900));
	--constant clk_b_period : time := (1 sec / (2*83899950));

	signal clk_a_count : integer := 0;
	signal clk_b_count : integer := 0;

	constant h_active : integer := 16;
	constant h_total  : integer := 20;
	constant v_active : integer := 12;
	constant v_total  : integer := 16;
    
    signal clk_a, clk_b : std_logic := '0';
    signal sof_a, sof_b : std_logic := '0';
    signal eol_a, eol_b : std_logic := '0';
    signal vld_a, vld_b : std_logic := '0';
    
    signal gen_a, gen_b : std_logic := '0';
     
begin

	video_timing_gen_inst_a : entity work.video_timing_generator
    generic map(
        H_ACTIVE => h_active,
        H_TOTAL  => h_total,
        V_ACTIVE => v_active,
        V_TOTAL  => v_total
    )
	port map(
		clk    => clk_a,
		enable => gen_a,

        sof => sof_a,
        eol => eol_a,
        vld => vld_a
	);

	video_timing_gen_inst_b : entity work.video_timing_generator
    generic map(
        H_ACTIVE => h_active,
        H_TOTAL  => h_total,
        V_ACTIVE => v_active,
        V_TOTAL  => v_total
    )
	port map(
		clk    => clk_b,
		enable => gen_b,

        sof => sof_b,
        eol => eol_b,
        vld => vld_b
	);



    dual_stream_aligner: entity work.stream_combiner
	generic map(
        DATA_WIDTH    => 24,
		H_ACTIVE      => h_active,
		LINES_IN_FIFO => 4
    )
	port map(
	    clk_a      => clk_a,
	    clk_b      => clk_b,
		reset      => '0',
        fifo_error => open,
        
        sof_a_i => sof_a,
        eol_a_i => eol_a,
        vld_a_i => vld_a,
        dat_a_i => (others => '0'),
        
        sof_b_i => sof_b,
        eol_b_i => eol_b,
        vld_b_i => vld_b,
        dat_b_i => (others => '0'),
        
        sof_o   => open,
        eol_o   => open,
        vld_o   => open,
        dat_o   => open
       
    );

	

	clk_stim_a : process
	begin
		clk_a <= '0';
		wait for clk_a_period;
		clk_a <= '1';
		wait for clk_a_period;
	end process;
    
	clk_stim_b : process
	begin
		clk_b <= '0';
		wait for clk_b_period;
		clk_b <= '1';
		wait for clk_b_period;
	end process;
    
    process(clk_a)
    begin
        if(rising_edge(clk_a)) then
            if(clk_a_count = 10) then
                gen_a <= '1';
            else
                clk_a_count <= clk_a_count + 1;
            end if;
        end if;
    end process;

    process(clk_b)
    begin
        if(rising_edge(clk_b)) then
            if(clk_b_count = 17) then
                gen_b <= '1';
            else
                clk_b_count <= clk_b_count + 1;
            end if;
        end if;
    end process;

    process
    begin
  
	wait;

    end process;
    
end test;