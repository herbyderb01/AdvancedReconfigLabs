library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.decode_reg_pkg.all;

entity Memory is
	generic(
		DATA_WIDTH	:	integer := 32
	);
	port(
		clk	:	in	std_logic;
		rst	:	in	std_logic;
		
		instruction	:	in		std_logic_vector(DATA_WIDTH-1 downto 0);
		ALU_result	:	in 	std_logic_vector(DATA_WIDTH-1 downto 0);
		rs2_data		:	in		std_logic_vector(DATA_WIDTH-1 downto 0);
		pc_inc		:	in		std_logic_vector(9 downto 0);
		
		RAM_output	:	out 	std_logic_vector(DATA_WIDTH-1 downto 0);
		reg_ALU		:	out	std_logic_vector(DATA_WIDTH-1 downto 0);
		instr_out	:	out	std_logic_vector(DATA_WIDTH-1 downto 0);
		pc_out		:	out   std_logic_vector(9 downto 0)
	);
end entity;

architecture structural of Memory is
	
	signal trunc_addr	:	std_logic_vector(9 downto 0);
	signal wren			:	std_logic := '0';
begin

	trunc_addr<=ALU_result(9 downto 0);
	wren <= '1' when instruction(31 downto 26) = OP_SW else '0';
	
	DATA_MEM	:	entity work.factorial_ram
		port map(
			address=>trunc_addr,
			clock=>clk,
			data=>rs2_data,
			wren=>wren,
			q=>RAM_output
		);
		
	PC_out_reg	:	entity work.reggi
		generic map(
			N=>10
		)
		port map(
			data_in=>pc_inc,
			rst=>rst,
			clk=>clk,
			data_out=>pc_out
		);
	
	reg_ALU_reg	:	entity work.reggi
		generic map(
			N=>32
		)
		port map(
			data_in=> ALU_result,
			rst=>rst,
			clk=>clk,
			data_out=>reg_ALU
		);

	instr_addr_reg	:	entity work.reggi
		generic map(
			N=>32
		)
		port map(
			data_in=>instruction,
			rst=>rst,
			clk=>clk,
			data_out=>instr_out
		);
		
end architecture structural;