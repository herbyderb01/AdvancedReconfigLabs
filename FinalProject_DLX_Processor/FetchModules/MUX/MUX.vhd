-- =============================================================================
-- MUX.vhd  --  Generic 2-to-1 N-bit multiplexer
-- =============================================================================
-- Convention used throughout the project:
--   S = '1' -> OUTPUT = A
--   S = '0' -> OUTPUT = B
-- (Note: this is reversed from the textbook A=0/B=1 ordering.)
--
-- Used in the fetch jump MUX (jump_addr vs PC+1), the execute forwarding MUXes
-- (rs1/rs2 register vs forwarded data), and the write-back source MUX.
-- =============================================================================

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
		OUTPUT:	out 	std_logic_vector(N-1 downto 0)
	);
end entity MUX;

architecture rtl of MUX is

begin

	OUTPUT <= A when S = '1' else B;
	
end architecture rtl;