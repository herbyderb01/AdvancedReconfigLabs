library ieee;
use ieee.std_logic_1164.all;

package ripple_adder_pkg is

	constant DEFAULT_WIDTH	: integer := 10;
	
	component ripple_adder is
		generic (
			N : integer := DEFAULT_WIDTH
		);
		port (
			A		: in std_logic_vector(N-1 downto 0);
			B		: in std_logic_vector(N-1 downto 0);
			C_in 	: in std_logic;
			SUM	: out std_logic_vector(N-1 downto 0);
			C_out	: out std_logic
		);
	end component;
end package ripple_adder_pkg;

package body ripple_adder_pkg is
end package body ripple_adder_pkg;