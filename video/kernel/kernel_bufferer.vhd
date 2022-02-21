library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
--Dave Muscle

--Kernel Bufferer
--Holds a few lines of video, then outputs pixel data concurrently for kernel operations
--Only supports square matrices >= 3
--Only tested for 3x3 and 5x5

--Applies zeroing on the edges

--For a 3x3 sliding kernel, returns data like this:
--Rolled vector is formatted as [matrix(2)(2), matrix(2)(1), etc...matrix(0)(1), matrix(0)(0)]
--matrix(0)(0), the oldest pixel, is here in the 3x3 sliding kernel:
-- [ o x x ]
-- [ x x x ]
-- [ x x x ]
--matrix(2)(2), the newest pixel, is here in a 3x3 sliding kernel:
-- [ x x x ]
-- [ x x x ]
-- [ x x o ]

--This is so that the newest pixel, z, matches how the kernel will slide over the image

entity kernel_bufferer is
	generic(
		DATA_WIDTH  : integer := 24;
        MATRIX_SIZE : integer := 5;
		H_ACTIVE    : integer := 1920;
		V_ACTIVE    : integer := 1080
		);
	port(
	    clk   : in std_logic;
		reset : in std_logic;
        
        sof_i : in std_logic;
        eol_i : in std_logic;
        vld_i : in std_logic;
        dat_i : in std_logic_vector(DATA_WIDTH-1 downto 0);
        
        sof_o : out std_logic := '0';
        eol_o : out std_logic := '0';
        vld_o : out std_logic := '0';
        dat_o : out std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
        dat_r : out std_logic_vector(MATRIX_SIZE*MATRIX_SIZE*DATA_WIDTH-1 downto 0) := (others => '0');
        
        fifo_error      : out std_logic := '0';
        bootstrap_error : out std_logic := '0'
		
        );
end kernel_bufferer;

architecture arch of kernel_bufferer is 

    --Constants
    constant FIFO_WIDTH         : integer := DATA_WIDTH+3;
    constant HALF_POINT         : integer := integer(floor(real(MATRIX_SIZE)/2.0));
    constant LINES_TO_BOOTSTRAP : unsigned(11 downto 0) := to_unsigned(HALF_POINT,12);
    
    signal reset_meta, reset_sync : std_logic := '0';
  
    type matrix_col is array(1 to MATRIX_SIZE-1) of std_logic_vector(FIFO_WIDTH-1 downto 0);
    type matrix_row is array(0 to MATRIX_SIZE-1) of matrix_col;
    
    signal matrix : matrix_row := (others => (others => (others => '0')));
 
    signal sof_i_reg : std_logic := '0';
    signal eol_i_reg : std_logic := '0';
    signal vld_i_reg : std_logic := '0';
    signal dat_i_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    signal fifo_rd_en   : std_logic_vector(MATRIX_SIZE-2  downto 0) := (others => '0');
    signal fifo_rd_en_dly : std_logic_vector(MATRIX_SIZE-2  downto 0) := (others => '0');
    signal fifo_wr_en   : std_logic_vector(MATRIX_SIZE-2  downto 0) := (others => '0');
    type   fifo_data_array is array(0 to MATRIX_SIZE-2) of std_logic_vector(FIFO_WIDTH-1 downto 0);
    signal fifo_rd_data : fifo_data_array := (others => (others => '0'));
    signal fifo_wr_data : fifo_data_array := (others => (others => '0'));
    
    signal fifo_wr_mask : std_logic_vector(MATRIX_SIZE-1 downto 0) := (others => '0');
    signal fifo_line_en : std_logic_vector(MATRIX_SIZE-1 downto 0) := (others => '0');
    
    constant STAT_ZEROS : std_logic_vector(MATRIX_SIZE-2 downto 0) := (others => '0');
    signal ov : std_logic_vector(MATRIX_SIZE-2 downto 0) := (others => '0');
    signal un : std_logic_vector(MATRIX_SIZE-2 downto 0) := (others => '0');

    type matrix_ocol is array(0 to MATRIX_SIZE-1) of std_logic_vector(FIFO_WIDTH-1 downto 0);
    type matrix_orow is array(0 to MATRIX_SIZE-1) of matrix_ocol;
    
    signal matrix_o : matrix_orow := (others => (others => (others => '0')));

    signal bootstrap_active_cnt    : unsigned(11 downto 0) := (others => '0');
    signal bootstrap_blank_cnt     : unsigned(11 downto 0) := (others => '0');
    signal bootstrap_active_cnt_en : std_logic := '0';
    signal bootstrap_blank_cnt_en  : std_logic := '0';
    signal bootstrap_sof_en        : std_logic := '0';
    signal bootstrap_det_cnt       : unsigned(11 downto 0) := (others => '0');
    signal bootstrap_det_en        : std_logic := '0';
    signal bootstrap_go            : std_logic := '0';
    
    signal bootstrap_wr_mask       : std_logic_vector(MATRIX_SIZE-1 downto 0) := (others => '0');
    
    signal bootstrap_compare_en : std_logic := '0';
    signal bootstrap_active_cnt_prev : unsigned(11 downto 0) := (others => '0');
    signal bootstrap_blank_cnt_prev : unsigned(11 downto 0) := (others => '0');
    
    signal xh_cnt : unsigned(11 downto 0) := (others => '0');
    signal xv_cnt : unsigned(11 downto 0) := (others => '0');

    signal bootstrap : std_logic := '0';
    
    signal input_reg : std_logic_vector(DATA_WIDTH+3-1 downto 0) := (others => '0');
    
    signal sof_b : std_logic := '0';
    signal eol_b : std_logic := '0';
    signal vld_b : std_logic := '0';
    
    signal sof_b_reg : std_logic := '0';
    signal eol_b_reg : std_logic := '0';
    signal vld_b_reg : std_logic := '0';
    
    signal first : std_logic := '0';
    
    signal vcnt : unsigned(11 downto 0) := (others => '0');
    signal hcnt : unsigned(11 downto 0) := (others => '0');
    
    --0dt0 for 3x3, 1dt0 for 5x5
    signal lef_edge_kill : std_logic_vector(HALF_POINT-1 downto 0) := (others => '0'); 
    signal top_edge_kill : std_logic_vector(HALF_POINT-1 downto 0) := (others => '0'); 

    --2dt2 for 3x3, 4dt3 for 5x5
    signal rig_edge_kill : std_logic_vector(MATRIX_SIZE-1 downto HALF_POINT+1) := (others => '0'); 
    signal bot_edge_kill : std_logic_vector(MATRIX_SIZE-1 downto HALF_POINT+1) := (others => '0');
    
    signal matrix_t : matrix_orow := (others => (others => (others => '0')));
    signal matrix_d : matrix_orow := (others => (others => (others => '0')));
    signal matrix_z : matrix_orow := (others => (others => (others => '0')));


begin	

	process(clk)
	begin
		if(rising_edge(clk)) then
        
            --Register inputs
            sof_i_reg <= sof_i;
            eol_i_reg <= eol_i;
            vld_i_reg <= vld_i;
            dat_i_reg <= dat_i;
     
            input_reg <= sof_i_reg & eol_i_reg & vld_i_reg & dat_i_reg;

            --Shift register for enabling writes into the FIFOs
            fifo_wr_mask <= fifo_wr_mask(MATRIX_SIZE-2 downto 0) & (vld_i_reg or bootstrap);
            
            --Shift register for enabling the entire FIFO to be active
            --We don't need the FIFO until we load HALF_POINT lines
            if(eol_i_reg = '1' and vld_i_reg = '1') then
                fifo_line_en <= fifo_line_en(MATRIX_SIZE-2 downto 0) & '1';
            end if;
            
            --Delay the FIFO rd a clock cycle
            --This is necessary to mask off the metadata in the matrix to prevent unwanted writes
            fifo_rd_en_dly <= fifo_rd_en;

            --Count the number of clocks between the SOF and the EOL
            --With this method, the count increases on the EOL
            if(sof_i_reg = '1') then
                bootstrap_active_cnt    <= (0 => '1', others => '0');
                bootstrap_active_cnt_en <= '1';
                bootstrap_sof_en        <= '1';
            end if;
            if(bootstrap_active_cnt_en = '1') then
                bootstrap_active_cnt <= bootstrap_active_cnt+1; 
            end if;
            if(eol_i_reg = '1') then
                bootstrap_active_cnt_en <= '0';
            end if;
            
            --Count the number of clocks between the falling and rising edge of valid
            --With this method, the count does not increase on the rising edge
            if(vld_i_reg = '1' and vld_i = '0' and bootstrap_sof_en = '1') then
                bootstrap_blank_cnt    <= (0 => '1', others => '0');
                bootstrap_blank_cnt_en <= '1';
            end if;
            if(vld_i_reg = '0' and vld_i = '1' and bootstrap_sof_en = '1') then
                bootstrap_blank_cnt_en <= '0';
                bootstrap_sof_en       <= '0';
                bootstrap_det_cnt      <= bootstrap_blank_cnt;
                bootstrap_det_en       <= '1';
                
                --error detection
                bootstrap_compare_en      <= '1';
                bootstrap_active_cnt_prev <= bootstrap_active_cnt;
                bootstrap_blank_cnt_prev  <= bootstrap_blank_cnt;
                if(bootstrap_compare_en = '1') then
                    if(bootstrap_active_cnt /= bootstrap_active_cnt_prev) then
                        bootstrap_error <= '1';
                    end if;
                    if(bootstrap_blank_cnt /= bootstrap_blank_cnt_prev) then
                        bootstrap_error <= '1';
                    end if;
                end if;
                
            elsif(bootstrap_blank_cnt_en = '1') then
                bootstrap_blank_cnt    <= bootstrap_blank_cnt+1;
            end if;

            --If we are looking for the blanking period, reload the determine count
            if(vld_i = '0' and bootstrap_det_en = '1') then
                bootstrap_det_cnt <= bootstrap_det_cnt-1;
            end if;
            
            --Try and determine if we have entered the vertical blanking period of the frame
            if(bootstrap_det_en = '1' and bootstrap_det_cnt = x"000" and vld_i /= '1') then
                --Bootstrap's time to shine
                bootstrap_go <= '1';
                fifo_line_en <= fifo_line_en(MATRIX_SIZE-2 downto 0) & '0';
                xh_cnt       <= (0 => '1', others => '0');
                xv_cnt       <= (others => '0');
                bootstrap    <= '1';
                bootstrap_det_en <= '0';
            end if; 
            
            if(vld_i = '1') then
                bootstrap_det_cnt <= bootstrap_blank_cnt;
            end if;
            

            --Service the bootstrap
            if(bootstrap_go = '1') then
                --Provide the same timing provided at the input
                --This is because we have a line latency
                --Do this for a few lines:
                --  3x3 matrix -> once
                --  5x5 matrix -> twice
                --  etc...
                xh_cnt <= xh_cnt + 1;
                if(xh_cnt < bootstrap_active_cnt) then
                    bootstrap <= '1';
                else
                    bootstrap <= '0';
                end if;

                if(xh_cnt = bootstrap_active_cnt + bootstrap_blank_cnt - 1) then
                    xh_cnt <= (others => '0');
                    fifo_line_en <= fifo_line_en(MATRIX_SIZE-2 downto 0) & '0';
                    --bootstrap_wr_mask <= '0' & bootstrap_wr_mask(MATRIX_SIZE-1 downto 1);
                    bootstrap_wr_mask(MATRIX_SIZE-1 downto HALF_POINT+1) <= (others => '0');
                    if(xv_cnt = LINES_TO_BOOTSTRAP - 1) then
                        bootstrap_go <= '0';
                    else
                        xv_cnt <= xv_cnt + 1;
                    end if;
                end if;

            end if;
            
            --Reset the bootstrap enable after the blanking period
            if(sof_i = '1') then
                bootstrap_go <= '0';
                bootstrap_wr_mask <= (others => '1');
            end if;

            --Move matrix data around
            for i in 0 to MATRIX_SIZE-1 loop
                if(i = 0) then
                    matrix(i)(1) <= input_reg;
                else
                    matrix(i)(1)(DATA_WIDTH-1 downto 0) <= fifo_rd_data(i-1)(DATA_WIDTH-1 downto 0);
                    --Zero out the metadata for out of range reads
                    if(fifo_rd_en_dly(i-1) = '1') then
                        matrix(i)(1)(DATA_WIDTH)   <= fifo_rd_data(i-1)(DATA_WIDTH);
                        matrix(i)(1)(DATA_WIDTH+1) <= fifo_rd_data(i-1)(DATA_WIDTH+1);
                        matrix(i)(1)(DATA_WIDTH+2) <= fifo_rd_data(i-1)(DATA_WIDTH+2);
                    else
                        matrix(i)(1)(DATA_WIDTH)   <= '0';
                        matrix(i)(1)(DATA_WIDTH+1) <= '0';
                        matrix(i)(1)(DATA_WIDTH+2) <= '0';
                    end if;
                end if;
                
                for j in 2 to MATRIX_SIZE-1 loop
                    matrix(i)(j) <= matrix(i)(j-1);
                end loop;
            end loop;
            
            --Put things back to normal at the start of the frame
            if(sof_i = '1') then
                fifo_line_en <= (0 => '1', others => '0');
                fifo_wr_mask <= (others => '0');
            end if;
            
            --FIFO status reporting
            if(ov /= STAT_ZEROS or un /= STAT_ZEROS) then
                fifo_error <= '1';
            end if;
            
            reset_meta <= reset;
            reset_sync <= reset_meta;
            
            if(reset_sync = '1') then
                fifo_line_en <= (others => '0');
                fifo_wr_mask <= (others => '0');
                fifo_error   <= '0';
                bootstrap_go <= '0';
                bootstrap    <= '0';
                bootstrap_det_en <= '0';
                bootstrap_active_cnt_en <= '0';
                bootstrap_blank_cnt_en <= '0';
                bootstrap_error <= '0';
                bootstrap_sof_en <= '0';
                bootstrap_wr_mask <= (others => '1');
            end if;
            
		end if;
	end process;    
    
    --Assign the output matrix
    --This should be zero LUTs (just wires)
    --Not even necessary, just to make loop rolling easier
    process(input_reg, fifo_rd_data, matrix)
    begin
        --rows
        for i in 0 to MATRIX_SIZE-1 loop
            --columns
            for j in 0 to MATRIX_SIZE-1 loop
                if(j = 0) then
                    if(i = 0) then
                        matrix_o(i)(j) <= input_reg;
                    else
                        matrix_o(i)(j) <= fifo_rd_data(i-1);
                    end if;
                else
                    matrix_o(i)(j) <= matrix(i)(j);
                end if;
            end loop;
        end loop;
    end process;
    
    --Transpose the matrix
    --This is how the data comes out of the FIFO buffering
    --matrix(0)(0), the newest pixel is here in a 3x3 sliding kernel:
    -- [ x x x ]
    -- [ x x x ]
    -- [ x x o ]
    --matrix(2)(2), the oldest pixel, is here in a 3x3 sliding kernel:
    -- [ o x x ]
    -- [ x x x ]
    -- [ x x x ]
    process(matrix_o)
    begin
        --Transpose the matrix since I want (0)(0) to be the top-left of the sliding kernel
        for i in 0 to MATRIX_SIZE-1 loop
            for j in 0 to MATRIX_SIZE-1 loop
                matrix_t(i)(j) <= matrix_o(MATRIX_SIZE-1-i)(MATRIX_SIZE-1-j);
            end loop;
        end loop;
    end process;
    
    --Now that the matrix is transposed, this is what it looks like:
    --matrix(0)(0), the oldest pixel is here in a 3x3 sliding kernel:
    -- [ o x x ]
    -- [ x x x ]
    -- [ x x x ]
    --matrix(2)(2), the newest pixel, is here in a 3x3 sliding kernel:
    -- [ x x x ]
    -- [ x x x ]
    -- [ x x o ]
    
    --Using HALF_POINT+1 in the j column should allow the vcnt and hcnt to line up with matrix_t
    sof_b <= matrix_t(HALF_POINT)(HALF_POINT+1)(DATA_WIDTH+2);
    eol_b <= matrix_t(HALF_POINT)(HALF_POINT+1)(DATA_WIDTH+1);
    vld_b <= matrix_t(HALF_POINT)(HALF_POINT+1)(DATA_WIDTH+0);
    
    --Get count values for where we are in the sliding kernel
    process(clk)
    begin
        if(rising_edge(clk)) then
            --clock 1, lines up with the matrix_t correct data
            sof_b_reg <= sof_b;
            eol_b_reg <= eol_b;
            vld_b_reg <= vld_b;
            
            if(vld_b = '1') then
                hcnt <= hcnt + 1;
                if(first = '1') then
                    hcnt  <= (others => '0');
                    first <= '0';
                end if;
            end if;
            
            if(sof_b = '1') then
                hcnt <= (others => '0');
                vcnt <= (others => '0');
            end if;
            
            --clock 2
            if(eol_b_reg = '1') then
                hcnt <= (others => '0');
                vcnt <= vcnt + 1;
                first <= '1';
            end if;
            
            if(HALF_POINT=1) then
                lef_edge_kill <= (others => '0');
                rig_edge_kill <= (others => '0');
            else
                lef_edge_kill <= '0' & lef_edge_kill(HALF_POINT-1 downto 1);
                rig_edge_kill <= (others => '0');
            end if;
            
            if(vld_b_reg = '1' and hcnt = x"000") then
                lef_edge_kill <= (others => '1');
            end if;
            
            if(vld_b_reg = '1' and hcnt >= to_unsigned(H_ACTIVE-HALF_POINT,12)) then
                if(HALF_POINT=1) then
                    rig_edge_kill <= (others => '1');
                else
                    rig_edge_kill <= '1' & rig_edge_kill(MATRIX_SIZE-1 downto HALF_POINT+2);
                end if;

            end if;
             
            if(vld_b_reg = '1' and vcnt = to_unsigned(V_ACTIVE-HALF_POINT,12) and hcnt = x"000") then
                if(HALF_POINT=1) then
                    bot_edge_kill <= (others => '1');
                else
                    bot_edge_kill <= '1' & bot_edge_kill(MATRIX_SIZE-1 downto HALF_POINT+2);
                end if;
            end if;

            if(vld_b_reg = '1' and eol_b_reg = '1') then
                top_edge_kill <= '0' & top_edge_kill(HALF_POINT-1 downto 1);
                bot_edge_kill <= bot_edge_kill(MATRIX_SIZE-1) & bot_edge_kill(MATRIX_SIZE-1 downto HALF_POINT+2);
            end if;

            if(sof_b_reg = '1' and vld_b_reg = '1') then
                top_edge_kill <= (others => '1');
                bot_edge_kill <= (others => '0');
            end if;

            matrix_d <= matrix_t;
            
            --clock 3
            --Defaults
            for i in 0 to MATRIX_SIZE-1 loop
                for j in 0 to MATRIX_SIZE-1 loop
                    matrix_z(i)(j) <= matrix_d(i)(j);
                end loop;
            end loop;
            
            --Zero off top row
            for i in 0 to HALF_POINT-1 loop
                if(top_edge_kill(i)= '1') then
                    for j in 0 to MATRIX_SIZE-1 loop
                        matrix_z(i)(j)(DATA_WIDTH-1 downto 0) <= (others => '0');
                    end loop;
                end if;
            end loop;
 
            --Zero off bottom row
            for i in HALF_POINT+1 to MATRIX_SIZE-1 loop
                if(bot_edge_kill(i) = '1') then
                    for j in 0 to MATRIX_SIZE-1 loop
                        matrix_z(i)(j)(DATA_WIDTH-1 downto 0) <= (others => '0');
                    end loop;
                end if;
            end loop;
            
            --Zero off left column
            for j in 0 to HALF_POINT-1 loop
                if(lef_edge_kill(j) = '1') then
                    for i in 0 to MATRIX_SIZE-1 loop
                        matrix_z(i)(j)(DATA_WIDTH-1 downto 0) <= (others => '0');
                    end loop;
                end if;
            end loop;

            --Zero off right column
            for j in HALF_POINT+1 to MATRIX_SIZE-1 loop
                if(rig_edge_kill(j) = '1') then
                    for i in 0 to MATRIX_SIZE-1 loop
                        matrix_z(i)(j)(DATA_WIDTH-1 downto 0) <= (others => '0');
                    end loop;
                end if;
            end loop;
        end if;
    end process;
    
    --Assign metadata on outputs
    sof_o <= matrix_z(HALF_POINT)(HALF_POINT)(DATA_WIDTH+2);
    eol_o <= matrix_z(HALF_POINT)(HALF_POINT)(DATA_WIDTH+1);
    vld_o <= matrix_z(HALF_POINT)(HALF_POINT)(DATA_WIDTH+0);
    dat_o <= matrix_z(HALF_POINT)(HALF_POINT)(DATA_WIDTH-1 downto 0);
    
    --Roll the output vector up
    --This should also be zero LUTs
    --Rolled vector is formatted as [matrix(2)(2), matrix(2)(1), etc...matrix(0)(1), matrix(0)(0)]
    --matrix(0)(0), the oldest pixel, is here in the 3x3 sliding kernel:
    -- [ o x x ]
    -- [ x x x ]
    -- [ x x x ]
    --matrix(2)(2), the newest pixel, is here in a 3x3 sliding kernel:
    -- [ x x x ]
    -- [ x x x ]
    -- [ x x o ]
    process(matrix_z)
        variable upper  : integer := 0;
        variable lower  : integer := 0;
        variable offset : integer := 0;
    begin
        --rows
        for i in 0 to MATRIX_SIZE-1 loop
           offset := MATRIX_SIZE*(i)*DATA_WIDTH;
           --columns
           for j in 0 to MATRIX_SIZE-1 loop
               upper := (j+1)*DATA_WIDTH-1 + offset;
               lower := (j+0)*DATA_WIDTH   + offset;
               dat_r(upper downto lower) <= matrix_z(i)(j)(DATA_WIDTH-1 downto 0);
           end loop;
        end loop;
    end process;
    
    --Assign FIFO signals
    process(matrix, vld_i_reg, bootstrap, fifo_wr_mask, fifo_line_en, bootstrap_wr_mask)
    begin
        for i in 0 to MATRIX_SIZE-2 loop
            fifo_wr_data(i) <= matrix(i)(MATRIX_SIZE-1);
            fifo_wr_en(i)   <= matrix(i)(MATRIX_SIZE-1)(DATA_WIDTH) and 
                               fifo_wr_mask(MATRIX_SIZE-1)          and 
                               fifo_line_en(i)                      and
                               bootstrap_wr_mask(i+1);
            fifo_rd_en(i)   <= (vld_i_reg or bootstrap) and fifo_line_en(i+1);
        end loop;
    end process;
    
    --FIFOs
    FIFO_place_gen : for i in 0 to MATRIX_SIZE-2 generate
    
        FIFO_inst : entity work.sync_fifo
        generic map(
            gDEPTH => H_ACTIVE,
            gWIDTH => FIFO_WIDTH,
            gOREGS => 0,
            gPF    => 0,
            gPE    => 0
        )
        port map(
            clk     => clk,
            reset   => reset,
            wr_en   => fifo_wr_en(i),
            wr_data => fifo_wr_data(i),
            rd_en   => fifo_rd_en(i),
            rd_data => fifo_rd_data(i),
            
            ff => open,
            fe => open,
            pf => open,
            pe => open,
            ov => ov(i),
            un => un(i)
        
        );
    end generate FIFO_place_gen;

end arch;
