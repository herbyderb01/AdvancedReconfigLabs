library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.component_pkg.all;

entity execute is
	generic(
		DATA_WIDTH	:	integer	:=	32;
		PC_WIDTH		:	integer	:= 10
	);
	port (
		clk			:	in		std_logic;
		rst			:	in		std_logic;
		
		instruction	:	in		std_logic_vector(DATA_WIDTH-1 downto 0);
		pc_inc		:	in		std_logic_vector(PC_WIDTH-1 downto 0);
		
		rs1_data		:	in 	std_logic_vector(DATA_WIDTH-1 downto 0);
		rs2_data		:	in		std_logic_vector(DATA_WIDTH-1 downto 0);
		sign_ext_imm:	in		std_logic_vector(DATA_WIDTH-1 downto 0);
		rd_addr_in	:	in 	std_logic_vector(4 downto 0);
		
		Branch_en	:	out	std_logic;
		ALU_reg		:	out 	std_logic_vector(DATA_WIDTH-1 downto 0);
		rs2_data_out:	out	std_logic_vector(DATA_WIDTH-1 downto 0);
		instr_out	:	out	std_logic_vector(DATA_WIDTH-1 downto 0);
	);
end entity execute;

architecture structual of DLX_Processor is
	signal opcode	:	std_logic_vector(5 downto 0) := instruction(31 downto 26);
	signal ALU_out	:	std_logic_vector(DATA_WIDTH-1 downto 0);
	branch_reg		:	std_logic;
	q1					:	std_logic_vector(DATA_WIDTH-1 downto 0);
	q2					:	std_logic_vector(DATA_WIDTH-1 downto 0);
	ext_pc			:	std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

begin

	ext_pc(9 downto 0) <= pc_inc;
	opcode <= instruction(31 downto 26);
	
	MUXXY1	:	entity work.MUX
		generic map(
			N=>32
		)
		port map(
			A=>ext_pc,
			B=>rs1_data,
			S=>,
			OUTPUT=>q1
		);
		
	MUXXY2	:	entity work.MUX
		generic map(
			N=>32
		)
		port map(
			A=>rs2_data,
			B=>sign_ext_imm,
			S=>,
			OUTPUT=>q2
		);

	ALU_inst:	ALU
		generic map(
			DATA_WIDTH=>DATA_WIDTH,
			OP_CODE_WIDTH=> 6
		)
		port map(
			data_in1=>q1,
			data_in2=>rs2_data,
			op_sel=>opcode,
			data_out1=>ALU_out
		);
		
	ALU_reg	:	entity work.reggi
		generic map(
			N => DATA_WIDTH
		)
		port map(
			data_in=>ALU_out,
			rst=>rst,
			clk=>clk,
			data_out=>ALU_reg
		);
		
	branch_check_inst	:	branch_check
		generic map(
			ADDR_WIDTH=>10
		)
		port map(
			addr_in=>pc_inc,
			rs1=>rs1_data,
			opcode=>opcode,
			take_branch=>branch_reg
		);
		
	branch_check_reg	:	entity work.reggi
		generic map(
			DATA_WIDTH=>1
		)
		port map(
			data_in=>branch_reg,
			rst=>rst,
			clk=>clk,
			data_out=>Branch_en
		);
	
	rs2_reg	:	entity work.reggi
		generic map(
			DATA_WIDTH=>DATA_WIDTH
		)
		port map(
			data_in=>rs2_data,
			rst=>rst,
			clk=>clk,
			data_out=>rs2_data_out
		);
		
	instr_reg	:	entity work.reggi
		generic map(
			DATA_WIDTH=>DATA_WIDTH
		)
		port map(
			data_in=>instruction,
			rst=>rst,
			clk=>clk,
			data_out=>instr_out
		);
		
end architecture structual;