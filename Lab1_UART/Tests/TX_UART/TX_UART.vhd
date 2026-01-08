library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TX_UART is
	port 
	(
		--CLK input (19200 Hz)--
		Pclk : in std_logic;
		--output bit--
		Tx: out std_logic;
		rdreq: out std_logic;
		--input bits--
		empty: in std_logic;                     -- Signal to start transmission
		data_in: in std_logic_vector(7 downto 0) -- Byte to transmit
	);
end entity TX_UART;

architecture component_list of TX_UART is

	type state_type is (idle, start_bit, data_bits, stop_bit);
	signal state : state_type := idle;
	
	-- Index to track which bit (0-7) is being sent
	signal bit_index : integer range 0 to 7 := 0;
	
	-- Register to latch the data
	signal tx_data_reg : std_logic_vector(7 downto 0) := (others => '0');
	
begin
	
	process (Pclk)
	begin
		if rising_edge(Pclk) then
			
			case state is
				when idle =>
					Tx <= '1'; -- UART Idle line is High
					bit_index <= 0;
					
					-- When write request is received, latch data and start
					if empty = '0' then
						rdreq <= '1';
						tx_data_reg <= data_in;
						state <= start_bit;
					end if;
					
				when start_bit =>
					rdreq <= '0';
					Tx <= '0'; -- Start bit is Low
					state <= data_bits;
					
				when data_bits =>
					Tx <= tx_data_reg(bit_index); -- Send LSB first
					
					-- Move to next bit or stop bit
					if bit_index < 7 then
						bit_index <= bit_index + 1;
					else
						bit_index <= 0;
						state <= stop_bit;
					end if;
					
				when stop_bit =>
					Tx <= '1'; -- Stop bit is High
					state <= idle; -- Transmission complete
					
			end case;
		end if;
	end process;

end component_list;