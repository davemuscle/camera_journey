library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
--Dave Muscle

--Applies Demosiacing to Raw Bayer Filter Data
--Video data needs to include blanking time
--This also expects constant sync'd video

--Bayer Filter order should be:
--   Mode = 0:      Mode 1:      Mode 2:      Mode 3:
-- |  B G . . |   | G B . . |  | G R . . |  | R G . . |
-- |  G R . . |   | R G . . |  | B G . . |  | G B . . |


--Applies four 5x5 sparse kernels to the raw data to get each color channel

------------------------------------------------------------------
--          Kernel 0
--For green pixels at red/blue locations:
------------------------------------------------------------------
    -- [ 0  0 -1  0  0 ]
    -- [ 0  0  2  0  0 ]
    -- [-1  2  4  2 -1 ]
    -- [ 0  0  2  0  0 ]
    -- [ 0  0 -1  0  0 ]
  
------------------------------------------------------------------
--          Kernel 1
--For red pixels at green location in red row, blue column:
--For blue pixels at green location in blue row, red column:
------------------------------------------------------------------
    -- [ 0  0  1/2  0  0 ]
    -- [ 0 -1   0  -1  0 ]
    -- [-1  4   5   4 -1 ]
    -- [ 0 -1   0  -1  0 ]
    -- [ 0  0  1/2  0  0 ]
    
------------------------------------------------------------------
--          Kernel 2
--For red pixels at green location in blue row, red column:
--For blue pixels at green location in red row, blue column:
------------------------------------------------------------------
    -- [  0   0  -1   0    0  ]
    -- [  0  -1   4  -1    0  ]
    -- [ 1/2  0   5   0   1/2 ]
    -- [  0  -1   4  -1    0  ]
    -- [  0   0  -1   0    0  ]
    
------------------------------------------------------------------
--          Kernel 3
------------------------------------------------------------------
--For red pixels at blue locations in blue row, blue column:
--For blue pixels at red locations in red row, red column:

    -- [  0    0  -3/2   0    0  ]
    -- [  0    2    0    2    0  ]
    -- [ -3/2  0    6    0  -3/2 ]
    -- [  0    2    0    2    0  ]
    -- [  0    0  -3/2   0    0  ]
       

entity debayer is
	generic(
		H_ACTIVE    : integer := 1920;
		V_ACTIVE    : integer := 1080
		);
	port(
	    clk   : in std_logic;
		reset : in std_logic;
        
        mode         : in std_logic_vector(1 downto 0);
        buffer_error : out std_logic := '0';
        bypass       : in std_logic;
        
        sof_i : in std_logic;
        eol_i : in std_logic;
        vld_i : in std_logic;
        dat_i : in std_logic_vector(7 downto 0);
        
        sof_o   : out std_logic := '0';
        eol_o   : out std_logic := '0';
        vld_o   : out std_logic := '0';
        dat_o   : out std_logic_vector(23 downto 0)
       
        );
end debayer;

architecture arch of debayer is 

    --Outputs from bufferer
    signal sof_b : std_logic := '0';
    signal eol_b : std_logic := '0';
    signal vld_b : std_logic := '0';
    signal dat_r : std_logic_vector(8*5*5-1 downto 0) := (others => '0');
  
    --Register outputs from bufferer
    signal sof_b_reg : std_logic := '0';
    signal eol_b_reg : std_logic := '0';
    signal vld_b_reg : std_logic := '0';
   
    signal sof_b_dly : std_logic := '0';
    signal eol_b_dly : std_logic := '0';
    signal vld_b_dly : std_logic := '0';
   
    signal sof_b_nxt : std_logic := '0';
    signal eol_b_nxt : std_logic := '0';
    signal vld_b_nxt : std_logic := '0';
   
    signal odd_column : std_logic := '0';
    signal odd_row    : std_logic := '0';

    signal hcnt : unsigned(11 downto 0) := (others => '0');
    signal vcnt : unsigned(11 downto 0) := (others => '0');
  
    --Edge-zeroing
    signal kill_top_row1, kill_top_row2 : std_logic := '0';
    signal kill_bot_row1, kill_bot_row2 : std_logic := '0';
    signal kill_lef_col1, kill_lef_col2 : std_logic := '0';
    signal kill_rig_col1, kill_rig_col2 : std_logic := '0';
  
    type matrix_col is array(0 to 4) of std_logic_vector(7 downto 0);
    type matrix_fcol is array(0 to 4) of std_logic_vector(12 downto 0);
    type matrix_row is array(0 to 4) of matrix_col;
    type matrix_frow is array(0 to 4) of matrix_fcol;
    signal matrix : matrix_row   := (others => (others => (others => '0')));
    signal matrix_d : matrix_row := (others => (others => (others => '0')));
    signal matrix_t : matrix_row := (others => (others => (others => '0')));
    signal matrix_z : matrix_frow := (others => (others => (others => '0')));

    signal red, grn, blu : std_logic_vector(12 downto 0) := (others => '0');
    signal red_p1, grn_p1, blu_p1 : std_logic_vector(12 downto 0) := (others => '0');
    signal red_p2, grn_p2, blu_p2 : std_logic_vector(12 downto 0) := (others => '0');
    signal center_pixel_row, center_pixel_col : std_logic := '0';
    
    signal sof_o_pre, eol_o_pre, valid_o_pre : std_logic := '0';
    signal sof_o_reg, eol_o_reg, valid_o_reg : std_logic := '0';
    signal sof_o_dly, eol_o_dly, valid_o_dly : std_logic := '0';
    signal red_o, grn_o, blu_o : std_logic_vector(7 downto 0) := (others => '0');
    
    --Q2.8, signed
    constant kernel0_norm : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(37,10));
    constant kernel1_norm : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(32,10));
    constant kernel2_norm : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(32,10));
    constant kernel3_norm : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(38,10));
    
    constant pass_norm : std_logic_vector(9 downto 0) := "0100000000";
    
    signal red_m : std_logic_vector(12 downto 0) := (others => '0');
    signal grn_m : std_logic_vector(12 downto 0) := (others => '0');
    signal blu_m : std_logic_vector(12 downto 0) := (others => '0');
    
    signal red_scale : std_logic_vector(22 downto 0) := (others => '0');
    signal blu_scale : std_logic_vector(22 downto 0) := (others => '0');
    signal grn_scale : std_logic_vector(22 downto 0) := (others => '0');    
    
    signal red_f : std_logic_vector(12 downto 0) := (others => '0');
    signal grn_f : std_logic_vector(12 downto 0) := (others => '0');
    signal blu_f : std_logic_vector(12 downto 0) := (others => '0');   
    
    signal red_norm : std_logic_vector(9 downto 0) := (others => '0');
    signal grn_norm : std_logic_vector(9 downto 0) := (others => '0');
    signal blu_norm : std_logic_vector(9 downto 0) := (others => '0');
    
    signal red_pass, grn_pass, blu_pass : std_logic := '0';
    
    signal grn_no_k,grn_k0 : std_logic_vector(12 downto 0) := (others => '0');
    signal grn_k0_p1,grn_k0_p2 : std_logic_vector(12 downto 0) := (others => '0');
    
    signal red_no_k,red_k1, red_k2, red_k3 : std_logic_vector(12 downto 0) := (others => '0');
    signal red_k1_p1, red_k2_p1, red_k3_p1 : std_logic_vector(12 downto 0) := (others => '0');
    signal red_k1_p2, red_k2_p2, red_k3_p2 : std_logic_vector(12 downto 0) := (others => '0');
    signal blu_no_k,blu_k1, blu_k2, blu_k3 : std_logic_vector(12 downto 0) := (others => '0');
    signal blu_k1_p1, blu_k2_p1, blu_k3_p1 : std_logic_vector(12 downto 0) := (others => '0');
    signal blu_k1_p2, blu_k2_p2, blu_k3_p2 : std_logic_vector(12 downto 0) := (others => '0');  
    signal red_sel : std_logic_vector(3 downto 0) := (others => '0');
    signal grn_sel : std_logic_vector(0 downto 0) := (others => '0');
    signal blu_sel : std_logic_vector(3 downto 0) := (others => '0');
 
    
    signal center_pixel_loc : std_logic_vector(1 downto 0) := (others => '0');
    signal self_reset : std_logic := '0';
    
    signal mode_locked : std_logic_vector(1 downto 0) := (others => '0');
    
    signal fifo_error : std_logic := '0';
    signal bootstrap_error : std_logic := '0';
    
    signal reset_meta, reset_sync : std_logic := '0';
    
    signal first : std_logic := '0';
    
begin	
    --Buffer up data
	kernel_bufferer_inst : entity work.kernel_bufferer
	generic map(
        DATA_WIDTH  => 8,
        MATRIX_SIZE => 5,
		H_ACTIVE    => H_ACTIVE,
		V_ACTIVE    => V_ACTIVE
	
		)
	port map(
		clk   => clk,
        reset => reset,

        sof_i  => sof_i,
        eol_i  => eol_i,
        vld_i  => vld_i,
        dat_i  => dat_i,


        sof_o => sof_b,
        eol_o => eol_b,
        vld_o => vld_b,
        dat_o => open,
        dat_r => dat_r,
        
        fifo_error      => fifo_error,
        bootstrap_error => bootstrap_error
	);
    
	buffer_error <= fifo_error or bootstrap_error;
    

    --Unroll the output from the bufferer into a nice matrix
    --It also shouldn't take any lookup tables
    process(dat_r)
        variable upper  : integer := 0;
        variable lower  : integer := 0;
        variable offset : integer := 0;
    begin
        for i in 0 to 4 loop
            offset := 5*i*8;
            for j in 0 to 4 loop
                upper := (j+1)*8-1+offset;
                lower := (j+0)*8-0+offset;
                matrix(i)(j) <= dat_r(upper downto lower);
            end loop;
        end loop;
    end process;
    
    --This is how the data comes out of the kernel bufferer:
    --matrix(0)(0), the oldest pixel, is here in a 3x3 sliding kernel:
    -- [ o x x ]
    -- [ x x x ]
    -- [ x x x ]
    --matrix(2)(2), the newest pixel, is here in a 3x3 sliding kernel:
    -- [ x x x ]
    -- [ x x x ]
    -- [ x x o ]
    
    process(clk)
    begin
        if(rising_edge(clk)) then
            
            --clock 1
            sof_b_reg <= sof_b;
            eol_b_reg <= eol_b;
            vld_b_reg <= vld_b;
            
            for i in 0 to 4 loop
                for j in 0 to 4 loop
                    matrix_z(i)(j) <= "00000" & matrix(i)(j);
                end loop;
            end loop;
            
            --Provide count values and even/odd signals for debayer application
            if(vld_b = '1') then
                odd_column <= not odd_column;
            end if;
            
            if(sof_b = '1') then
                odd_column <= '0';
                odd_row    <= '0';
            end if;
            
            if(first = '1' and vld_b = '1') then
                odd_column <= '0';
                first      <= '0';
            end if;

            if(eol_b_reg = '1') then
                odd_row <= not odd_row;
                first <= '1';
            end if;

        end if;
    end process;
    
    center_pixel_loc <= odd_row & odd_column;
    
    grn_m <= grn;
    red_m <= red;
    blu_m <= blu;
    
    --calculate green pixels
    process(clk)
    begin
        if(rising_edge(clk)) then
        
            grn_scale <= std_logic_vector(signed(grn_m)*signed(grn_norm));

            if(grn_sel = "0") then
                grn <= grn_no_k;
                grn_norm <= pass_norm;
            else
                --grn <= grn_k0;
                grn <= std_logic_vector(signed(grn_k0_p1) - signed(grn_k0_p2));
                grn_norm <= kernel0_norm;
            end if;
            
            --grn_sel = 1 to apply kernel
            --grn_sel = 0 to pass through
            
            case mode_locked is 
            when "00"   =>
                --BGGR
                case center_pixel_loc is
                when "00"   =>
                    grn_sel <= "1";
                when "01"   =>
                    grn_sel <= "0";
                when "10"   =>
                    grn_sel <= "0";
                when others => 
                    grn_sel <= "1";
                end case;
            when "01"   =>
                --GBRG
                case center_pixel_loc is
                when "00"   =>
                    grn_sel <= "0";
                when "01"   =>
                    grn_sel <= "1";
                when "10"   =>
                    grn_sel <= "1";
                when others => 
                    grn_sel <= "0";
                end case;
            when "10"   =>
                --GRBG
                case center_pixel_loc is
                when "00"   =>
                    grn_sel <= "0";
                when "01"   =>
                    grn_sel <= "1";
                when "10"   =>
                    grn_sel <= "1";
                when others => 
                    grn_sel <= "0";
                end case;
            when others =>
                --RGGB
                case center_pixel_loc is
                when "00"   =>
                    grn_sel <= "1";
                when "01"   =>
                    grn_sel <= "0";
                when "10"   =>
                    grn_sel <= "0";
                when others => 
                    grn_sel <= "1";
                end case;
            end case;

            
            grn_no_k <= matrix_z(2)(2);
            
            ------------------------------------------------------------------
            --          Kernel 0
            --For green pixels at red/blue locations:
            ------------------------------------------------------------------
                -- [ 0  0 -1  0  0 ]
                -- [ 0  0  2  0  0 ]
                -- [-1  2  4  2 -1 ]
                -- [ 0  0  2  0  0 ]
                -- [ 0  0 -1  0  0 ]

            grn_k0_p1 <= std_logic_vector(
                     (signed(matrix_z(2)(2)) sll 2) + --mult by 4
                     (signed(matrix_z(2)(1)) sll 1) + --mult by 2
                     (signed(matrix_z(2)(3)) sll 1) + --mult by 2
                     (signed(matrix_z(1)(2)) sll 1) + --mult by 2
                     (signed(matrix_z(3)(2)) sll 1)   --mult by 2
            );
            
            grn_k0_p2 <= std_logic_vector(
                      signed(matrix_z(0)(2)) +
                      signed(matrix_z(2)(0)) +
                      signed(matrix_z(2)(4)) +
                      signed(matrix_z(4)(2))
            );           
        end if;
    end process;

    --calculate red pixels
    process(clk)
    begin
        if(rising_edge(clk)) then
        
            red_scale <= std_logic_vector(signed(red_m)*signed(red_norm));

            case red_sel is
            when "0010" =>
                red_norm <= kernel1_norm;
                --red <= red_k1;
                red <= std_logic_vector(signed(red_k1_p1) - signed(red_k1_p2));
            when "0100" =>
                red_norm <= kernel2_norm;
                --red <= red_k2;
                red <= std_logic_vector(signed(red_k2_p1) - signed(red_k2_p2));
            when "1000" =>
                red_norm <= kernel3_norm;
                --red <= red_k3;
                red <= std_logic_vector(signed(red_k3_p1) - signed(red_k3_p2));
            when others =>
                red_norm <= pass_norm;
                red <= red_no_k;
            end case;
        
        
            case mode_locked is 
            when "00"   =>
                --BGGR
                case center_pixel_loc is
                when "00"   =>
                    red_sel <= "1000";       
                when "01"   =>
                    red_sel <= "0100";
                when "10"   =>
                    red_sel <= "0010";
                when others => 
                    red_sel <= "0000";
                end case;

            when "01"   =>
                --GBRG
                case center_pixel_loc is
                when "00"   =>
                    red_sel <= "0100";       
                when "01"   =>
                    red_sel <= "1000";
                when "10"   =>
                    red_sel <= "0000";
                when others => 
                    red_sel <= "0010";
                end case;
                
            when "10"   =>
                --GRBG
                case center_pixel_loc is
                when "00"   =>
                    red_sel <= "0010";       
                when "01"   =>
                    red_sel <= "0000";
                when "10"   =>
                    red_sel <= "1000";
                when others => 
                    red_sel <= "0100";
                end case;
                
            when others =>
                --RGGB
                case center_pixel_loc is
                when "00"   =>
                    red_sel <= "0000";       
                when "01"   =>
                    red_sel <= "0010";
                when "10"   =>
                    red_sel <= "0100";
                when others => 
                    red_sel <= "1000";
                end case;
                
            end case;
            
        

        
        
            red_no_k <= matrix_z(2)(2);
        
            ------------------------------------------------------------------
            --          Kernel 1
            --For red pixels at green location in red row, blue column:
            --For blue pixels at green location in blue row, red column:
            ------------------------------------------------------------------
                -- [ 0  0  1/2  0  0 ]
                -- [ 0 -1   0  -1  0 ]
                -- [-1  4   5   4 -1 ]
                -- [ 0 -1   0  -1  0 ]
                -- [ 0  0  1/2  0  0 ]
            
            red_k1_p1 <= std_logic_vector(
                     (signed(matrix_z(2)(2)) sll 2) + --mult by 5, part 1
                      signed(matrix_z(2)(2))        + --mult by 5, part 2
                     (signed(matrix_z(2)(1)) sll 2) + --mult by 4
                     (signed(matrix_z(2)(3)) sll 2) + --mult by 4
                     (signed(matrix_z(0)(2)) srl 1) + --mult by 1/2
                     (signed(matrix_z(4)(2)) srl 1)   --mult by 1/2
            );
            
            red_k1_p2 <= std_logic_vector(
                      signed(matrix_z(2)(0)) +
                      signed(matrix_z(1)(1)) +
                      signed(matrix_z(3)(1)) +
                      signed(matrix_z(1)(3)) +
                      signed(matrix_z(3)(3)) +
                      signed(matrix_z(2)(4))
            );
        
            ------------------------------------------------------------------
            --          Kernel 2
            --For red pixels at green location in blue row, red column:
            --For blue pixels at green location in red row, blue column:
            ------------------------------------------------------------------
                -- [  0   0  -1   0    0  ]
                -- [  0  -1   4  -1    0  ]
                -- [ 1/2  0   5   0   1/2 ]
                -- [  0  -1   4  -1    0  ]
                -- [  0   0  -1   0    0  ]

            red_k2_p1 <= std_logic_vector(
                     (signed(matrix_z(2)(2)) sll 2) + --mult by 5, part 1
                      signed(matrix_z(2)(2))        + --mult by 5, part 2
                     (signed(matrix_z(1)(2)) sll 2) + --mult by 4
                     (signed(matrix_z(3)(2)) sll 2) + --mult by 4
                     (signed(matrix_z(2)(0)) srl 1) + --mult by 1/2
                     (signed(matrix_z(2)(4)) srl 1)   --mult by 1/2
            );
                
            red_k2_p2 <= std_logic_vector(
                      signed(matrix_z(0)(2)) +
                      signed(matrix_z(1)(1)) +
                      signed(matrix_z(1)(3)) +
                      signed(matrix_z(3)(1)) +
                      signed(matrix_z(3)(3)) +
                      signed(matrix_z(4)(2))
            );
                
            ------------------------------------------------------------------
            --          Kernel 3
            ------------------------------------------------------------------
            --For red pixels at blue locations in blue row, blue column:
            --For blue pixels at red locations in red row, red column:

                -- [  0    0  -3/2   0    0  ]
                -- [  0    2    0    2    0  ]
                -- [ -3/2  0    6    0  -3/2 ]
                -- [  0    2    0    2    0  ]
                -- [  0    0  -3/2   0    0  ]
                
            red_k3_p1 <= std_logic_vector(
                     (signed(matrix_z(2)(2)) sll 1) + --mult by 6, part 1
                     (signed(matrix_z(2)(2)) sll 2) + --mult by 6, part 2
                     (signed(matrix_z(1)(1)) sll 1) + --mult by 2
                     (signed(matrix_z(1)(3)) sll 1) + --mult by 2
                     (signed(matrix_z(3)(1)) sll 1) + --mult by 1/2
                     (signed(matrix_z(3)(3)) sll 1)   --mult by 1/2

            );
    
            red_k3_p2 <= std_logic_vector(
            
                      signed(matrix_z(0)(2))        + --mult by 3/2, part 1
                     (signed(matrix_z(0)(2)) srl 1) + --mult by 3/2, part 2
                      signed(matrix_z(2)(0))        + --mult by 3/2, part 1
                     (signed(matrix_z(2)(0)) srl 1) + --mult by 3/2, part 2
                      signed(matrix_z(2)(4))        + --mult by 3/2, part 1
                     (signed(matrix_z(2)(4)) srl 1) + --mult by 3/2, part 2
                      signed(matrix_z(4)(2))        + --mult by 3/2, part 1
                     (signed(matrix_z(4)(2)) srl 1)   --mult by 3/2, part 2
            );
            
    
        end if;
    end process;
    
 
    --calculate blue pixels
    process(clk)
    begin
        if(rising_edge(clk)) then
        
            blu_scale <= std_logic_vector(signed(blu_m)*signed(blu_norm));

            case blu_sel is
            when "0010" =>
                blu_norm <= kernel1_norm;
                --blu <= blu_k1;
                blu <= std_logic_vector(signed(blu_k1_p1) - signed(blu_k1_p2));
            when "0100" =>
                blu_norm <= kernel2_norm;
                --blu <= blu_k2;
                blu <= std_logic_vector(signed(blu_k2_p1) - signed(blu_k2_p2));
            when "1000" =>
                blu_norm <= kernel3_norm;
                --blu <= blu_k3;
                blu <= std_logic_vector(signed(blu_k3_p1) - signed(blu_k3_p2));
            when others =>
                blu_norm <= pass_norm;
                blu <= blu_no_k;
            end case;
        
            case mode_locked is 
            when "00"   =>
                --BGGR
                case center_pixel_loc is
                when "00"   =>
                    blu_sel <= "0000";       
                when "01"   =>
                    blu_sel <= "0010";
                when "10"   =>
                    blu_sel <= "0100";
                when others => 
                    blu_sel <= "1000";
                end case;
                
            when "01"   =>
                --GBRG
                case center_pixel_loc is
                when "00"   =>
                    blu_sel <= "0010";       
                when "01"   =>
                    blu_sel <= "0000";
                when "10"   =>
                    blu_sel <= "1000";
                when others => 
                    blu_sel <= "0100";
                end case;
                
            when "10"   =>
                --GRBG
                case center_pixel_loc is
                when "00"   =>
                    blu_sel <= "0100";       
                when "01"   =>
                    blu_sel <= "1000";
                when "10"   =>
                    blu_sel <= "0000";
                when others => 
                    blu_sel <= "0010";
                end case;
                
            when others =>
                --RGGB
                case center_pixel_loc is
                when "00"   =>
                    blu_sel <= "1000";       
                when "01"   =>
                    blu_sel <= "0100";
                when "10"   =>
                    blu_sel <= "0010";
                when others => 
                    blu_sel <= "0000";
                end case;
                
            end case;
        
            blu_no_k <= matrix_z(2)(2);

            ------------------------------------------------------------------
            --          Kernel 1
            --For red pixels at green location in red row, blue column:
            --For blue pixels at green location in blue row, red column:
            ------------------------------------------------------------------
                -- [ 0  0  1/2  0  0 ]
                -- [ 0 -1   0  -1  0 ]
                -- [-1  4   5   4 -1 ]
                -- [ 0 -1   0  -1  0 ]
                -- [ 0  0  1/2  0  0 ]
            
            blu_k1_p1 <= std_logic_vector(
                     (signed(matrix_z(2)(2)) sll 2) + --mult by 5, part 1
                      signed(matrix_z(2)(2))        + --mult by 5, part 2
                     (signed(matrix_z(2)(1)) sll 2) + --mult by 4
                     (signed(matrix_z(2)(3)) sll 2) + --mult by 4
                     (signed(matrix_z(0)(2)) srl 1) + --mult by 1/2
                     (signed(matrix_z(4)(2)) srl 1)   --mult by 1/2
            );

            blu_k1_p2 <= std_logic_vector(
                      signed(matrix_z(2)(0)) +
                      signed(matrix_z(1)(1)) +
                      signed(matrix_z(3)(1)) +
                      signed(matrix_z(1)(3)) +
                      signed(matrix_z(3)(3)) +
                      signed(matrix_z(2)(4))
            );

            ------------------------------------------------------------------
            --          Kernel 2
            --For red pixels at green location in blue row, red column:
            --For blue pixels at green location in red row, blue column:
            ------------------------------------------------------------------
                -- [  0   0  -1   0    0  ]
                -- [  0  -1   4  -1    0  ]
                -- [ 1/2  0   5   0   1/2 ]
                -- [  0  -1   4  -1    0  ]
                -- [  0   0  -1   0    0  ]

            blu_k2_p1 <= std_logic_vector(
                     (signed(matrix_z(2)(2)) sll 2) + --mult by 5, part 1
                      signed(matrix_z(2)(2))        + --mult by 5, part 2
                     (signed(matrix_z(1)(2)) sll 2) + --mult by 4
                     (signed(matrix_z(3)(2)) sll 2) + --mult by 4
                     (signed(matrix_z(2)(0)) srl 1) + --mult by 1/2
                     (signed(matrix_z(2)(4)) srl 1)   --mult by 1/2
            );  

            blu_k2_p2 <= std_logic_vector(
                      signed(matrix_z(0)(2)) +
                      signed(matrix_z(1)(1)) +
                      signed(matrix_z(1)(3)) +
                      signed(matrix_z(3)(1)) +
                      signed(matrix_z(3)(3)) +
                      signed(matrix_z(4)(2))
            );  

            ------------------------------------------------------------------
            --          Kernel 3
            ------------------------------------------------------------------
            --For red pixels at blue locations in blue row, blue column:
            --For blue pixels at red locations in red row, red column:

                -- [  0    0  -3/2   0    0  ]
                -- [  0    2    0    2    0  ]
                -- [ -3/2  0    6    0  -3/2 ]
                -- [  0    2    0    2    0  ]
                -- [  0    0  -3/2   0    0  ]
                

            blu_k3_p1 <= std_logic_vector(
            
                     (signed(matrix_z(2)(2)) sll 1) + --mult by 6, part 1
                     (signed(matrix_z(2)(2)) sll 2) + --mult by 6, part 2
                     (signed(matrix_z(1)(1)) sll 1) + --mult by 2
                     (signed(matrix_z(1)(3)) sll 1) + --mult by 2
                     (signed(matrix_z(3)(1)) sll 1) + --mult by 1/2
                     (signed(matrix_z(3)(3)) sll 1)   --mult by 1/2
            );
  
            blu_k3_p2 <= std_logic_vector(

                      signed(matrix_z(0)(2))        + --mult by 3/2, part 1
                     (signed(matrix_z(0)(2)) srl 1) + --mult by 3/2, part 2
                      signed(matrix_z(2)(0))        + --mult by 3/2, part 1
                     (signed(matrix_z(2)(0)) srl 1) + --mult by 3/2, part 2
                      signed(matrix_z(2)(4))        + --mult by 3/2, part 1
                     (signed(matrix_z(2)(4)) srl 1) + --mult by 3/2, part 2
                      signed(matrix_z(4)(2))        + --mult by 3/2, part 1
                     (signed(matrix_z(4)(2)) srl 1)   --mult by 3/2, part 2
            );
  
        end if;
    end process;
    
    red_f <= red_scale(20 downto 8);
    grn_f <= grn_scale(20 downto 8);
    blu_f <= blu_scale(20 downto 8);
 
    --assign metadata on outputs, saturate colors if needed
    process(clk)
    begin
        if(rising_edge(clk)) then
        
            --valid_o_pre <= matrix_meta_m2(2)(2);
            --sof_o_pre   <= matrix_meta_m2(2)(1);
            --eol_o_pre   <= matrix_meta_m2(2)(0);
   
            --valid_o_pre <= vld_b_nxt;
            --sof_o_pre   <= sof_b_nxt;
            --eol_o_pre   <= eol_b_nxt;
   
            valid_o_pre <= vld_b_reg;
            sof_o_pre   <= sof_b_reg;
            eol_o_pre   <= eol_b_reg;
   
            if(red_f(12) = '0') then
                if(red_f(11 downto 8) /= "0000") then
                    red_o <= (others => '1');
                else
                    red_o <= red_f(7 downto 0);
                end if;
                else
                red_o <= (others => '0');
            end if;
            
            if(grn_f(12) = '0') then
                if(grn_f(11 downto 8) /= "0000") then
                    grn_o <= (others => '1');
                else
                    grn_o <= grn_f(7 downto 0);
                end if;
                else
                grn_o <= (others => '0');
            end if;
            
            if(blu_f(12) = '0') then
                if(blu_f(11 downto 8) /= "0000") then
                    blu_o <= (others => '1');
                else
                    blu_o <= blu_f(7 downto 0);
                end if;
                else
                blu_o <= (others => '0');
            end if;
            
            valid_o_reg <= valid_o_pre;
            sof_o_reg   <= sof_o_pre;
            eol_o_reg   <= eol_o_pre;
   
            valid_o_dly <= valid_o_reg;
            sof_o_dly   <= sof_o_reg;
            eol_o_dly   <= eol_o_reg;
   
            vld_o   <= valid_o_dly;
            sof_o   <= sof_o_dly;
            eol_o   <= eol_o_dly;
            
            if(bypass = '1') then
                vld_o <= vld_i;
                sof_o <= sof_i;
                eol_o <= eol_i;
                red_o <= dat_i;
                grn_o <= dat_i;
                blu_o <= dat_i;
            end if;
            
            --rgb_o <= red_o & grn_o & blu_o;
            
            if(reset_sync = '1') then
                valid_o_pre <= '0';
                sof_o_pre   <= '0';
                eol_o_pre   <= '0';
                
                valid_o_reg <= '0';
                sof_o_reg   <= '0';
                eol_o_reg   <= '0';
        
                valid_o_dly <= '0';
                sof_o_dly   <= '0';
                eol_o_dly   <= '0';
        
                vld_o <= '0';
                sof_o   <= '0';
                eol_o   <= '0';  
            end if;
        
        end if;
    end process;
    
    dat_o <= red_o & grn_o & blu_o;

    
end arch;
