library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity RX_UART is
	port 
	(
		--CLK input--
		Pclk : in std_logic;
		--input bit--
		Rx: in std_logic;
		--output bits--
		wrreq: out std_logic;
		data_in: out std_logic_vector(7 downto 0)
	);
end entity RX_UART;

architecture component_list of RX_UART is

	type bits is (start, data, stop);
	type oversample is (throw_away_start, acquire, throw_away_end);
	
	signal bit_state:bits;
	signal sample_state:oversample;
	integer oversample_counter = 0;
	integer one_count = 0;
	integer zero_count = 0;
	integer data_count = 0;
	signal true_data;
	signal sample_rdy;
	
begin
	
	--state machines--
	process (Pclk)

	if rising_edge(Pclk) then
	
		-- state for keeping track of data frame --
		case bit_state is
			when start =>
				if sample_rdy == 1 and true_data == 0 then
					bit_state <= data;
				end if
			when data => 
				if data_count != 8 && sample_rdy then
					data_in[data_count];
					data_count = data_count + 1;
				elsif data_count == 8 then
					bit_state <= stop;
					data_count = 0
				end if;
			when stop => 
				if sample_rdy == 1 and true_data == 1 then
					wrreq = 1;
					bit_state <= start;
				end if
		end case;
		
		-- state for keeping track of oversampling--
		case oversample is
			when throw_away_start =>
				if oversample_counter != 4 then
					oversample_counter = oversample_counter + 1;
				else 
					oversample_counter = 0;
					oversample <= acquire;
				end if;
			when acquire =>
				if oversample_counter != 8
					oversample_counter = oversample_counter + 1;
					if Rx == 0
						zero_count = zero_count + 1;
					else
						one_count = one_count + 1;
					end if;
				else
					oversample_counter = 0;
					sample_rdy = 1;
					if zero_count > one_count
						true_data = 0;
					else
						true_data = 1;
					end if;
					oversample <= throw_away_end
				end if;
			when throw_away_end =>
				sample_rdy = 0;
				if oversample_counter != 4
					oversample_counter = oversample_counter + 1;
				else 
					oversample_counter = 0;
					oversample <= throw_away_start;
				end if;
		end case;
		--End of oversample state machine--
	end if;
	end process
	

end component_list;