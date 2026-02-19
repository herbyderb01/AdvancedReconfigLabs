library ieee;
use ieee.std_logic_1164.all;

package fetch_pkg is

	CONSTANT DEFAULT_WIDTH 			:	integer	:= 10;
	CONSTANT DEFAULT_INSTRUCTION	:	integer	:= 32;
	
	component fetch is
		generic	(
			N	:	integer	:= DEFAULT_WIDTH;
			M	:	integer	:=	DEFAULT_INSTRUCTION;
		);
		port	(
			jump_addr	:	in		std_logic_vector(N-1 downto 0);
			pc_select	:	in		std_logic;
			rst			:	in		std_logic;
			clk			:	in		std_logic;
			decode_addr	:	out	std_logic_vector(N-1 downto 0);
			instruction	:	out	std_logic_vector(M-1 downto 0);
		);
	end component
end package fetch_pkg

package body fetch_pkg is
end package body fetch_pkg;