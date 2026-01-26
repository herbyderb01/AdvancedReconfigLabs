library ieee;
use ieee.std_logic_1164.all;

package MUX_pkg is

	constant DEFAULT_WIDTH	:	integer	:= 10;
	
	component MUX is 
		generic (
			N	:	integer	:=	DEFAULT_WIDTH
		);
		port (
			A		:	in		std_logic_vector(N-1 downto 0);
			B		:	in 	std_logic_vector(N-1 downto 0);
			S		:	in 	std_logic;
			OUTPUT:	out 	std_logic_vector(N-1 downto 0);
		);
	end component;
end package MUX;

package body MUX_pkg is
end package body MUX_pkg;