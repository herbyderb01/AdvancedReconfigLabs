-- =============================================================================
-- register_async_pkg.vhd  --  Component declaration for reggi_async.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

package register_async_pkg is
	
	constant DEFAULT_WIDTH	:	integer	:=	10;
	
	component reggi_async is 	
		generic	(
			N	:	integer	:=	DEFAULT_WIDTH
		);
		port	(
			data_in	:	in 	std_logic_vector(N-1 downto 0);
			rst		:	in		std_logic;
			clk		:	in		std_logic;
			data_out	:	out	std_logic_vector(N-1 downto 0)
		);
	end component;
end package register_async_pkg;

package body register_async_pkg is
end package body register_async_pkg;