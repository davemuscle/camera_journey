library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

--Register mappings are done within comments embedded in the code
--The code is parsed to create Python classes for easy access

entity camera_bridge_top_regfile is
	port(
		clk     : in std_logic;
        ddr_clk : in std_logic;
        
        --Register Mapping to UART debugger
        rm_wr_en    : in  std_logic;                            
        rm_rd_en    : in  std_logic;                            
        rm_rd_valid : out std_logic := '0';                                       
        rm_addr     : in  std_logic_vector(15 downto 0);
        rm_wr_data  : in  std_logic_vector(31 downto 0);
        rm_rd_data  : out std_logic_vector(31 downto 0) := (others => '0');                    
        
        --Camera Registers
        reg_camera_init_go      : out std_logic_vector(1 downto 0) := "00"; 
        reg_camera_init_sel     : out std_logic_vector(1 downto 0) := "00"; 
        reg_camera_fid          : out std_logic_vector(1 downto 0) := "00";
        reg_camera_addr         : out std_logic_vector(31 downto 0) := (others => '0');        
        reg_camera_wr           : out std_logic_vector(1 downto 0) := "00";   
        reg_camera_fifo_wr      : out std_logic_vector(1 downto 0) := "00";  
        reg_camera_wr_data      : out std_logic_vector(15 downto 0) := (others => '0');
        reg_camera_rd           : out std_logic_vector(1 downto 0) := "00"; 
        reg_camera_rd_data      : in  std_logic_vector(15 downto 0) := (others => '0');
        reg_camera_init_done    : in  std_logic_vector(1 downto 0);
        reg_camera_boot_done    : in  std_logic_vector(1 downto 0);
        reg_camera_cmd_busy     : in  std_logic_vector(1 downto 0);
        reg_camera_pwr_up_done  : in  std_logic_vector(1 downto 0);
        reg_camera_pclk_freq    : in  std_logic_vector(63 downto 0);

        --Video Pipe Registers
        reg_vp_reset          : out std_logic := '0';
        reg_vp_cam_mux        : out std_logic := '0';
        reg_vp_frm_mux        : out std_logic := '0';
        reg_vp_dem_mux        : out std_logic := '0';
        reg_vp_debayer_mode   : out std_logic_vector(1 downto 0) := (others => '0');
        reg_vp_debayer_bypass : out std_logic := '0';
        reg_vp_camera_select  : out std_logic := '0';
        
        --FrameBuffer Registers
        reg_ufifo_ov_sticky       : in  std_logic;
        reg_ufifo_un_sticky       : in  std_logic;
        reg_dfifo_ov_sticky       : in  std_logic;
        reg_dfifo_un_sticky       : in  std_logic;
        reg_read_time             : in  std_logic_vector(11 downto 0);
        reg_write_time            : in  std_logic_vector(11 downto 0);
        reg_request_error         : in  std_logic;
        reg_load_error            : in  std_logic;
        reg_timeout_error         : in  std_logic;
        --FrameBuffer Fx Registers
        reg_vert_bypass           : out std_logic := '0';
        reg_vert_splitscreen      : out std_logic := '0';
        reg_vert_splitscreen_type : out std_logic_vector(5 downto 0) := (others => '0');
        reg_vert_flip             : out std_logic := '0';
        reg_vert_mirror           : out std_logic := '0';
        reg_vert_scroll           : out std_logic := '0';
        reg_vert_scroll_offset    : out std_logic_vector(11 downto 0) := (others => '0');
        reg_horz_bypass           : out std_logic := '0';
        reg_horz_splitscreen      : out std_logic := '0';
        reg_horz_splitscreen_type : out std_logic_vector(5 downto 0) := (others => '0');
        reg_horz_flip             : out std_logic := '0';
        reg_horz_mirror           : out std_logic := '0';
        reg_horz_scroll           : out std_logic := '0';
        reg_horz_scroll_offset    : out std_logic_vector(11 downto 0) := (others => '0')

        
	);
end camera_bridge_top_regfile;

architecture bhv of camera_bridge_top_regfile is 

    constant id : std_logic_vector(31 downto 0) := x"DEADBEEF";
    signal   scratchpad : std_logic_vector(31 downto 0) := (others => '0');
 
    signal int_camera_init_go      : std_logic_vector(1 downto 0) := "00"; 
    signal int_camera_init_sel     : std_logic_vector(1 downto 0) := "00"; 
    signal int_camera_fid          : std_logic_vector(1 downto 0) := "00";               
    signal int_camera_wr           : std_logic_vector(1 downto 0) := "00";   
    signal int_camera_rd           : std_logic_vector(1 downto 0) := "00";   
    signal int_camera_fifo_wr      : std_logic_vector(1 downto 0) := "00";  
    signal int_camera_addr         : std_logic_vector(31 downto 0) := (others => '0');
    signal int_camera_wr_data      : std_logic_vector(15 downto 0) := (others => '0');
    
    signal int_vp_reset        : std_logic := '0';
    signal int_vp_cam_mux      : std_logic := '0';
    signal int_vp_frm_mux      : std_logic := '0';
    signal int_vp_dem_mux      : std_logic := '0';
    signal int_vp_debayer_mode : std_logic_vector(1 downto 0) := (others => '0');
    signal int_vp_debayer_bypass : std_logic := '0';
    signal int_vp_camera_select : std_logic := '0';
    
    signal int_vert_bypass           : std_logic := '0';
    signal int_vert_splitscreen      : std_logic := '0';
    signal int_vert_splitscreen_type : std_logic_vector(5 downto 0) := (others => '0');
    signal int_vert_flip             : std_logic := '0';
    signal int_vert_mirror           : std_logic := '0';
    signal int_vert_scroll           : std_logic := '0';
    signal int_vert_scroll_offset    : std_logic_vector(11 downto 0) := (others => '0');
    signal int_horz_bypass           : std_logic := '0';
    signal int_horz_splitscreen      : std_logic := '0';
    signal int_horz_splitscreen_type : std_logic_vector(5 downto 0) := (others => '0');
    signal int_horz_flip             : std_logic := '0';
    signal int_horz_mirror           : std_logic := '0';
    signal int_horz_scroll           : std_logic := '0';
    signal int_horz_scroll_offset    : std_logic_vector(11 downto 0) := (others => '0');
 
    signal int_framebuffer_fx_latch       : std_logic := '0';
    signal int_framebuffer_fx_latch_sync  : std_logic := '0';
 
begin
    
    reg_camera_init_go  <= int_camera_init_go;
    reg_camera_init_sel <= int_camera_init_sel;
    reg_camera_fid      <= int_camera_fid;
    
    reg_camera_addr    <= int_camera_addr;
    reg_camera_wr_data <= int_camera_wr_data;
    
    reg_camera_wr      <= int_camera_wr;
    reg_camera_fifo_wr <= int_camera_fifo_wr;
    
    reg_camera_rd      <= int_camera_rd;
    
    reg_vp_reset        <= int_vp_reset       ;
    reg_vp_cam_mux      <= int_vp_cam_mux     ;
    reg_vp_frm_mux      <= int_vp_frm_mux     ;
    reg_vp_dem_mux      <= int_vp_dem_mux     ;
    reg_vp_debayer_mode <= int_vp_debayer_mode;
    reg_vp_debayer_bypass <= int_vp_debayer_bypass;
    reg_vp_camera_select <= int_vp_camera_select;
    
    process(clk)
    begin
        if(rising_edge(clk)) then

            --Force pulses
            int_camera_init_go <= "00";
            
            int_camera_wr      <= "00";
            int_camera_fifo_wr <= "00";
            int_camera_rd      <= "00";
            
            int_framebuffer_fx_latch <= '0';
            
            rm_rd_valid <= '0';
            
            --chip select
            if(rm_wr_en = '1' or rm_rd_en = '1') then
                
                --read defaults
                if(rm_rd_en = '1') then
                    rm_rd_valid <= '1';
                    rm_rd_data  <= (others => '0');
                end if;
            
                --main switch
                case rm_addr is
                    when x"0000" =>
                        --[@REG@ ID] [0x0000] [FPGA ID] [RO]
                        --@[31:0] FPGA_ID
                        --        Read only FPGA identification, always set to 0xDEADBEEF
                        --[@DNE@]
                        if(rm_rd_en = '1') then
                            rm_rd_data <= id;
                        end if;
                    when x"0001" =>
                        --[@REG@ Scratchpad] [0x0001] [Scratchpad] [RW]
                        --@[31:0] Scratchpad
                        --        Scratchpad data for testing reads and writes
                        --[@DNE@]
                        if(rm_wr_en = '1') then
                            scratchpad <= rm_wr_data;
                        else
                            rm_rd_data <= scratchpad;
                        end if;
                    when x"0002" =>
                        --[@REG@ CameraControl] [0x0002] [Camera Control and Status] [RW]
                        -- @[1:0] InitGo
                        --      Assert a rising edge to initalize the camera 
                        --      Cleared by the FPGA
                        --      LSB is for CameraA
                        --      MSB is for CameraB
                        -- @[3:2] InitSelect
                        --      0 to initialize camera from boot ROM
                        --      1 to initialize camera from FIFO
                        --      LSB is for CameraA
                        --      MSB is for CameraB
                        -- @[5:4] ForceID
                        --      Assert to force continually reading the device ID over I2C
                        --      LSB is for CameraA
                        --      MSB is for CameraB
                        --@[7:6] EnableWrite
                        --      Rising edge to assert a write command over SCCB interface
                        --      Cleared by the FPGA
                        --      LSB is for CameraA
                        --      MSB is for CameraB
                        -- @[9:8] EnableWriteFIFO
                        --      Rising edge to add the write command to FIFO init sequence
                        --      Cleared by the FPGA
                        --      LSB is for CameraA
                        --      MSB is for CameraB
                        -- @[11:10] EnableRead
                        --      Rising edge to assert read command over SCCB interface
                        --      Cleared by the FPGA
                        --      LSB is for CameraA
                        --      MSB is for CameraB
                        -- @[13:12] InitDone
                        --      Set by the FPGA after the camera has been initialized
                        --      Writes have no effect
                        -- @[15:14] BootDone
                        --      Set by the FPGA shortly after a power up timer
                        --      Writes have no effect
                        -- @[17:16] CmdBusy
                        --      Bit to show the camera state machine is processing a command
                        --      Writes have no effect
                        -- @[19:18] PwrUpDone
                        --      Set by the FPGA SCCB interface after the camera has been powered on
                        --      Writes have no effect
                        --[@DNE@]
                        if(rm_wr_en = '1') then
                            int_camera_init_go  <= rm_wr_data( 1 downto  0);
                            int_camera_init_sel <= rm_wr_data( 3 downto  2);
                            int_camera_fid      <= rm_wr_data( 5 downto  4);
                            int_camera_wr       <= rm_wr_data( 7 downto  6);
                            int_camera_fifo_wr  <= rm_wr_data( 9 downto  8);
                            int_camera_rd       <= rm_wr_data(11 downto 10);
                        else
                            rm_rd_data( 3 downto  2) <= int_camera_init_sel;
                            rm_rd_data( 5 downto  4) <= int_camera_fid;
                            rm_rd_data(13 downto 12) <= reg_camera_init_done;   
                            rm_rd_data(15 downto 14) <= reg_camera_boot_done;          
                            rm_rd_data(17 downto 16) <= reg_camera_cmd_busy;           
                            rm_rd_data(19 downto 18) <= reg_camera_pwr_up_done;   
                        end if;
                        
                    when x"0003" =>
                        --[@REG@ CameraData] [0x0003] [Camera Command Data] [RW]
                        -- @[7:0] DataWriteCameraA
                        --      Data sent to the OV5640 over the SCCB interface
                        -- @[15:8] DataReadCameraA
                        --      Data sent from the OV5640 over the SCCB interface
                        -- @[23:16] DataWriteCameraB
                        --      Data sent to the OV5640 over the SCCB interface
                        -- @[31:24] DataReadCameraB
                        --      Data sent from the OV5640 over the SCCB interface
                        --[@DNE@]
                        if(rm_wr_en = '1') then
                            int_camera_wr_data( 7 downto 0) <= rm_wr_data( 7 downto  0);
                            int_camera_wr_data(15 downto 8) <= rm_wr_data(23 downto 16);
                        else
                            rm_rd_data(7 downto 0)   <= int_camera_wr_data(7 downto 0);
                            rm_rd_data(15 downto 8)  <= reg_camera_rd_data(7 downto 0);
                            rm_rd_data(23 downto 16) <= int_camera_wr_data(15 downto 8);
                            rm_rd_data(31 downto 24) <= reg_camera_rd_data(15 downto 8);
                        end if;
                    when x"0004" =>
                        --[@REG@ CameraAddress] [0x0004] [Camera Command Adderss] [RW]
                        -- @[15:0] AddressCameraA
                        --      Address sent to the OV5640 over the SCCB interface 
                        -- @[31:0] AddressCameraB
                        --      Address sent to the OV5640 over the SCCB interface 
                        --[@DNE@]
                        if(rm_wr_en = '1') then
                            int_camera_addr <= rm_wr_data;
                        else
                            rm_rd_data <= int_camera_addr;
                        end if;
                    
                    when x"0005" =>
                        --[@REG@ VideoPipe] [0x0005] [VideoPipe Control] [RW]
                        -- @[0] Reset
                        --      Active high reset for video components
                        -- @[1] CameraMux
                        --      0 - Send Camera Data into Framebuffer
                        --      1 - Send Test Pattern into Framebuffer
                        -- @[2] FrameBufferMux
                        --      0 - Send FrameBuffer Data into Demosaic
                        --      1 - Send Test Pattern into Demosaic
                        -- @[3] DemosaicMux
                        --      0 - Send Demosaic Data Downstream
                        --      1 - Send Test Pattern Downstream
                        -- @[5:4] DemosaicPattern
                        --   Mode 0:        Mode 1:      Mode 2:      Mode 3:
                        -- |  B G . . |   | G B . . |  | G R . . |  | R G . . |
                        -- |  G R . . |   | R G . . |  | B G . . |  | G B . . |
                        -- @[6] DemosiacBypass
                        --      Active high to pass through the debayer buffering + math
                        -- @[7] CameraSelect
                        --      0 for CameraA
                        --      1 for CameraB
                        --[@DNE@]
                        if(rm_wr_en = '1') then
                            int_vp_reset        <= rm_wr_data(0);
                            int_vp_cam_mux      <= rm_wr_data(1);
                            int_vp_frm_mux      <= rm_wr_data(2);
                            int_vp_dem_mux      <= rm_wr_data(3);
                            int_vp_debayer_mode <= rm_wr_data(5 downto 4);
                            int_vp_debayer_bypass <= rm_wr_data(6);
                            int_vp_camera_select <= rm_wr_data(7);
                        else
                            rm_rd_data(0)          <= int_vp_reset        ;
                            rm_rd_data(1)          <= int_vp_cam_mux      ; 
                            rm_rd_data(2)          <= int_vp_frm_mux      ;
                            rm_rd_data(3)          <= int_vp_dem_mux      ;
                            rm_rd_data(5 downto 4) <= int_vp_debayer_mode ;
                            rm_rd_data(6)          <= int_vp_debayer_bypass;
                            rm_rd_data(7)          <= int_vp_camera_select;
                        end if;
                    when x"0006" =>
                        --[@REG@ FrameBufferControl] [0x0006] [FrameBuffer Control and Status] [RW]
                        -- @[0] UfifoOv
                        --      Upstream Async FIFO Overflow Sticky Bit (1 = bad)
                        -- @[1] UfifoUn
                        --      Upstream Async FIFO Underflow Sticky Bit (1 = bad)
                        -- @[2] DfifoOv
                        --      Downstream Async FIFO Overflow Sticky Bit (1 = bad)
                        -- @[3] DfifoUn
                        --      Downstream Async FIFO Underflow Sticky Bit (1 = bad)
                        -- @[4] LoadError
                        --      Arbiter Load Error Sticky Bit (1 = bad)
                        -- @[5] RequestError
                        --      Arbiter Request Error Sticky Bit (1 = bad)
                        -- @[6] TimeoutError
                        --      Arbiter Timeout Error Sticky Bit (1 = bad)
                        -- @[7] FxLatch
                        --      Latch in the parameters for the horizontal and vertical addressing modes
                        --      Reads will return zeros
                        -- @[19:8] DatamoverReadTime
                        --      Number of clocks it took the datamover to perform a line read
                        --      Prone to metastability so take averages
                        -- @[31:20] DatamoverWriteTime
                        --      Number of clocks it took the datamover to perform a line write
                        --      Prone to metastability so take averages

                        --[@DNE@]
                        
                        if(rm_wr_en = '1') then
                            int_framebuffer_fx_latch <= rm_wr_data(7);
                        else
                            rm_rd_data(0) <= reg_ufifo_ov_sticky;
                            rm_rd_data(1) <= reg_ufifo_un_sticky;
                            rm_rd_data(2) <= reg_dfifo_ov_sticky;
                            rm_rd_data(3) <= reg_dfifo_un_sticky;
                            
                            rm_rd_data(4) <= reg_load_error;
                            rm_rd_data(5) <= reg_request_error;
                            rm_rd_data(6) <= reg_timeout_error;
                            
                            rm_rd_data(19 downto  8) <= reg_read_time;
                            rm_rd_data(31 downto 20) <= reg_write_time;
                        end if;
                    when x"0007" =>
                        --[@REG@ FrameBufferVert] [0x0007] [FrameBuffer Vertical Fx] [RW]
                        -- @[0] Bypass
                        --      Overrides any vertical or horizontal addressing effects
                        -- @[1] SplitScreen
                        --      Enables splitscreen mode
                        -- @[7:2] SplitScreenType
                        --      Set to how many screens to split into minus 1
                        --      Eg: 0 for 1 screen, 1 for 2 screens (max 64)
                        -- @[8] Flip
                        --      Enables flipped addressing
                        -- @[9] Mirror
                        --      Enables a mirror effect when in splitscreen mode
                        -- @[10] Scroll
                        --      Enables an addressing offset "scroll" effect
                        -- @[22:11] ScrollOffset
                        --      How far to scroll in terms of lines (vertical) or pixels (horizontal)
                        --[@DNE@]  
                        if(rm_wr_en = '1') then
                            int_vert_bypass           <= rm_wr_data(0);
                            int_vert_splitscreen      <= rm_wr_data(1);
                            int_vert_splitscreen_type <= rm_wr_data(7 downto 2);
                            int_vert_flip             <= rm_wr_data(8);
                            int_vert_mirror           <= rm_wr_data(9);
                            int_vert_scroll           <= rm_wr_data(10);
                            int_vert_scroll_offset    <= rm_wr_data(22 downto 11);
                        else
                            rm_rd_data(0)            <= int_vert_bypass          ; 
                            rm_rd_data(1)            <= int_vert_splitscreen     ; 
                            rm_rd_data(7 downto 2)   <= int_vert_splitscreen_type; 
                            rm_rd_data(8)            <= int_vert_flip            ; 
                            rm_rd_data(9)            <= int_vert_mirror          ; 
                            rm_rd_data(10)           <= int_vert_scroll          ; 
                            rm_rd_data(22 downto 11) <= int_vert_scroll_offset   ; 
                        end if;
                    when x"0008" =>
                        --[@REG@ FrameBufferHorz] [0x0008] [FrameBuffer Horizontal Fx] [RW]
                        -- @[0] Bypass
                        --      Overrides any vertical or horizontal addressing effects
                        -- @[1] SplitScreen
                        --      Enables splitscreen mode
                        -- @[7:2] SplitScreenType
                        --      Set to how many screens to split into minus 1
                        --      Eg: 0 for 1 screen, 1 for 2 screens (max 64)
                        -- @[8] Flip
                        --      Enables flipped addressing
                        -- @[9] Mirror
                        --      Enables a mirror effect when in splitscreen mode
                        -- @[10] Scroll
                        --      Enables an addressing offset "scroll" effect
                        -- @[22:11] ScrollOffset
                        --      How far to scroll in terms of lines (vertical) or pixels (horizontal)
                        --[@DNE@]  
                        if(rm_wr_en = '1') then
                            int_horz_bypass           <= rm_wr_data(0);
                            int_horz_splitscreen      <= rm_wr_data(1);
                            int_horz_splitscreen_type <= rm_wr_data(7 downto 2);
                            int_horz_flip             <= rm_wr_data(8);
                            int_horz_mirror           <= rm_wr_data(9);
                            int_horz_scroll           <= rm_wr_data(10);
                            int_horz_scroll_offset    <= rm_wr_data(22 downto 11);
                        else
                            rm_rd_data(0)            <= int_horz_bypass          ; 
                            rm_rd_data(1)            <= int_horz_splitscreen     ; 
                            rm_rd_data(7 downto 2)   <= int_horz_splitscreen_type; 
                            rm_rd_data(8)            <= int_horz_flip            ; 
                            rm_rd_data(9)            <= int_horz_mirror          ; 
                            rm_rd_data(10)           <= int_horz_scroll          ; 
                            rm_rd_data(22 downto 11) <= int_horz_scroll_offset   ; 
                        end if;
                    when x"0009" =>
                        --[@REG@ CameraFreqA] [0x0009] [Camera A Pixel Clock Frequency] [RO]
                        -- @[31:0] FreqA
                        --      Camera A PCLK Frequency
                        --[@DNE@]  
                        if(rm_wr_en = '0') then
                            rm_rd_data <= reg_camera_pclk_freq(31 downto 0);
                        end if;
                    when x"000A" =>
                        --[@REG@ CameraFreqB] [0x000A] [Camera B Pixel Clock Frequency] [RO]
                        -- @[31:0] FreqB
                        --      Camera B PCLK Frequency
                        --[@DNE@]  
                        if(rm_wr_en = '0') then
                            rm_rd_data <= reg_camera_pclk_freq(63 downto 32);
                        end if;
                    when others =>               
                    end case;
            end if;
        
        end if;
    
    end process;
    
    framebuffer_fx_pulse_sync : entity work.pulse_sync_handshake
    port map(
        clk_a   => clk,
        pulse_a => int_framebuffer_fx_latch,
        busy_a  => open,
        clk_b   => ddr_clk,
        pulse_b => int_framebuffer_fx_latch_sync
    );
    
    --FrameBuffer Fx Latching
    process(ddr_clk)
    begin
        if(rising_edge(ddr_clk)) then
            if(int_framebuffer_fx_latch_sync = '1') then
                
                reg_vert_bypass           <= int_vert_bypass          ;
                reg_vert_splitscreen      <= int_vert_splitscreen     ;
                reg_vert_splitscreen_type <= int_vert_splitscreen_type;
                reg_vert_flip             <= int_vert_flip            ;
                reg_vert_mirror           <= int_vert_mirror          ;
                reg_vert_scroll           <= int_vert_scroll          ;
                reg_vert_scroll_offset    <= int_vert_scroll_offset   ;
                reg_horz_bypass           <= int_horz_bypass          ;
                reg_horz_splitscreen      <= int_horz_splitscreen     ;
                reg_horz_splitscreen_type <= int_horz_splitscreen_type;
                reg_horz_flip             <= int_horz_flip            ;
                reg_horz_mirror           <= int_horz_mirror          ;
                reg_horz_scroll           <= int_horz_scroll          ;
                reg_horz_scroll_offset    <= int_horz_scroll_offset   ;
  
            end if;
        end if;
    end process;

end bhv;		

