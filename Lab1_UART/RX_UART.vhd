library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RX_UART is
	port 
	(
		--CLK input (8x Baud Rate)--
		clk : in std_logic;
		--input bit--
		Rx: in std_logic;
		--output bits--
		wrreq: out std_logic;
		data_out: out std_logic_vector(7 downto 0)
	);
end entity RX_UART;

architecture component_list of RX_UART is

	type bits is (start, data, stop);
	type oversample is (idle, throw_away_start, acquire, throw_away_end);
	
	-- Initialize state machines start states
	signal bit_state : bits := start;
	signal sample_state : oversample := idle;
	
	signal oversample_counter : integer range 0 to 7 := 0;
	signal one_count : integer range 0 to 8 := 0;
	signal zero_count : integer range 0 to 8 := 0;
	signal data_count : integer range 0 to 8 := 0;
	
	signal true_data : std_logic := '0';
	signal sample_rdy : std_logic := '0';
	
	signal rx_data_buffer : std_logic_vector(7 downto 0) := (others => '0');
	
begin
	
	data_out <= rx_data_buffer;

	--state machines--
	process (clk)
	begin
		if rising_edge(clk) then
			
			-- default one-cycle signals
			wrreq <= '0'; 

			-- ==========================================
			-- Bit State Machine (Tracks Frame Progress)
			-- ==========================================
			case bit_state is
				when start =>
					-- Wait for the Oversample machine to tell us it found a bit
					if sample_rdy = '1' then
						-- We expect a '0' for a valid Start bit
						if true_data = '0' then
							bit_state <= data;
							data_count <= 0;
						end if;
						-- If true_data is '1', it was a glitch, stay in start (and Oversample machine will go back to IDLE)
					end if;
					
				when data => 
					if sample_rdy = '1' then
						rx_data_buffer(data_count) <= true_data; -- Shift in LSB first? Standard is LSB. Array index matches.
						
						if data_count = 7 then
							bit_state <= stop;
						else
							data_count <= data_count + 1;
						end if;
					end if;
					
				when stop => 
					if sample_rdy = '1' then
						-- We expect a '1' for a valid Stop bit
						if true_data = '1' then
							wrreq <= '1'; -- Good valid byte!
						end if;
						-- Regardless of whether stop bit was valid frame or error, we reset to look for next start
						bit_state <= start;
					end if;
			end case;
			
			-- ==========================================
			-- Oversample State Machine (Samples the Line)
			-- 8x Oversampling (8 Clocks per bit)
			-- ==========================================
			case sample_state is
				when idle =>
					sample_rdy <= '0';
					oversample_counter <= 0;
					zero_count <= 0;
					one_count <= 0;
					
					-- Synchronize to falling edge of Start Bit
					-- Only start if we are expecting a start bit (bit_state = start)
					-- or if we are already in the middle of a frame (bit_state != start)
					-- But actually, loop control is handled in throw_away_end.
					
					if Rx = '0' and bit_state = start then
						sample_state <= throw_away_start;
					end if;

				when throw_away_start =>
					-- Skip first 2 ticks (Ticks 0, 1)
					if oversample_counter < 1 then
						oversample_counter <= oversample_counter + 1;
					else 
						oversample_counter <= 0;
						sample_state <= acquire;
						zero_count <= 0;
						one_count <= 0;
					end if;
					
				when acquire =>
					-- Vote on middle 4 ticks (Ticks 2, 3, 4, 5)
					if oversample_counter < 3 then
						oversample_counter <= oversample_counter + 1;
						if Rx = '0' then
							zero_count <= zero_count + 1;
						else
							one_count <= one_count + 1;
						end if;
					else
						-- Final vote tally
						if Rx = '0' then
							zero_count <= zero_count + 1;
						else
							one_count <= one_count + 1;
						end if;
						
						oversample_counter <= 0;
						sample_state <= throw_away_end;
					end if;

				when throw_away_end =>
					-- Decision Time (happens immediately upon entering state)
					-- Note: zero_count/one_count updated at end of acquire, so values are valid now.
					if zero_count > one_count then
						true_data <= '0';
					else
						true_data <= '1';
					end if;
					sample_rdy <= '1'; -- Signal valid data for one cycle

					-- Skip last 2 ticks (Ticks 6, 7)
					if oversample_counter < 1 then
						oversample_counter <= oversample_counter + 1;
					else 
						oversample_counter <= 0;
						sample_rdy <= '0'; -- Clear ready flag
						
						-- Where do we go next?
						if bit_state = stop then
							-- We just finished the Stop bit. Go to IDLE to wait for next Start bit edge.
							sample_state <= idle;
						elsif bit_state = start and true_data = '1' then
							-- We thought we saw a Start bit, but the voting said it was '1' (Glitch). Reset.
							sample_state <= idle;
						else
							-- We are in the middle of data bits (or moving Start->Data), 
							-- jump straight to next bit sampling without waiting for edge.
							sample_state <= throw_away_start; 
						end if;
					end if;
			end case;
			
		end if;
	end process;	

end component_list;