library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Hehe
entity uart_debugger_top is
	port(
		clk_board : in std_logic;
		tx        : out std_logic;
		rx        : in std_logic;

		led0 : out std_logic := '0';
		led1 : out std_logic := '0';
		led2 : out std_logic := '0';
		led3 : out std_logic := '0';
        led4 : out std_logic := '0';
        led5 : out std_logic := '0';
        led6 : out std_logic := '0';
        led7 : out std_logic := '0'
        
	);
end uart_debugger_top;

architecture arch of uart_debugger_top is 

    signal rm_wr_en, rm_rd_en, rm_rd_valid : std_logic := '0';
    signal rm_addr : std_logic_vector(15 downto 0) := (others => '0');
    signal rm_wr_data, rm_rd_data : std_logic_vector(31 downto 0) := (others => '0');

    signal scratchpad : std_logic_vector(31 downto 0) := (others => '0');
    signal reg : std_logic_vector(7 downto 0) := (others => '0');
    signal id : std_logic_vector(31 downto 0) := x"DEADBEEF";

    signal uart_fifo_status : std_logic_vector(3 downto 0) := (others => '0');
begin

 	uart_db_inst : entity work.uart_debugger
    generic map(
		CLKRATE  => 50000000,
		BAUDRATE => 115200,
		DATA_SIZE => 8,
		FIFO_SIZE => 16
    )
	port map(
		clk => clk_board,
        
        rx => rx,
        tx => tx,
        
        uart_fifo_status => uart_fifo_status,
        
		rm_wr_en    => rm_wr_en,
        rm_rd_en    => rm_rd_en,
        rm_rd_valid => rm_rd_valid,
        rm_addr     => rm_addr,
        rm_wr_data  => rm_wr_data,
        rm_rd_data  => rm_rd_data
	);

    --Registers
    --[0] = scratchpad
    --[1] = Read Only ID
    --[2] = LEDs
	process(clk_board)
	begin
		if(rising_edge(clk_board)) then
			
            --Write to registers
            if(rm_wr_en = '1') then
            
                if(rm_addr = x"0000") then
                    scratchpad <= rm_wr_data;
                elsif(rm_addr = x"0002") then
                    reg <= rm_wr_data(7 downto 0);
                end if;
            
            
            end if;
            
            rm_rd_valid <= '0';
            
            if(rm_rd_en = '1') then
                
                if(rm_addr = x"0000") then
                    rm_rd_data <= scratchpad;
                elsif(rm_addr = x"0001") then
                    rm_rd_data <= id;
                else
                    rm_rd_data <= x"000000" & reg;
                end if;
                
                rm_rd_valid <= '1';

            end if;
    
		end if;
	end process;
	
    led0 <= reg(0);
    led1 <= reg(1);
    led2 <= reg(2);
    led3 <= reg(3);
    led4 <= uart_fifo_status(0);
    led5 <= uart_fifo_status(1);
    led6 <= uart_fifo_status(2);
    led7 <= uart_fifo_status(3);
	
end arch;