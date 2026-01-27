library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reggi is
	generic	(
		N	:	integer	:= 10
	);
	port	(
		data_in	:	in 	std_logic_vector(N-1 downto 0);
		rst		:	in		std_logic;
		clk		:	in		std_logic;
		data_out	:	out	std_logic_vector(N-1 downto 0)
	);
end entity reggi;

architecture behavioral of reggi is

	signal output_data	:	std_logic_vector(N-1 downto 0)	
	:= (others => '0');

begin

	data_out <= output_data;
	process(clk) begin
		if rising_edge(clk) then
			if rst = '1' then
				output_data <= (others => '0');
			else
				output_data <= data_in;
			end if;
		end if;
	end process;

end architecture behavioral;