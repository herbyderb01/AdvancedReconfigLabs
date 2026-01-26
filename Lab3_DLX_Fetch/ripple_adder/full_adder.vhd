library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.half_adder_pkg.all;

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
   HA0 : half_adder
		port map (
			A		=> A,
			B		=> B,
			SUM	=> SUM_AB,
			CARRY => CARRY_AB
		);
	HA1 : half_adder
		port map (
			A		=> SUM_AB,
			B 		=> C_IN,
			SUM 	=> SUM,
			CARRY => CARRY_ABC
		);
		
	CARRY <= CARRY_ABC or CARRY_AB;
end architecture rtl;
