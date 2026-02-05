library ieee;
use ieee.std_logic_1164.all;

package sign_extend_pkg is
    component sign_extend is
        port (
            input_data  : in  std_logic_vector(15 downto 0);
            output_data : out std_logic_vector(31 downto 0)
        );
    end component;
end package sign_extend_pkg;
