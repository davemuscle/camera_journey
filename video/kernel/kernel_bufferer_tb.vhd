library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;

entity kernel_bufferer_tb is 

end kernel_bufferer_tb;

architecture test of kernel_bufferer_tb is
    
	signal clk50M : std_logic := '0';
	signal clk_count : integer := 0;
	
	--constant h_active : integer := 32;
	--constant h_total  : integer := 40;
	--constant v_active : integer := 16;
	--constant v_total  : integer := 20;
    
    constant h_active : integer := 160;
    constant h_total  : integer := 180;
    constant v_active : integer := 120;
    constant v_total  : integer := 130;
    
    
	--constant h_active : integer := 640;
	--constant h_total  : integer := 800;
	--constant v_active : integer := 480;
	--constant v_total  : integer := 525;
    
	--constant h_active : integer := 1920;
	--constant h_total  : integer := 2200;
	--constant v_active : integer := 1080;
	--constant v_total  : integer := 1125;
    
    signal gen_en : std_logic := '0';

    
    signal vtg_sof, vtg_eol, vtg_vld : std_logic := '0';
    signal ker_sof, ker_eol, ker_vld : std_logic := '0';
    signal count : std_logic_vector(15 downto 0) := (others => '0');
    
    signal sof_cnt : integer := 0;
    signal eol_cnt : integer := 0;
    signal sof_o   : std_logic := '0';
    signal eol_o   : std_logic := '0';
    
begin

	video_timing_gen_inst : entity work.video_timing_generator
    generic map(
        H_ACTIVE => h_active,
        H_TOTAL  => h_total,
        V_ACTIVE => v_active,
        V_TOTAL  => v_total
    )
	port map(
		clk    => clk50M,
		enable => gen_en,

        sof => vtg_sof,
        eol => vtg_eol,
        vld => vtg_vld
	);
    
    process(clk50M)
    begin
        if(rising_edge(clk50M)) then
        
            ker_sof <= vtg_sof;
            ker_eol <= vtg_eol;
            ker_vld <= vtg_vld;
 
            if(vtg_vld = '1') then
                count <= std_logic_vector(unsigned(count)+1);
            end if;
 
            if(vtg_sof = '1') then
                count <= (0 => '1', others => '0');
            end if;

        end if;
    end process;

	kernel_bufferer_inst : entity work.kernel_bufferer
	generic map(
        DATA_WIDTH => 16,
        MATRIX_SIZE => 5,
		h_active   => h_active,
		v_active   => v_active
	
		)
	port map(
		clk => clk50M,
        reset => '0',

        sof_i  => ker_sof,
        eol_i  => ker_eol,
        vld_i  => ker_vld,
        dat_i  => count,


        sof_o => sof_o,
        eol_o => eol_o,
        vld_o => open,
        dat_o => open,
        dat_r => open,
        
        fifo_error => open,
        bootstrap_error => open
	);
    
	clk_stim : process
	begin
		clk50M <= '0';
		wait for 10 ns;
		clk50M <= '1';
		wait for 10 ns;
	end process;

    process(clk50M)
    begin
        if(rising_edge(clk50M)) then
            gen_en <= '1';
            if(sof_o = '1') then
                sof_cnt <= sof_cnt + 1;
                if(sof_cnt = 2) then
                    assert false report "done" severity failure;
                end if;
            end if;
            if(eol_o = '1' )then
                eol_cnt <= eol_cnt + 1;
                if(eol_cnt = 99) then
                    assert false report "100 eol" severity note;
                    eol_cnt <= 0;
                end if;
            end if;
        end if;
    end process;

    process
    begin
  
	wait;

    end process;
    
end test;