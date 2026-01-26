library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MUX is
	generic (
		N : integer	:= 10
	);
	port (
		A		:	in		std_logic_vector(N-1 downto 0);
		B		:	in 	std_logic_vector(N-1 downto 0);
		S		:	in 	std_logic;
		OUTPUT:	out 	std_logic_vector(N-1 downto 0);
	);
end entity MUX;

architecture rtl of MUX is

begin

	OUTPUT <= A when S = '1' else B;
	
end architecture rtl