library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.decode_reg_pkg.all;

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
		
		-- Hazard control
		flush			:	in		std_logic;

		-- Scan data (GD/GDU)
		scan_data		:	in		std_logic_vector(DATA_WIDTH-1 downto 0);

		-- Forwarding inputs
		fwd_a_sel		:	in		std_logic_vector(1 downto 0);
		fwd_b_sel		:	in		std_logic_vector(1 downto 0);
		ex_mem_alu_data:	in		std_logic_vector(DATA_WIDTH-1 downto 0);
		mem_wb_data		:	in		std_logic_vector(DATA_WIDTH-1 downto 0);
		
		--print outputs
		fifo_wr 	:	out std_logic;
		fifo_data	:	out std_logic_vector(DATA_WIDTH-1 downto 0);
		fifo_instr	:	out	std_logic_vector(DATA_WIDTH-1 downto 0);

		-- Timer control outputs
		timer_rst	:	out std_logic;
		timer_go	:	out std_logic;
		timer_stop	:	out std_logic;


		Branch_en	:	out	std_logic;
		ALU_result	:	out 	std_logic_vector(DATA_WIDTH-1 downto 0);
		rs2_data_out:	out	std_logic_vector(DATA_WIDTH-1 downto 0);
		instr_out	:	out	std_logic_vector(DATA_WIDTH-1 downto 0);
		rd_addr_out	:	out	std_logic_vector(4 downto 0);
		pc_out		:	out	std_logic_vector(PC_WIDTH-1 downto 0);
		jump_addr	:	out	std_logic_vector(PC_WIDTH-1 downto 0)
	);
end entity execute;

architecture structural of execute is
	signal opcode		:	std_logic_vector(5 downto 0);
	signal reg_opcode	:	std_logic_vector(5 downto 0);
	signal ALU_out		:	std_logic_vector(DATA_WIDTH-1 downto 0);
	signal branch_reg	:	std_logic_vector(0 downto 0);
	signal branch_out	:	std_logic_vector(0 downto 0);
	signal q1			:	std_logic_vector(DATA_WIDTH-1 downto 0);
	signal q2			:	std_logic_vector(DATA_WIDTH-1 downto 0);
	signal ext_pc		:	std_logic_vector(DATA_WIDTH-1 downto 0);
	signal reg_ALU		:	std_logic_vector(DATA_WIDTH-1 downto 0);
	signal reg_rs2		:	std_logic_vector(DATA_WIDTH-1 downto 0);
	signal reg_instr	:	std_logic_vector(DATA_WIDTH-1 downto 0);
	
	-- MUX control signals
	signal mux1_sel	:	std_logic; -- '1' = PC (for JAL/JALR), '0' = rs1
	signal mux2_sel	:	std_logic; -- '1' = immediate (I-type), '0' = rs2 (R-type)
	
	-- Forwarding signals
	signal fwd_rs1	:	std_logic_vector(DATA_WIDTH-1 downto 0);
	signal fwd_rs2	:	std_logic_vector(DATA_WIDTH-1 downto 0);
	signal flush_rst	:	std_logic;

	-- Scan data injection: override ALU output for GD/GDU
	signal alu_or_scan	:	std_logic_vector(DATA_WIDTH-1 downto 0);

begin

	--Logic for print statements
	fifo_wr <= '1' when opcode = OP_PCH or
						opcode = OP_PD	or
						opcode = OP_PDU
					else '0';
	fifo_data <= q1;
	fifo_instr <= instruction;

	-- Timer control: single-cycle pulses when instruction is in execute
	timer_rst  <= '1' when opcode = OP_TR  else '0';
	timer_go   <= '1' when opcode = OP_TGO else '0';
	timer_stop <= '1' when opcode = OP_TSP else '0';

	-- Scan data injection: for GD/GDU, use scan_data instead of ALU output
	alu_or_scan <= scan_data when (opcode = OP_GD or opcode = OP_GDU)
	               else ALU_out;

	--wrap up assignments
	ALU_result <= reg_ALU;
	rs2_data_out <= reg_rs2;
	instr_out <= reg_instr;
	
	-- Combined reset: flush output pipeline registers on branch/jump
	flush_rst <= rst or flush;
	
	-- Forwarding MUXes: select correct data source for ALU inputs
	-- "00" = no forward (register file), "01" = EX/MEM, "10" = MEM/WB
	fwd_rs1 <= ex_mem_alu_data when fwd_a_sel = "01" else
	           mem_wb_data     when fwd_a_sel = "10" else
	           rs1_data;
	
	fwd_rs2 <= ex_mem_alu_data when fwd_b_sel = "01" else
	           mem_wb_data     when fwd_b_sel = "10" else
	           rs2_data;
	
	-- Zero-extend PC to DATA_WIDTH
	ext_pc(PC_WIDTH-1 downto 0) <= pc_inc;
	ext_pc(DATA_WIDTH-1 downto PC_WIDTH) <= (others => '0');
	
	opcode <= instruction(31 downto 26);
	--allows opcode to be synced with jump address and branching
	reg_opcode <= reg_instr(31 downto 26);
	--jump address is reg_ALU(9 downto 0) when opcode isn't JALR or JR
	jump_addr <= reg_ALU(PC_WIDTH-1 downto 0) when reg_opcode /= OP_JALR AND
																  reg_opcode /= OP_JR
																-- else look at the botton of reg rs2
																else reg_rs2(PC_WIDTH-1 downto 0);
	
	-- MUX1 Control: Always select rs1_data. PC not needed in ALU for absolute addressing.
	-- PC is forwarded through pipeline separately for JAL/JALR writeback to R31 (future lab).
	-- For JR/JALR, rs1 contains the jump target, so it MUST pass through to the ALU.
	mux1_sel <= '0';
	
	-- MUX2 Control: Select immediate for I-type instructions, rs2 for R-type
	-- When S='1', MUX outputs A (sign_ext_imm). When S='0', MUX outputs B (rs2_data).
	-- I-type: LW, SW, all Immediate ALU ops, branches, JAL, JALR
	-- R-type: register-register ALU ops (ADD, SUB, AND, OR, XOR, shifts, compares)
	mux2_sel <= '0' when (opcode = OP_ADD  or opcode = OP_ADDU or
	                      opcode = OP_SUB  or opcode = OP_SUBU or
	                      opcode = OP_AND  or opcode = OP_OR   or
	                      opcode = OP_XOR  or
	                      opcode = OP_SLL  or opcode = OP_SRL  or opcode = OP_SRA  or
	                      opcode = OP_SLT  or opcode = OP_SLTU or
	                      opcode = OP_SGT  or opcode = OP_SGTU or
	                      opcode = OP_SLE  or opcode = OP_SLEU or
	                      opcode = OP_SGE  or opcode = OP_SGEU or
	                      opcode = OP_SEQ  or opcode = OP_SNE)
	            else '1';
	
	MUXXY1	:	entity work.MUX
		generic map(
			N=>32
		)
		port map(
			A=>ext_pc,
			B=>fwd_rs1,
			S=>mux1_sel,
			OUTPUT=>q1
		);
		
	MUXXY2	:	entity work.MUX
		generic map(
			N=>32
		)
		port map(
			A=>sign_ext_imm,
			B=>fwd_rs2,
			S=>mux2_sel,
			OUTPUT=>q2
		);

	ALU_inst	:	entity work.ALU
		generic map(
			DATA_WIDTH=>DATA_WIDTH,
			OP_CODE_WIDTH=> 6
		)
		port map(
			data_in1=>q1,
			data_in2=>q2,
			op_sel=>opcode,
			data_out1=>ALU_out
		);
		
	ALU_out_reg	:	entity work.reggi
		generic map(
			N => DATA_WIDTH
		)
		port map(
			data_in=>alu_or_scan,
			rst=>flush_rst,
			clk=>clk,
			data_out=>reg_ALU
		);

	PC_out_reg : entity work.reggi
		generic map(
			N => PC_WIDTH
		)
		port map(
			data_in=>pc_inc,
			rst=>flush_rst,
			clk=>clk,
			data_out=>pc_out
		);
		
	branch_check_inst	:	entity work.branch_check
		generic map(
			ADDR_WIDTH=>PC_WIDTH
		)
		port map(
			addr_in=>pc_inc,
			rs1=>fwd_rs1,
			opcode=>opcode,
			take_branch=>branch_reg(0)
		);
		
	branch_check_reg	:	entity work.reggi
		generic map(
			N=>1
		)
		port map(
			data_in=>branch_reg,
			rst=>flush_rst,
			clk=>clk,
			data_out=>branch_out
		);
	
	Branch_en <= branch_out(0);
	
	rs2_reg	:	entity work.reggi
		generic map(
			N=>DATA_WIDTH
		)
		port map(
			data_in=>fwd_rs2,
			rst=>flush_rst,
			clk=>clk,
			data_out=>reg_rs2
		);

	instr_reg	:	entity work.reggi
		generic map(
			N=>DATA_WIDTH
		)
		port map(
			data_in=>instruction,
			rst=>flush_rst,
			clk=>clk,
			data_out=>reg_instr
		);

	rd_addr_reg	:	entity work.reggi
		generic map(
			N=>5
		)
		port map(
			data_in=>rd_addr_in,
			rst=>flush_rst,
			clk=>clk,
			data_out=>rd_addr_out
		);
		
end architecture structural;