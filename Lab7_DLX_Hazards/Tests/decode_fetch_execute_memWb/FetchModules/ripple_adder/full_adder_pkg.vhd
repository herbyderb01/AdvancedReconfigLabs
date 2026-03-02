library ieee;
use ieee.std_logic_1164.all;

package full_adder_pkg is 
	component full_adder is
		 port (
			  A     : in  std_logic;
			  B     : in  std_logic;
			  C_IN  : in  std_logic;
			  SUM   : out std_logic;
			  CARRY : out std_logic
		 );
	end component;
end package full_adder_pkg;

package body full_adder_pkg is
end package body full_adder_pkg;