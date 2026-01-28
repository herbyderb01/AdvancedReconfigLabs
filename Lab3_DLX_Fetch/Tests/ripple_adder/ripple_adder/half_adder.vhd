library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity half_adder is
    port (
        A     : in  std_logic;
        B     : in  std_logic;
        SUM   : out std_logic;
        CARRY : out std_logic
    );
end entity half_adder;

architecture rtl of half_adder is
begin
    SUM   <= A xor B;
    CARRY <= A and B;
end architecture rtl;
