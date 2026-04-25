-- =============================================================================
-- ripple_adder.vhd  --  N-bit ripple-carry adder (built from full_adder cells)
-- =============================================================================
-- Standard textbook ripple adder. The fetch stage uses this with B hardwired
-- to "...0001" and C_in = '0' to compute PC + 1 for the next instruction
-- address. C_out is exposed but unused at the top level (PC width is fixed
-- at 10 bits, so overflow is not a concern for our 1024-deep ROM).
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
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
		FA	:	entity work.full_adder
			port map(
				A	 	=>	A(i),
				B 		=>	B(i),
				C_in	=> C(i),
				SUM 	=> SUM(i),
				CARRY => C(i+1)
			);
	end generate gen_adders;
	
	C_out <= C(N);

end architecture rtl;