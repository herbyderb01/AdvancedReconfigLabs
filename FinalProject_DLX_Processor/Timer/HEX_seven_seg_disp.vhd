library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HEX_seven_seg_disp is
	port (
		hex : in std_logic_vector(3 downto 0);
		clk : in std_logic;
		oseg : out std_logic_vector(7 downto 0)
	);
end HEX_seven_seg_disp;

architecture behavior of HEX_seven_seg_disp is
	type HEX_TABLE is array (0 to 15) of std_logic_vector(7 downto 0);
	constant table : HEX_TABLE := ("11000000", "11111001", "10100100", "10110000", "10011001", "10010010", "10000010",
		"11111000", "10000000", "10011000", "10001000", "10000011", "11000110", "10100001", "10000110", "10001110");
begin
	process(clk) 
	begin
	if rising_edge(clk) then
		case to_integer(unsigned(hex)) is
		when 0 =>
			oseg <= table(0);
		when 1 =>
			oseg <= table(1);
		when 2 =>
			oseg <= table(2);
		when 3 =>
			oseg <= table(3);
		when 4 =>
			oseg <= table(4);
		when 5 =>
			oseg <= table(5);
		when 6 =>
			oseg <= table(6);
		when 7 =>
			oseg <= table(7);
		when 8 =>
			oseg <= table(8);
		when 9 =>
			oseg <= table(9);
		when 10 =>
			oseg <= table(10);
		when 11 =>
			oseg <= table(11);
		when 12 =>
			oseg <= table(12);
		when 13 =>
			oseg <= table(13);
		when 14 =>
			oseg <= table(14);
		when 15 =>
			oseg <= table(15);
		when others =>
			oseg <= "11111111";
		end case;
	end if;
	end process;
end behavior;