library ieee;
use ieee.std_logic_1164.all;

package factorial_ROM_pkg is

	CONSTANT DEFAULT_WIDTH 			:	integer	:= 10;
	CONSTANT DEFAULT_INSTRUCTION	:	integer	:= 32;
	
	component factorial_ROM is
		PORT
		(
			address		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
			clock			: IN STD_LOGIC  := '1';
			q				: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
		);
	end component;
end package factorial_ROM_pkg;

package body factorial_ROM_pkg is
end package body factorial_ROM_pkg;