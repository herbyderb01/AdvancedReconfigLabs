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
		pc_inc		:	in	std_logic_vector(9 downto 0);
		
		wb_en			:	out	std_logic;
		wb_data		:	out	std_logic_vector(DATA_WIDTH-1 downto 0);
		wb_addr		:	out	std_logic_vector(4 downto 0)
	);
end entity write_back;

architecture structural of write_back is
	
	signal mux_sel	:	std_logic := '0';
	signal opcode	:	std_logic_vector(5 downto 0);
	signal mux_out	:	std_logic_vector(DATA_WIDTH-1 downto 0);
	signal pc_data	:	std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	
begin
	
	pc_data(9 downto 0) <= pc_inc;
	opcode  <= instruction(31 downto 26);
	-- address is (25 downto 21) when opcode is not JAL or JALR
	wb_addr <= instruction(25 downto 21) when opcode /= OP_JAL and
															opcode /= OP_JALR else
														--else hard set to R31
															"11111";
	mux_sel <= '1' when opcode = "000001" else '0';
	wb_en	  <= '0' when (opcode = OP_NOP or opcode = OP_SW or
								opcode = OP_BEQZ or opcode = OP_BNEZ or
								opcode = OP_J	 or opcode = OP_JR or
								opcode = OP_PCH or opcode = OP_PD or
								opcode = OP_PDU or
								opcode = OP_TR or opcode = OP_TGO or
								opcode = OP_TSP)
					else '1';
	
	--when opcode is not JALR or JAL use rs2 data or alu data
	wb_data <= mux_out when opcode /= OP_JALR and
									opcode /= OP_JAL 
								--else use the program counter as data
									else pc_data;
	
	MUXXY		:	entity work.MUX
		generic map(
			N => 32
		)
		port map(
			A=> RAM_output,
			B=> reg_ALU,
			S=> mux_sel,
			OUTPUT=> mux_out
		);

end architecture structural;