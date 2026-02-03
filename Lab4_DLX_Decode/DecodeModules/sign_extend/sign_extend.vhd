library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sign_extend is
    port (
        input  : in  std_logic_vector(15 downto 0);
        output : out std_logic_vector(31 downto 0)
    );
end entity sign_extend;

architecture behavior of sign_extend is
begin
    output <= std_logic_vector(resize(signed(input), 32));
end architecture behavior;
