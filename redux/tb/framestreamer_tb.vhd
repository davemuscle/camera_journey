library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.math_real.all;

use work.axi_pkg.all;

entity framestreamer_tb is 

end framestreamer_tb;

architecture test of framestreamer_tb is

	constant downstream_period_ns : time := (1 sec / 148500000);

	constant PIXEL_WIDTH : integer := 32;
	constant DATA_WIDTH  : integer := 256;
    
	constant h_active : integer := 160;
	constant v_active : integer := 120;
    constant h_total  : integer := 200;
    constant v_total  : integer := 128;

	--constant h_active : integer := 1280;
	--constant v_active : integer := 720;
    --constant h_total  : integer := 1300;
    --constant v_total  : integer := 740;
    
	--constant h_active : integer := 1920;
	--constant v_active : integer := 1080;
    --constant h_total  : integer := 1940;
    --constant v_total  : integer := 1084;

    constant BURST_SIZE : integer := 8;

    constant RAM_SIZE       : integer := 4*h_active*v_active/(DATA_WIDTH/PIXEL_WIDTH);
    constant ENTIRE_RAM     : integer := 2**integer(ceil(log2(real(RAM_SIZE))));
    constant BRAM_TEST_SIZE : integer := integer(ceil(log2(real(ENTIRE_RAM))));

    --clocking
	signal clk : std_logic := '0';
	signal clk_count : integer := 0;
	signal downstream_clk, upstream_clk : std_logic := '0';

    --pixel streams
	signal pixel_in, pixel_out : std_Logic_vector(PIXEL_WIDTH-1 downto 0) := (others => '0');
	signal pixel_in_valid, pixel_out_valid : std_logic := '0';
	signal pixel_in_sof, pixel_in_eol : std_logic := '0';
	signal pixel_out_sof, pixel_out_eol : std_logic := '0';	

    --verification
    signal gen_en : std_logic := '0';
    signal rgb : std_logic_vector(23 downto 0) := (others => '0');
    signal image_written : std_logic := '0';
    signal i_w_cnt : integer := 0;
    
    --random tb
    signal sof_toggle : std_logic := '0';

    --constant BRAM_TEST_SIZE : integer := integer(ceil(log2(real((2**30) / (DATA_WIDTH/8)))));
    --constant BRAM_TEST_SIZE : integer := 14;

    signal framebuffer_axi_m2s : axi4_m2s := axi4_m2s_init;
    signal framebuffer_axi_s2m : axi4_s2m := axi4_s2m_init;
    signal framebuffer_axi_wdata : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal framebuffer_axi_rdata : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    signal frame_offset_1, frame_offset_2, frame_offset_3 : std_logic_vector(31 downto 0) := (others => '0');
    constant frame_offset_constant : integer := 2**integer(ceil(log2(real(h_active*v_active*PIXEL_WIDTH/8))));
    signal frame_offsets : std_logic_vector(95 downto 0) := (others => '0');
    signal frame_active : std_logic_vector(2 downto 0) := (others => '0');
    signal output_enable : std_logic := '0';
    
    signal valid_note : std_logic := '0';
    signal reset_go : std_logic_vector(127 downto 0) := (others => '0');
    signal rst : std_logic := '0';
    signal en_dly : std_logic_vector(127 downto 0) := (others => '0');
    signal rst_dly : std_logic_vector(511 downto 0) := (others => '0');

    
begin

    frame_offset_1 <= std_logic_vector(to_unsigned(0+frame_offset_constant*0,32));
    frame_offset_2 <= std_logic_vector(to_unsigned(0+frame_offset_constant*1,32));
    frame_offset_3 <= std_logic_vector(to_unsigned(0+frame_offset_constant*2,32));
    frame_offsets <= frame_offset_3 & frame_offset_2 & frame_offset_1;
    --frame_active <= "100";
    output_enable <= gen_en;
    
	framestreamer_inst : entity work.framestreamer
	generic map(
        PIXEL_WIDTH       => PIXEL_WIDTH,
		DATA_WIDTH        => DATA_WIDTH,
        XFER_TIMEOUT      => 100000,
        MAX_BURST         => BURST_SIZE
	)
	port map(
        
        h_active => std_logic_vector(to_unsigned(h_active,12)),
        v_active => std_logic_vector(to_unsigned(v_active,12)),
        h_total  => std_logic_vector(to_unsigned(h_total,12)),
        v_total  => std_logic_vector(to_unsigned(v_total,12)),
        frame_offsets => frame_offsets,
        frame_active  => frame_active,
        output_enable => output_enable,
        
        fifo_ov        => open,
        fifo_un        => open,
        datamove_error => open,
        
		pclk => downstream_clk,
        preset => rst,
        pixel_out => pixel_out,
        pixel_out_sof => pixel_out_sof,
        pixel_out_eol => pixel_out_eol,
        pixel_out_vld => pixel_out_valid,
        
        --axi memory
        aclk       => clk,
        areset     => rst,
		axi4_m2s_o => framebuffer_axi_m2s,
        axi4_s2m_i => framebuffer_axi_s2m,
        axi4_wdata => framebuffer_axi_wdata,
        axi4_rdata => framebuffer_axi_rdata
        
		
	);
    
    process(downstream_clk)
    begin
        if(rising_edge(downstream_clk)) then
            if(pixel_out_sof = '1') then
                case frame_active is 
                when "001" => frame_active <= "010";
                when "010" => frame_active <= "100";
                when others => frame_active <= "001";
                end case;
            end if;
        end if;
    end process;
    
    axi_bram_inst : entity work.axi_bram_model
    generic map(
		DATA_WIDTH        => DATA_WIDTH,
        BRAM_TEST_SIZE    => BRAM_TEST_SIZE
    )
    port map(
        aclk    => clk,
        areset  => rst,
        axi4_m2s_i => framebuffer_axi_m2s,
        axi4_s2m_o => framebuffer_axi_s2m,
        axi4_wdata => framebuffer_axi_wdata,
        axi4_rdata => framebuffer_axi_rdata
        
    );

	img_wr_inst : entity work.image_writer
	generic map(
	    o_file => "../matlab/Verification/framestreamer_output.txt",
        DATA_WIDTH => 24,
        h_active   => h_active,
        v_active   => v_active
        
	)
	port map(
		clk      => downstream_clk,
		enable   => gen_en,
        sof      => pixel_out_sof,
        eol      => pixel_out_eol,
        data     => pixel_out(23 downto 0),
        valid    => pixel_out_valid,
        pic_err  => open,
        line_err => open,
        i_w      => image_written,
        i_w_cnt  => i_w_cnt

	);

	clk_stim : process
	begin
		clk <= '0';
		wait for 10 ns;
		clk <= '1';
		wait for 10 ns;
	end process;
	
	dwnclk_stim : process
	begin
		downstream_clk <= '0';
		wait for downstream_period_ns;
		downstream_clk <= '1';
		wait for downstream_period_ns;
	end process;
	
    gen_en <= en_dly(127);

    --comparison to counting data
    process(downstream_clk)
    begin
        if(rising_edge(downstream_clk)) then

            if(pixel_out_valid = '1' and valid_note = '0') then
                valid_note <= '1';
                assert false report "Valid received" severity note;
            end if;
            
            if(image_written = '1') then
                assert false report "Image Written" severity note; 
            end if;
            
            reset_go <= reset_go(126 downto 0) & '0';
            
            rst_dly <= rst_dly(510 downto 0) & '0'; 
            
            if(image_written = '1' and i_w_cnt = 2) then
            
                --assert false report "Second Image Written" severity failure;
            
                --enable reset
                --rst_dly(0) <= '1';
                --assert false report "Reset Active" severity note;
                --assert false report "Switching Pattern" severity note;
                --pattern <= "01";
            end if;
            
            if(rst_dly(511) = '1') then
                reset_go <= (others => '1');
            end if;
            
            rst <= reset_go(127);
            
            
            en_dly <= en_dly(126 downto 0) & not rst;
            if(rst = '1') then
                valid_note <= '0';
            end if;
            
            if(image_written = '1' and i_w_cnt = 4) then
                assert false report "Fourth Image Written" severity failure;
            end if;
            
            
            
        end if;
    end process;

    process
    begin
		wait;
    end process;
    
end test;