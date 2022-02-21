library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.math_real.all;

use work.axi_pkg.all;

entity app_top_tb is 

end app_top_tb;

architecture test of app_top_tb is

    constant FINAL_IMG : integer := 4;

    constant PIXEL_WIDTH : integer := 32;
    constant DATA_WIDTH  : integer := 256;

	constant upstream_period_ns   : time := (1 sec / 75000000);
	constant downstream_period_ns : time := (1 sec / 148500000);
    constant ddr_clk_period_ns    : time := (1 sec / 100000000);
    constant clk_board_period_ns  : time := (1 sec / 50000000);
    
	constant h_active     : integer := 160;
	constant h_frontporch : integer := 10;
    constant h_syncwidth  : integer := 20;
    constant h_backporch  : integer := 10;
    constant h_total      : integer := 200;   
    
    constant v_active     : integer := 120;
    constant v_frontporch : integer := 2;
    constant v_syncwidth  : integer := 4;
    constant v_backporch  : integer := 2;
    constant v_total      : integer := 128;

    --clocking
    signal clk_board : std_logic := '0';
    signal cam_pclk  : std_logic := '0';
    signal ddr_clk   : std_logic := '0';
    signal pclk      : std_logic := '0';
    
    --camera input
    signal cam_a_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal cam_a_href  : std_logic := '0';
    signal cam_a_vsync : std_logic := '0';
    signal cam_b_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal cam_b_href  : std_logic := '0';
    signal cam_b_vsync : std_logic := '0';
    
    --vga output
    signal vga_data  : std_logic_vector(23 downto 0) := (others => '0');
    signal vga_sof   : std_logic := '0';
    signal vga_eol   : std_logic := '0';
    signal vga_valid : std_logic := '0';
    

    --verification
    signal gen_en_a : std_logic := '0';
    signal gen_en_b : std_logic := '0';
    signal image_written : std_logic := '0';
    signal i_w_cnt : integer := 0;
    
    --random tb
    signal sof_toggle : std_logic := '0';


    constant BRAM_TEST_SIZE : integer := integer(ceil(log2(real((2**26) / (DATA_WIDTH/8)))));

    signal framebuffer_axi_m2s : axi4_m2s := axi4_m2s_init;
    signal framebuffer_axi_s2m : axi4_s2m := axi4_s2m_init;
    signal framebuffer_axi_wdata : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal framebuffer_axi_rdata : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  
    signal reset : std_logic := '0';
    signal reset_n : std_logic := '0';
    signal pattern : std_logic_vector(1 downto 0) := "10";
    
    signal en_dly : std_logic_vector(127 downto 0) := (others => '0');
    signal reset_go : std_logic_vector(127 downto 0) := (others => '1');
    signal rst_dly : std_logic_vector(511 downto 0) := (others => '1');
    signal valid_note : std_logic := '0';
    
    signal hsync_dly : std_logic := '0';
    signal vsync_dly : std_logic := '0';
    
    signal clk_count : unsigned(31 downto 0) := (others => '0');
    
    signal sof_count : integer := 0;
    
begin

    --Clock Generation
	upclk_stim : process
	begin
		cam_pclk <= '0';
		wait for upstream_period_ns/2;
		cam_pclk <= '1';
		wait for upstream_period_ns/2;
	end process;

	clk_stim : process
	begin
		clk_board <= '0';
		wait for clk_board_period_ns/2;
		clk_board <= '1';
		wait for clk_board_period_ns/2;
	end process;
	
	dwnclk_stim : process
	begin
		pclk <= '0';
		wait for downstream_period_ns/2;
		pclk <= '1';
		wait for downstream_period_ns/2;
	end process;
	
	ddr_stim : process
	begin
		ddr_clk <= '0';
		wait for ddr_clk_period_ns/2;
		ddr_clk <= '1';
		wait for ddr_clk_period_ns/2;
	end process;
    
    reset_n <= not reset;
    
	video_source_a : entity work.camera_stim
	generic map(
	    USE_BLANKING => true,
        USE_IMG_FILE => true,
        i_file       => "../matlab/AppTop/test_stream_160x120.txt",
        v_file       => "../matlab/VideoGen/video_stream.txt",
        h_active     => h_active,
        h_total      => h_total,
        v_active     => v_active,
        v_total      => v_total,
        v_sync_spot  => v_active + 2,
        num_images   => 16
        
	)
	port map(
		clk      => cam_pclk,
		enable   => gen_en_a,
        pattern  => "11",
        movement => '0',
        
        rgb      => open,
        raw_BGGR => cam_a_data(7 downto 0),
		raw_GBRG => open,
        raw_GRBG => open,
        raw_RGGB => open,
        
        href  => cam_a_href,
        vsync => cam_a_vsync,
        sof   => sof_toggle,
        eol   => open,
        valid => open

	);

	video_source_b : entity work.camera_stim
	generic map(
	    USE_BLANKING => true,
        USE_IMG_FILE => true,
        i_file       => "../matlab/AppTop/test_stream_160x120.txt",
        v_file       => "../matlab/VideoGen/video_stream.txt",
        h_active     => h_active,
        h_total      => h_total,
        v_active     => v_active,
        v_total      => v_total,
        v_sync_spot  => v_active + 2,
        num_images   => 16
        
	)
	port map(
		clk      => cam_pclk,
		enable   => gen_en_b,
        pattern  => "11",
        movement => '0',
        
        rgb      => open,
        raw_BGGR => cam_b_data(7 downto 0),
		raw_GBRG => open,
        raw_GRBG => open,
        raw_RGGB => open,
        
        href  => cam_b_href,
        vsync => cam_b_vsync,
        sof   => open,
        eol   => open,
        valid => open

	);

    process(cam_pclk)
    begin
        if(rising_edge(cam_pclk)) then
            if(sof_toggle = '1') then
                sof_count <= sof_count + 1;
            end if;
        end if;
    end process;

    application : entity work.app_top
    generic map(
        PIXEL_WIDTH    => PIXEL_WIDTH,
        DATA_WIDTH     => DATA_WIDTH,
        h_active       => h_active    , 
        h_frontporch   => h_frontporch, 
        h_syncwidth    => h_syncwidth , 
        h_backporch    => h_backporch , 
        h_total        => h_total     , 
        v_active       => v_active    , 
        v_frontporch   => v_frontporch, 
        v_syncwidth    => v_syncwidth , 
        v_backporch    => v_backporch , 
        v_total        => v_total     , 
        SIM            => TRUE,
        CLK_DIV_1ms    => 10,
        I2C_CLK_DIV    => 4,
        HPD_CHECKRATE  => 500,
        AXI_TIMEOUT    => 10000000,
        AXI_MAX_BURST  => 8,
        FRAMEBUFFER_FX => TRUE,
        UART_CLKRATE   => 50000000,
        UART_BAUDRATE  => 12500000
    )
	port map(
        --external reset
        reset_ext  => reset,
    
        --clocks
		clk_board => clk_board,
        cam_a_pclk  => cam_pclk ,
        cam_b_pclk  => cam_pclk,
        ddr_clk   => ddr_clk  ,
        pclk      => pclk     ,
		
        --uart debugger
        tx => open,
        rx => '0',
        
        --camera A
        cam_a_sda   => open,
        cam_a_scl   => open,
        cam_a_xclk_disable  => open,
		cam_a_reset => open,
		cam_a_pwdn  => open,
        cam_a_data  => cam_a_data ,
        cam_a_href  => cam_a_href ,
        cam_a_vsync => cam_a_vsync,       
        
        --camera B
        cam_b_sda   => open,
        cam_b_scl   => open,
        cam_b_xclk_disable  => open,
		cam_b_reset => open,
		cam_b_pwdn  => open,
        cam_b_data  => cam_b_data ,
        cam_b_href  => cam_b_href ,
        cam_b_vsync => cam_b_vsync,      

        --test output stream
        tb_out_sof   => vga_sof  ,
        tb_out_eol   => vga_eol  ,
        tb_out_valid => vga_valid,
        tb_out_data  => vga_data ,
        
        --adv7513 control
 		hdmi_sda => open,
		hdmi_scl => open,   
    
        --adv7513 VGA output stream
		vga_hsync => open,
		vga_vsync => open,
		vga_de    => open,
		vga_out   => open,
        
        --status signals to LEDs
        leds    => open,
		
        --framebuffer memory
        framebuffer_axi_m2s   => framebuffer_axi_m2s  ,
        framebuffer_axi_s2m   => framebuffer_axi_s2m  ,
        framebuffer_axi_wdata => framebuffer_axi_wdata,
        framebuffer_axi_rdata => framebuffer_axi_rdata

	);

    axi_bram_inst : entity work.axi_bram_model
    generic map(
		DATA_WIDTH        => DATA_WIDTH,
        BRAM_TEST_SIZE    => BRAM_TEST_SIZE
    )
    port map(
        aclk    => ddr_clk,
        areset  => reset,
        axi4_m2s_i => framebuffer_axi_m2s,
        axi4_s2m_o => framebuffer_axi_s2m,
        axi4_wdata => framebuffer_axi_wdata,
        axi4_rdata => framebuffer_axi_rdata
        
    );

	img_wr_inst : entity work.image_writer
	generic map(
	    o_file => "../matlab/AppTop/output.txt",
        DATA_WIDTH => 24,
        h_active   => h_active,
        v_active   => v_active
        
	)
	port map(
		clk      => pclk,
		enable   => reset_n,
        sof      => vga_sof,
        eol      => vga_eol,
        data     => vga_data,
        valid    => vga_valid,
        pic_err  => open,
        line_err => open,
        i_w      => image_written,
        i_w_cnt  => i_w_cnt

	);
    
    process(cam_pclk)
    begin
        if(rising_edge(cam_pclk)) then
            clk_count <= clk_count + 1;
            if(clk_count = to_unsigned(10,32)) then
                gen_en_a <= '1';
            end if;
            
            if(clk_count = to_unsigned(h_active*2 + 15,32)) then
                gen_en_b <= '1';
            end if;
        end if;
    end process;
    
    --comparison to counting data
    process(pclk)
    begin
        if(rising_edge(pclk)) then
            
            if(vga_valid = '1' and valid_note = '0') then
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
                --rst_dly(0) <= '1';
                --assert false report "Reset Active" severity note;
                --assert false report "Switching Pattern" severity note;
                --pattern <= "01";
            end if;
            
            if(sof_count = 10 and sof_toggle = '1') then
                rst_dly(0) <= '1';
                assert false report "Reset Active" severity note;
            end if;
   
            if(rst_dly(511) = '1') then
                reset_go <= (others => '1');
            end if;
      
            reset <= reset_go(127);

            
            if(reset = '1') then
                valid_note <= '0';
            end if;
            
            if(image_written = '1' and i_w_cnt = FINAL_IMG) then
                assert false report "Video Finished" severity failure;
            end if;
            
            if(reset = '1') then
                valid_note <= '0';
            end if;
            
        end if;
    end process;

    process
    begin
		wait;
    end process;
    
end test;