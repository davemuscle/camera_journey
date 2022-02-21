library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

--Custom Debugging/Control over UART

--The UART_debugger converts 8 bytes from the UART core into:
	--a 16 bit address, 32 bit data, and read/write signal
--Connects to a register map to control FPGA components over a PC com port
--Data is sent/received in big endian format

--Python<->FPGA Messaging Format
-- [Start]
-- [Write or read code]
-- [Addr Byte 1]
-- [Addr Byte 0]
-- [Data Byte 3]
-- [Data Byte 2]
-- [Data Byte 1]
-- [Data Byte 0]

--For write ACKs, echo back the received data
--For read  ACKs, transmit the read data

entity uart_debugger is
    generic(
		CLKRATE   : integer := 50000000;
		BAUDRATE  : integer := 115200;
		DATA_SIZE : integer := 8;
		FIFO_SIZE : integer := 16
    );
	port(
		clk   : in std_logic; -- clock
        
        rx : in  std_logic;        --to top level uart pins
        tx : out std_logic := '0'; --to top level uart pins
        
        uart_fifo_status : out std_logic_vector(3 downto 0) := (others => '0'); --fifo sticky bits
   
        rm_wr_en    : out std_logic := '0';                                 --wr en pulse to register map
        rm_rd_en    : out std_logic := '0';                                 --rd en pulse to regiser map
        rm_rd_valid : in  std_logic;                                        --rd valid pulse from register map
        rm_addr     : out std_logic_vector(15 downto 0) := (others => '0'); --reg map address
        rm_wr_data  : out std_logic_vector(31 downto 0) := (others => '0'); --reg map wr data
        rm_rd_data  : in  std_logic_vector(31 downto 0)                     --reg map rd data
		
	);
end uart_debugger;

architecture bhv of uart_debugger is 
	
    --Messaging constants
	constant udb_sof  : std_logic_vector(7 downto 0) := x"7E";
    constant udb_esc  : std_logic_vector(7 downto 0) := x"7D";
    constant udb_xor  : std_logic_vector(7 downto 0) := x"20";
	constant udb_wr   : std_logic_vector(7 downto 0) := x"37";
	constant udb_rd   : std_logic_vector(7 downto 0) := x"38";
    
    --UART core signals
    signal rx_valid   : std_logic := '0';
    signal rx_rd_en   : std_logic := '0';
    signal rx_rd_data : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_ready   : std_logic := '0';
    signal tx_wr_en   : std_logic := '0';
    signal tx_wr_data : std_logic_vector(7 downto 0) := (others => '0');
    
    --UART core fifo status
    signal rx_fifo_ov, rx_fifo_ov_s : std_logic := '0';
    signal rx_fifo_un, rx_fifo_un_s : std_logic := '0';
    signal tx_fifo_ov, tx_fifo_ov_s : std_logic := '0';
    signal tx_fifo_un, tx_fifo_un_s : std_logic := '0';
    
    --Byte Arrays for UART comms
	type   byte_array is array(0 to 7) of std_logic_vector(7 downto 0);
	signal rx_bytes : byte_array := (others => (others => '0'));
	signal tx_bytes : byte_array := (others => (others => '0'));
	
    --Receive Processing
    signal rx_busy : std_logic := '0';
    signal rx_start_det : std_logic := '0';
	signal rx_byte_cnt : integer range 0 to 7 := 0;
    signal rx_esc_det  : std_logic := '0';
	signal rx_rd_en_dly : std_logic := '0';
	signal rx_bytes_ready : std_logic := '0';
	
    --Transmit Processing
    signal tx_send_en   : std_logic := '0';
    signal tx_send_go   : std_logic := '0';
    signal tx_wr_cnt : integer range 0 to 7 := 0;
	signal tx_esc_det : std_logic := '0';

    --Needed this to read an output pin
    signal rm_wr_en_int : std_logic := '0';
    
begin

    --Instantiate UART core
	uart_inst : entity work.uart
	generic map(
		CLKRATE   =>   CLKRATE,
		BAUDRATE  =>  BAUDRATE,
		DATA_SIZE => DATA_SIZE,
		FIFO_SIZE => FIFO_SIZE
	)
	port map(
		clk        => clk,
		rx         => rx,
		tx         => tx,
		rx_valid   => rx_valid,
		rx_full    => open,
		rx_rd_en   => rx_rd_en,
		rx_rd_data => rx_rd_data,
		rx_fifo_ov => rx_fifo_ov,
		rx_fifo_un => rx_fifo_un,
		tx_ready   => open,
		tx_empty   => tx_ready,
		tx_wr_en   => tx_wr_en,
		tx_wr_data => tx_wr_data,
		tx_fifo_ov => tx_fifo_ov,
		tx_fifo_un => tx_fifo_un
	);

    --Sticky bits for fifo signals
    process(clk)
    begin
        if(rising_edge(clk)) then
            if(rx_fifo_ov = '1') then
                rx_fifo_ov_s <= '1';
            end if;
            if(tx_fifo_ov = '1') then
                tx_fifo_ov_s <= '1';
            end if;        
            if(rx_fifo_un = '1') then
                rx_fifo_un_s <= '1';
            end if;     
            if(tx_fifo_un = '1') then
                tx_fifo_un_s <= '1';
            end if;  
        end if;
    end process;
    
    --UART Fifo Status Output
    uart_fifo_status <= tx_fifo_ov_s & tx_fifo_un_s & rx_fifo_ov_s & rx_fifo_un_s;

	--load data from the UART receive fifo into the debugger registers
	process(clk)
	begin
		if(rising_edge(clk)) then


			--if the rx fifo has valid data, read from it
            if(rx_valid = '1' and rx_busy = '0') then
                rx_rd_en <= '1';
                rx_busy <= '1';
            end if;

			--default the fifo read enable to zero
            if(rx_busy = '1') then
                rx_rd_en <= '0';
            end if;
		
			--delay it a clock cycle for logic
			rx_rd_en_dly <= rx_rd_en;
			
			--read each byte from the fifo for the frame
			if(rx_rd_en_dly = '1') then

                rx_busy <= '0';

                if(rx_rd_data = udb_esc) then
                    -- don't load the escape byte
                    rx_esc_det <= '1';

                else
                    rx_esc_det <= '0';

                    if(rx_esc_det = '1') then
                        --load the xor version of the byte
                        rx_bytes(0) <= rx_rd_data xor udb_xor;
                    else
                        --load the byte as-is
                        rx_bytes(0) <= rx_rd_data;
                    end if;

                    --shift bytes over
                    rx_bytes(1 to 7) <= rx_bytes(0 to 6);

                    if(rx_rd_data = udb_sof) then
                        --resync count if this is a start byte
                        rx_byte_cnt <= 1;
                        rx_bytes_ready <= '0';
                        rx_start_det <= '1';
                    elsif(rx_byte_cnt = 7) then
                        --reset count and signal we have a frame loaded
                        rx_byte_cnt <= 0;
                        rx_start_det <= '0';
                        if(rx_start_det = '1') then
                            rx_bytes_ready <= '1';
                        else
                            rx_bytes_ready <= '0';
                        end if;
                    else
                        --continue counting
                        rx_byte_cnt <= rx_byte_cnt + 1;
                        rx_bytes_ready <= '0';
                    end if;
                    
                end if;

			end if;
		
			--pulse the ready signal for the process below
			if(rx_bytes_ready = '1') then
				rx_bytes_ready <= '0';
			end if;
            
		end if;
	end process;

    --Setup the read or write to the memory map
    process(clk)
    begin
        if(rising_edge(clk)) then
            
            rm_wr_en_int <= '0';
            rm_rd_en <= '0';
            
            if(rx_bytes_ready = '1') then
        
                if(rx_bytes(6) = udb_wr) then
                    rm_wr_en_int <= '1';
                elsif(rx_bytes(6) = udb_rd) then
                    rm_rd_en <= '1';
                end if;
 
                rm_addr    <= rx_bytes(5) & rx_bytes(4);
                rm_wr_data <= rx_bytes(3) & rx_bytes(2) & rx_bytes(1) & rx_bytes(0);
            end if;
     
        end if;
    end process;

    rm_wr_en <= rm_wr_en_int;

    --For writes, echo back the entire frame
    --For reads, echo back the received data but with the data we actually want
    process(clk)
    begin
        if(rising_edge(clk)) then
        
            --Echo back the received data
            if(rm_wr_en_int = '1') then
                tx_send_en <= '1';
                tx_bytes(7) <= rx_bytes(7);
                tx_bytes(6) <= rx_bytes(6);
                tx_bytes(5) <= rx_bytes(5);
                tx_bytes(4) <= rx_bytes(4);
                tx_bytes(3) <= rx_bytes(3);
                tx_bytes(2) <= rx_bytes(2);
                tx_bytes(1) <= rx_bytes(1);
                tx_bytes(0) <= rx_bytes(0);          
            end if;
        
            --Transmit the read data, expecting this to be a pulse
            if(rm_rd_valid = '1') then
                tx_send_en <= '1';
                tx_bytes(7) <= rx_bytes(7);
                tx_bytes(6) <= rx_bytes(6);
                tx_bytes(5) <= rx_bytes(5);
                tx_bytes(4) <= rx_bytes(4);
                tx_bytes(3) <= rm_rd_data(31 downto 24);
                tx_bytes(2) <= rm_rd_data(23 downto 16);
                tx_bytes(1) <= rm_rd_data(15 downto  8);
                tx_bytes(0) <= rm_rd_data( 7 downto  0);
            end if;
        
            if(tx_send_en = '1' and tx_ready = '1') then
                tx_send_go <= '1';
            end if;
            
            tx_esc_det <= '0';
        
            if(tx_send_go = '1') then

                tx_wr_en <= '1';
                
                if(tx_wr_cnt /= 0 and (tx_bytes(7) = udb_sof or tx_bytes(7) = udb_esc) and tx_esc_det = '0') then
                    tx_esc_det <= '1';
                    tx_wr_data <= udb_esc;
                else
                
                    if(tx_esc_det = '1') then
                        tx_esc_det <= '0';
                        tx_wr_data <= tx_bytes(7) xor udb_xor;
                    
                    else
                    
                        tx_wr_data <= tx_bytes(7);
                    
                    end if;
                
                    tx_bytes(1 to 7) <= tx_bytes(0 to 6);
  
                end if;

            end if;
            
            if(tx_wr_en = '1' and tx_esc_det = '0') then
                if(tx_wr_cnt = 7) then
                    tx_wr_en   <= '0';
                    tx_send_en <= '0';
                    tx_send_go <= '0';
                    tx_wr_cnt <= 0;
                else
                    tx_wr_cnt <= tx_wr_cnt + 1;
                end if;
            end if;
        
        end if;
    end process;

end bhv;		

