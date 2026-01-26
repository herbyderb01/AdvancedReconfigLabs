library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.register_pkg.all;
use work.MUX_pkg.all;
use work.ripple_adder_pkg.all;

entity fetch is
	generic	(
		N	:	integer	:= 10;
		M	:	integer	:=	32;
	);
	port	(
		jump_addr	:	in		std_logic_vector(N-1 downto 0);
		pc_select	:	in		std_logic;
		rst			:	in		std_logic;
		clk			:	in		std_logic;
		decode_addr	:	out	std_logic_vector(N-1 downto 0);
		instruction	:	out	std_logic_vector(M-1 downto 0);
	)
end entity;

architecture component_list of fetch is

	signal	new_addr	:	std_logic_vector(N-1 downto 0) := (others => 0);
	signal	addr		:	std_logic_vector(N-1 downto 0) := (others => 0);
	signal 	sum		:	std_logic_vector(N-1 downto 0) := (others => 0);
	signal 	C_DUMMY	:	std_logic;
	
	constant LSB_ONE 	: 	std_logic_vector(N-1 downto 0) := 
      (N-2 downto 0 => '0') & '1';
	constant ZERO		: 	std_logic := '0'

begin

	PC_counter	:	register 
		generic map(
			N => 10
		);
		port map(
			data_in 	=> new_addr,
			rst 		=>	rst,
			clk		=>	clk,
			data_out	=>	addr
		);
		
	ADDER		:	ripple_adder
		generic map(
			N => 10
		);
		port map(
			A		=> addr,
			B		=> LSB_ONE,	
			C_in 	=> ZERO,
			SUM	=> sum,
			C_out => C_DUMMY
		);
		
	MUXXY		:	MUX
		generic map(
			N => 10
		);
		port map(
			A		=>	jump_addr,
			B		=> sum,
			S		=> pc_select,
			OUTPUT=>	new_addr
		);
		
	MUX_REGISTER	:	register
		generic map(
			N => 10
		);
		port map(
			data_in	=> new_addr,
			rst		=>	rst,
			clk		=>	clk,
			data_out	=>	decode_addr
		);
		
	--insert IP ROM device with .mif file

end architecture component_list