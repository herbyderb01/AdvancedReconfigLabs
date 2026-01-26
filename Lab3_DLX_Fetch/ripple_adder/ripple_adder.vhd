library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.full_adder_pkg.all;

entity ripple_adder is
	generic (
		N : integer := 10
	);
	port (
		A		: in std_logic_vector(N-1 downto 0);
		B		: in std_logic_vector(N-1 downto 0);
		C_in 	: in std_logic;
		SUM	: out std_logic_vector(N-1 downto 0);
		C_out	: out std_logic
	);
end entity ripple_adder;

architecture rtl of ripple_adder is

	signal C	: std_logic_vector(N downto 0);
	
begin

	C(0) <= C_in;
	
	gen_adders : for i in 0 to N-1 generate
		FA	:	full_adder
			port map(
				A	 	=>	A(i),
				B 		=>	B(i),
				C_in	=> C(i),
				SUM 	=> SUM(i),
				CARRY => C(i+1),
			);
	end generate;
	
	C_out <= C(N);

end architecture rtl