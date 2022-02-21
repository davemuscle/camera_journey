library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity cycloneV_debayer_demo is
	port(
		clk_board : in std_logic;
		led7 : out std_logic := '0';
		led6 : out std_logic := '0';
		led5 : out std_logic := '0';
		led4 : out std_logic := '0';
		led3 : out std_logic := '0';
		led2 : out std_logic := '0';
		led1 : out std_logic := '0';
		led0 : out std_logic := '0';
		
		key1 : in std_logic;
		key0 : in std_logic;
		
		sda : inout std_logic;
		scl : inout std_logic;
		
		vid_clk : out std_logic;
		hsync   : out std_logic;
		vsync   : out std_logic;
		de      : out std_logic;
		red     : out std_logic_vector(7 downto 0);
		grn     : out std_logic_vector(7 downto 0);
		blu     : out std_logic_vector(7 downto 0)

	);
end cycloneV_debayer_demo;

architecture arch of cycloneV_debayer_demo is 


	component video_pll is
	port(
		refclk : in std_logic;
		rst    : in std_logic;
		outclk_0 : out std_logic
	);
	end component video_pll;

	constant PIXEL_WIDTH : integer := 32;
	constant DATA_WIDTH : integer := 128;
	
	constant h_active     : integer := 1920;
	constant h_frontporch : integer := 88;
	constant h_syncwidth  : integer := 44;
	constant h_backporch  : integer := 148;
	constant h_total      : integer := 2200;
	
	constant v_active     : integer := 1080;
	constant v_frontporch : integer := 4;
	constant v_syncwidth  : integer := 5;
	constant v_backporch  : integer := 36;
	constant v_total      : integer := 1125; 

	
	--avalon
	signal avl_size : std_logic_vector(8 downto 0) := (others => '0');
	signal avl_waitrequest, avl_read, avl_write, avl_readdatavalid : std_logic := '0';
	signal avl_address : std_logic_vector(25 downto 0) := (others => '0');
	signal avl_readdata, avl_writedata : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	
	--fifo status
	signal afifo0_ov, afifo0_un, afifo1_ov, afifo1_un : std_logic := '0';
	
	--pixel data
	signal pixel_out_sof, pixel_out_eol : std_logic := '0';
	signal pixel_in_sof, pixel_in_eol : std_logic := '0';
	signal pixel_in, pixel_out : std_Logic_vector(PIXEL_WIDTH-1 downto 0) := (others => '0');
	signal pixel_in_valid, pixel_out_valid : std_logic := '0';
		
	signal en : std_logic := '0';
	signal red_in, grn_in, blu_in : std_logic_vector(7 downto 0) := (others => '0');
	signal valid_frm_in, sof_frm_in, eol_frm_in : std_logic := '0';
	
	signal reset, valid_in, eol_in, sof_in : std_logic := '0';
	signal data_in, data_out : std_logic_vector(23 downto 0) := (others => '0');
	
	signal start, init_done, init_busy : std_logic := '0';
	
	signal hpd_detect : std_logic := '0';
	
	signal pll_test_tgl : std_logic := '0';
	signal pll_test_cnt : integer := 0;
	
	signal pclk : std_logic := '0';
	signal sync_error : std_logic := '0';
	
	attribute keep : boolean;
	
	signal lockup_cnt : integer := 0;
	signal avl_read_latch : std_logic := '0';
	signal avl_write_latch : std_logic := '0';
	signal avl_size_latch : std_logic_vector(8 downto 0) := (others => '0');
	signal avl_address_latch : std_logic_vector(25 downto 0) := (others => '0');
	signal avl_read_dly, avl_write_dly : std_logic := '0';
	
	attribute keep of avl_read_latch, avl_write_latch, avl_size_latch, avl_address_latch : signal is true;
	
	signal h_active_CNT_IN, v_active_CNT_IN : integer := 0;
	signal pixel_in_cnt : integer := 0;
    
    signal raw_in : std_Logic_vector(7 downto 0) := (others => '0');
    
begin

	clocking: video_pll
	port map(
		refclk   => clk_board,
		rst      => '0',
		outclk_0 => pclk
	);
	

	--false path
	process(clk_board)
	begin
		if(rising_edge(clk_board)) then
			if(key1 = '0') then
				en <= '1';
			end if;
		end if;
	end process;

	reset <= not key0;


	-- --setup video input data, replace with camera later
	video_proc : entity work.vstream_demo_raw
	generic map(
	    h_active 	 => h_active 	,
	    h_frontporch => h_frontporch,
	    h_syncwidth  => h_syncwidth ,
	    h_backporch  => h_backporch ,
	    h_total      => h_total     ,
	    v_active     => v_active    ,
	    v_frontporch => v_frontporch,
	    v_syncwidth  => v_syncwidth ,
	    v_backporch  => v_backporch ,
	    v_total		 => v_total		
	)
	port map(
		clk    => pclk,
		enable => '1',
		
		raw => raw_in,
		
		valid => valid_frm_in,
		sof   => sof_frm_in,
		eol   => eol_frm_in

	);
	
    debayer_inst : entity work.debayer
	generic map(
		h_active   => h_active,
		h_total    => h_total,
		v_active   => v_active,
		v_total    => v_total
		)
	port map(
		clk => pclk,
        
        sof_i  => sof_frm_in,
        eol_i  => eol_frm_in,
        raw_i  => raw_in,
        valid_i => valid_frm_in,

        sof_o => sof_in,
        eol_o => eol_in,
        rgb_o => data_in,
        valid_o => valid_in
	);



	-- video_proc : entity work.vstream_demo
	-- generic map(
	    -- h_active 	 => h_active 	,
	    -- h_frontporch => h_frontporch,
	    -- h_syncwidth  => h_syncwidth ,
	    -- h_backporch  => h_backporch ,
	    -- h_total      => h_total     ,
	    -- v_active     => v_active    ,
	    -- v_frontporch => v_frontporch,
	    -- v_syncwidth  => v_syncwidth ,
	    -- v_backporch  => v_backporch ,
	    -- v_total		 => v_total		
	-- )
	-- port map(
		-- clk    => pclk,
		-- enable => '1',
		
		-- red    => red_in,
		-- grn    => grn_in,
		-- blu    => blu_in,
		
		-- valid => valid_in,
		-- sof   => sof_in,
		-- eol   => eol_in

	-- );
	
    -- data_in <= red_in & grn_in & blu_in;
    
	--convert video stream to vga output
	stream_converter : entity work.vstream2vga
	generic map(
		DATA_WIDTH   => 24,
		SYNC_POL     => '0',
	    h_active 	 => h_active 	,
	    h_frontporch => h_frontporch,
	    h_syncwidth  => h_syncwidth ,
	    h_backporch  => h_backporch ,
	    h_total      => h_total     ,
	    v_active     => v_active    ,
	    v_frontporch => v_frontporch,
	    v_syncwidth  => v_syncwidth ,
	    v_backporch  => v_backporch ,
	    v_total		 => v_total		
	)
	port map(
		clk => pclk,
		reset => reset,
		
		data_in    => data_in,
		valid_in   => valid_in,
		sof_in     => sof_in,
		eol_in     => eol_in,
		
		data_out   => data_out,
		hsync      => hsync,
		vsync      => vsync,
		de         => de,
		sync_error => sync_error

	);	
	
    red <= data_out(23 downto 16);
    grn <= data_out(15 downto 8);
    blu <= data_out(7 downto 0);
	
	led3 <= sync_error;
	
	vid_clk <= pclk;
	
    adv7513_hdmi_if_inst : entity work.adv7513_hdmi_if
	generic map(
		DEV_ADDR      => "0111001",
		HPD_CHECKRATE => 50000000,
		I2C_CLK_DIV   => 500      
	)
	port map(
    	clk => clk_board,

		--i2c pins
		sda => sda,
		scl => scl,
		
		--status signals
		hpd_detect_o => hpd_detect,
		init_done_o  => init_done,
		init_busy_o  => open
    );
	
	process(pclk)
	begin
		if(rising_edge(pclk)) then
			if(pll_test_cnt = 148500000-1) then
				pll_test_cnt <= 0;
				pll_test_tgl <= not pll_test_tgl;
			else
				pll_test_cnt <= pll_test_cnt + 1;
			end if;
		end if;
	end process;
	
	--led2 <= pll_test_tgl;
	
	--led1 <= init_done;
	--led0 <= hpd_detect;
	
end arch;