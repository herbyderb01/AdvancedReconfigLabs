library ieee;
use ieee.std_logic_1164.all;

package half_adder_pkg is
    component half_adder is
        port (
            A     : in  std_logic;
            B     : in  std_logic;
            SUM   : out std_logic;
            CARRY : out std_logic
        );
    end component;
end package half_adder_pkg;

package body half_adder_pkg is
end package body half_adder_pkg;
