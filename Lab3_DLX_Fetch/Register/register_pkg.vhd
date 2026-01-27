library ieee;
use ieee.std_logic_1164.all;

package register_pkg is 
	
	constant DEFAULT_WIDTH	:	integer	:=	10;
	
	component reggi is 	
		generic	(
			N	:	integer	:=	DEFAULT_WIDTH
		);
		port	(
			data_in	:	in 	std_logic_vector(N-1 downto 0);
			rst		:	in		std_logic;
			clk		:	in		std_logic;
			data_out	:	out	std_logic_vector(N-1 downto 0);
		);
	end component;
end package register_pkg;

package body register_pkg is
end package body register_pkg;