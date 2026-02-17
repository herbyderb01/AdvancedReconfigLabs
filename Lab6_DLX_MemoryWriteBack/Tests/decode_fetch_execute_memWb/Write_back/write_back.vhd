library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
--use work.MUX.pkg.all;
use work.decode_reg_pkg.all;

entity write_back is
	generic(
		DATA_WIDTH	:	integer := 32
	);
	port(
		RAM_output	:	in	std_logic_vector(DATA_WIDTH-1 downto 0);
		reg_ALU		:	in	std_logic_vector(DATA_WIDTH-1 downto 0);
		instruction	:	in	std_logic_vector(DATA_WIDTH-1 downto 0);
		
		wb_en			:	out	std_logic;
		wb_data		:	out	std_logic_vector(DATA_WIDTH-1 downto 0);
		wb_addr		:	out	std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end entity write_back;

architecture structural of write_back is
	
	signal mux_sel	:	std_logic := '0';
	signal opcode	:	std_logic_vector(5 downto 0);
	
begin

	opcode  <= instruction(31 downto 26);
	wb_addr <= instruction(25 downto 21);
	mux_sel <= '1' when opcode = "000001" else '0';
	wb_en	  <= '0' when (opcode = OP_NOP or opcode = OP_SW or
								opcode = OP_BEQZ or opcode = OP_BNEZ or
								opcode = OP_J	 or opcode = OP_JR)
					else '1';
	
	MUXXY		:	entity work.MUX
		generic map(
			N => 10
		)
		port map(
			A=> RAM_output,
			B=> reg_ALU,
			S=> mux_sel,
			OUTPUT=> wb_data
		);

end architecture structural;