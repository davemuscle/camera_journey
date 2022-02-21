library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Wrapper containing the UART interface, OV5640 sccb if, OV5640 controller, a FIFO, and some glue logic
--Tested with 50 MHz input clock
--XCLK output is half the input clock (camera xclk = 25 MHz)

use work.ov5640_controller_pkg.all;

entity ov5640_wrapper is
    generic(
        I2C_CLK_DIV : integer := 500; --for 100 kHz at 50 MHz
        CLK_DIV_1ms : integer := 50000; --for 1 ms at 50 MHz
        SIM         : boolean := false;
        ENABLE_BOOT : boolean := true
    );
	port(
    	clk  : in  std_logic;
        
        --Register Control
        reg_camera_init_go   : in std_logic;  --rising edge initialize camera  
        reg_camera_init_sel  : in std_logic;  --0 = read boot ROM, 1 = read debug FIFO
        reg_camera_fid       : in std_logic;  --level, continuously read device id for i2c debug                
        
        reg_camera_addr : in std_logic_vector(15 downto 0);
        
        reg_camera_wr      : in std_logic;    --rising edge write to camera
        reg_camera_fifo_wr : in std_logic;    --rising edge write to dbg fifo
        reg_camera_wr_data : in std_logic_vector( 7 downto 0);
        
        reg_camera_rd      : in std_logic;  --rising edge read from camera
        reg_camera_rd_data : out std_logic_vector( 7 downto 0) := (others => '0');

        --Register Status
        reg_camera_init_done    : out std_logic := '0'; --level, displays done
        reg_boot_done           : out std_logic := '0';
        reg_cmd_busy            : out std_logic := '0';
        reg_pwr_up_done         : out std_logic := '0';

        frex             : in std_logic;

        --Reset ticks high when resetting camera via UART
        manual_reset     : out std_logic := '0';

        --Camera Serial Interface
        cam_sda   : inout std_logic;
		cam_scl   : inout std_logic;
        
        --Camera Interface
		cam_xclk_disable   : out std_logic := '1';
		cam_reset          : out std_logic;
		cam_pwdn           : out std_logic
		
    );
end ov5640_wrapper;

architecture str of ov5640_wrapper is 

	signal scl_o, scl_i, scl_t, sda_o, sda_i, sda_t : std_logic := '0';
	
	signal start : std_logic := '0';
	
	signal cmd, cmd_en, cmd_busy, cmd_busy_dly : std_logic := '0';

	signal pwdn_t : std_logic := '0';
	signal reset_t : std_logic := '0';

	signal xclk : std_logic := '0';
    signal xclk_half : std_logic := '0';
    
	signal force_id_read : std_logic := '0';
	signal pwr_up_start, pwr_up_done : std_logic := '0';
    
	signal base_addr : std_logic_vector(15 downto 0) := (others => '0');
	signal rd_data, wr_data : std_logic_vector(7 downto 0) := (others => '0');
    
    signal device_id_good, init_done : std_logic := '0';
    
    signal boot_start : std_logic := '0';
    signal boot_start_cnt : integer range 0 to CLK_DIV_1ms-1 := 0;
    signal boot_done : std_logic := '0';
    
    signal dbg_cmd_start : std_logic := '0';
    signal dbg_cmd_sel : std_logic := '0';

    signal uart_cam_wr_started : std_logic := '0';
    signal uart_cam_wr_queued : std_logic := '0';
    signal uart_cam_rd_started : std_logic := '0';
    signal uart_cam_rd_queued : std_logic := '0';
    
    signal dbg_fifo_wr : std_logic := '0';
    signal dbg_fifo_wr_data : std_logic_vector(23 downto 0) := (others => '0');
    signal dbg_fifo_rd : std_logic := '0';
    signal dbg_fifo_rd_data : std_logic_vector(23 downto 0) := (others => '0'); 
    signal dbg_fifo_empty : std_logic := '0';
    
    signal dbg_cmd_rd, dbg_cmd_wr : std_logic := '0';
    signal dbg_cmd_addr : std_logic_vector(15 downto 0) := (others => '0');
    signal dbg_cmd_wr_data, dbg_cmd_rd_data : std_logic_vector(7 downto 0) := (others => '0');

    signal reset_cnt : integer range 0 to 100*CLK_DIV_1ms-1;
    signal reset_en : std_logic := '0';
    
    signal reg_camera_init_go_d : std_logic := '0';
    signal reg_camera_wr_d : std_logic := '0';
    signal reg_camera_rd_d : std_logic := '0';
    signal reg_camera_fifo_wr_d : std_logic := '0';
    
begin
 
    --start the controller on boot
    process(clk)
    begin
        if(rising_edge(clk)) then
            if(ENABLE_BOOT = TRUE) then
                if(boot_done = '0') then
                    if(boot_start_cnt = CLK_DIV_1ms-1) then
                        boot_start <= '1';
                        boot_start_cnt <= 0;
                        boot_done <= '1';
                    else
                        boot_start <= '0';
                        boot_start_cnt <= boot_start_cnt + 1;
                        boot_done <= '0';
                    end if;
                else
                    boot_start_cnt <= 0;
                    boot_start <= '0';
                end if;     
            end if;
        end if;
    end process;
 
    start <= boot_start or dbg_cmd_start;
    
    --Must have been debugging the reset feature
    process(clk)
    begin
        if(rising_edge(clk)) then
            
            if(reset_en = '1' and init_done = '1') then
                if(reset_cnt = 1*CLK_DIV_1ms-1) then
                    reset_en <= '0';
                    reset_cnt <= 0;
                else
                    reset_cnt <= reset_cnt + 1;
                    reset_en <= '1';
                end if;             
            else
                reset_cnt <= 0;
            end if;
        
            --this should be a pulse
            if(dbg_cmd_start = '1') then
                
                reset_en <= '1';

            end if;
            
            manual_reset <= reset_en;
         
        end if;
    end process;
    
    --process(clk)
    --begin
    --    if(rising_edge(clk)) then
    --        --gating the xclk until the chip is ready is extremely important
    --        if(pwr_up_done = '1') then
    --            xclk <= not xclk;
    --        else
    --            xclk <= '0';
    --        end if;
    --    end if;
    --end process;

	--cam_xclk <= xclk;
	cam_xclk_disable <= not pwr_up_done;
    
    ctrl_inst : entity work.ov5640_controller
	generic map(
		CLK_DIV_10ms => 10*CLK_DIV_1ms
	)
	port map(
    	clk => clk,

		start => start,
        
        dbg_cmd_sel      => dbg_cmd_sel,
        dbg_fifo_en      => dbg_fifo_rd,
        dbg_fifo_addr    => dbg_fifo_rd_data(23 downto 8),
        dbg_fifo_wr_data => dbg_fifo_rd_data(7 downto 0),
        dbg_fifo_empty   => dbg_fifo_empty,
        
        dbg_cmd_rd      => dbg_cmd_rd,
        dbg_cmd_wr      => dbg_cmd_wr,
        dbg_cmd_addr    => dbg_cmd_addr,
        dbg_cmd_wr_data => dbg_cmd_wr_data,
        dbg_cmd_rd_data => dbg_cmd_rd_data,
        
		force_id_read => force_id_read,
		pwr_up_start  => pwr_up_start,
		pwr_up_done   => pwr_up_done,
		
		device_id_good => device_id_good,
		init_done      => init_done,
		
		cmd       => cmd,
		cmd_en    => cmd_en,
		cmd_busy  => cmd_busy,
		
		base_addr => base_addr,
		
		wr_data => wr_data,
		rd_data => rd_data
	);
    
    sccb_inst : entity work.ov5640_sccb
    generic map(
        CLK_DIV_4x => I2C_CLK_DIV/4,
        CLK_DIV_1ms => CLK_DIV_1ms
    )
    port map(
        clk   => clk,
        
        pwdn_reset_start => pwr_up_start,
        pwdn_o           => cam_pwdn,
        reset_o          => cam_reset,
        pwr_up_done      => pwr_up_done,
        
        cmd       => cmd,
        cmd_en    => cmd_en,
        cmd_busy  => cmd_busy,
        
        dev_addr  => "0111100",
        base_addr => base_addr,
        
        wr_data => wr_data,
        rd_data => rd_data,
        
        sda_o => sda_o,
        sda_i => sda_i,
        sda_t => sda_t,
        scl_o => scl_o,
        scl_i => scl_i,
        scl_t => scl_t

    );
    
	--i2c tristate buffer, pullup resistors
	cam_scl <= 'Z' when scl_t = '0' else scl_o;
	cam_sda <= 'Z' when sda_t = '0' else sda_o;
    
    GEN_PULLUPS: if SIM = true generate
        scl_i <= scl_o when scl_t = '1' else '1';
        sda_i <= sda_o when sda_t = '1' else '1';
    end generate GEN_PULLUPS;
    
    NO_GEN_PULLUPS: if SIM = false generate
        scl_i <= cam_scl;
        sda_i <= cam_sda;
    end generate NO_GEN_PULLUPS;

    
    reg_boot_done           <= boot_done;
    reg_cmd_busy            <= cmd_busy;
    reg_pwr_up_done         <= pwr_up_done;
    
    

    
    --logic for working with the register file
    process(clk)
    begin
        if(rising_edge(clk)) then
        
            --pulse
            dbg_cmd_start <= '0';
            
            --delay
            reg_camera_init_go_d <= reg_camera_init_go;
            reg_camera_wr_d      <= reg_camera_wr;
            reg_camera_rd_d      <= reg_camera_rd;
            reg_camera_fifo_wr_d <= reg_camera_fifo_wr;
        
            --start camera initizalization from register write
            if(reg_camera_init_go_d = '0' and reg_camera_init_go = '1') then
                dbg_cmd_start <= '1';
                dbg_cmd_sel   <= reg_camera_init_sel;
            end if;

            --queue write to camera
            if(reg_camera_wr_d = '0' and reg_camera_wr = '1') then
                dbg_cmd_addr       <= reg_camera_addr;
                dbg_cmd_wr_data    <= reg_camera_wr_data;
                uart_cam_wr_queued <= '1';
            end if;
            
            --queue read from camera
            if(reg_camera_rd_d = '0' and reg_camera_rd = '1') then
                dbg_cmd_addr       <= reg_camera_addr;
                uart_cam_rd_queued <= '1';
            end if;            
            
            --write into dbg fifo
            dbg_fifo_wr <= '0';
            if(reg_camera_fifo_wr_d = '0' and reg_camera_fifo_wr = '1') then
                dbg_fifo_wr <= '1';
                dbg_fifo_wr_data <= reg_camera_addr & reg_camera_wr_data;
            end if;
            
            force_id_read <= reg_camera_fid;

            
            cmd_busy_dly <= cmd_busy;

            if(uart_cam_wr_queued = '1' and cmd_busy = '0') then
                uart_cam_wr_queued <= '0';
                uart_cam_wr_started <= '1';
                dbg_cmd_wr <= '1';
            end if;
            
            if(uart_cam_rd_queued = '1' and cmd_busy = '0') then
                uart_cam_rd_queued <= '0';
                uart_cam_rd_started <= '1';
                dbg_cmd_rd <= '1';
            end if;
         
            if(cmd_busy = '1') then
                dbg_cmd_wr <= '0';
                dbg_cmd_rd <= '0';
            end if;
            

            
            if(uart_cam_wr_started = '1' and cmd_busy_dly = '1' and cmd_busy = '0') then
                uart_cam_wr_started <= '0';
            end if;
  
            if(uart_cam_rd_started = '1' and cmd_busy_dly = '1' and cmd_busy = '0') then
                uart_cam_rd_started <= '0';
                reg_camera_rd_data <= dbg_cmd_rd_data;
            end if;
            
            reg_camera_init_done <= init_done;
            
            
        
        end if;
    end process;
    
    --Synchronous FIFO for holding debugger write sequence to camera
 	--Rx FIFO
	dbg_fifo_inst : entity work.sync_fifo
	generic map(
		gDEPTH => 512, 
		gWIDTH => 24, 
		gOREGS => 0, 
		gPF    => 0, 
		gPE    => 0
	)
	port map(
		clk     => clk,
        reset   => '0',
		wr_en   => dbg_fifo_wr,
		wr_data => dbg_fifo_wr_data,
		rd_en   => dbg_fifo_rd,
		rd_data => dbg_fifo_rd_data,
		ff      => open,
		fe      => dbg_fifo_empty,
		pf      => open,
		pe      => open,
		ov      => open,
		un      => open
	);	   

end str;