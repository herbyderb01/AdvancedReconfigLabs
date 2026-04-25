-- =============================================================================
-- full_adder.vhd  --  Single-bit full adder built from two half adders.
-- =============================================================================
-- SUM   = A XOR B XOR C_IN
-- CARRY = (A and B) or ((A xor B) and C_IN)
-- Implemented here by chaining two half_adder cells and ORing the two carry
-- outputs.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
--use work.half_adder_pkg.all;

entity full_adder is
    port (
        A     : in  std_logic;
        B     : in  std_logic;
		  C_IN  : in  std_logic;
        SUM   : out std_logic;
        CARRY : out std_logic
    );
end entity full_adder;

architecture rtl of full_adder is

signal SUM_AB		:	std_logic;
signal CARRY_AB	:	std_logic;
signal CARRY_ABC	:	std_logic;

begin
   HA0 : entity work.half_adder
		port map (
			A		=> A,
			B		=> B,
			SUM	=> SUM_AB,
			CARRY => CARRY_AB
		);
	HA1 : entity work.half_adder
		port map (
			A		=> SUM_AB,
			B 		=> C_IN,
			SUM 	=> SUM,
			CARRY => CARRY_ABC
		);
		
	CARRY <= CARRY_ABC or CARRY_AB;
end architecture rtl;
