library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HEX_seven_seg_disp_6 is
	port (
		IN0 : in std_logic_vector(3 downto 0);
		IN1 : in std_logic_vector(3 downto 0);
		IN2 : in std_logic_vector(3 downto 0);
		IN3 : in std_logic_vector(3 downto 0);
		IN4 : in std_logic_vector(3 downto 0);
		IN5 : in std_logic_vector(3 downto 0);
		clk : in std_logic;
		HEX0 : out std_logic_vector(7 downto 0);
		HEX1 : out std_logic_vector(7 downto 0);
		HEX2 : out std_logic_vector(7 downto 0);
		HEX3 : out std_logic_vector(7 downto 0);
		HEX4 : out std_logic_vector(7 downto 0);
		HEX5 : out std_logic_vector(7 downto 0)
	);
end HEX_seven_seg_disp_6;

architecture component_list of HEX_seven_seg_disp_6 is
	component HEX_seven_seg_disp
		port (
			clk : in std_logic;
			hex : in std_logic_vector(3 downto 0);
			oseg : out std_logic_vector(7 downto 0)
		);
	end component HEX_seven_seg_disp;
begin

	disp1 : HEX_seven_seg_disp
		port map (
			clk => clk,
			hex => IN0,
			oseg => HEX0
		);
	disp2 : HEX_seven_seg_disp
		port map (
			clk => clk,
			hex => IN1,
			oseg => HEX1
		);
	disp3 : HEX_seven_seg_disp
		port map (
			clk => clk,
			hex => IN2,
			oseg => HEX2
		);
	disp4 : HEX_seven_seg_disp
		port map (
			clk => clk,
			hex => IN3,
			oseg => HEX3
		);
	disp5 : HEX_seven_seg_disp
		port map (
			clk => clk,
			hex => IN4,
			oseg => HEX4
		);
	disp6 : HEX_seven_seg_disp
		port map (
			clk => clk,
			hex => IN5,
			oseg => HEX5
		);
		

end component_list;