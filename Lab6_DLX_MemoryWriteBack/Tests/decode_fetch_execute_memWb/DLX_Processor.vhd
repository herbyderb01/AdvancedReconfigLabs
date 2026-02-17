library ieee;
use ieee.std_logic_1164.all;

library work;
use work.fetch_pkg.all;

entity DLX_Processor is
    generic (
        WIDTH       : integer := 10;
        INSTR_WIDTH : integer := 32
    );
    port (
        clk             : in  std_logic;
        rst             : in  std_logic;
    );
end entity DLX_Processor;

architecture structural of DLX_Processor is
    -- Fetch -> Decode signals
    signal internal_pc_inc	:	std_logic_vector(WIDTH-1 downto 0);
    signal internal_instr	:	std_logic_vector(INSTR_WIDTH-1 downto 0);
	 
    -- Decode -> Execute signals
    signal dec_instruction	:	std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal dec_rs1_data		:	std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal dec_rs2_data		:	std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal dec_imm32			:	std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal dec_rd_addr		:	std_logic_vector(4 downto 0);
    signal dec_pc_inc			:	std_logic_vector(WIDTH-1 downto 0);
	 
    -- Execute outputs / feedback
    signal exec_branch_en	:	std_logic;
    signal exec_alu_result	:	std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal exec_rs2_data		:	std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal exec_instr			:	std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal exec_rd_addr		:	std_logic_vector(4 downto 0);
	 
	 -- Jump address derived from ALU result (for branches/jumps)
	 signal jump_addr			:	std_logic_vector(WIDTH-1 downto 0);
	 
	 --memory signals
	 signal mem_RAM_output		:	std_logic_vector(INSTR_WIDTH-1 downto 0);
	 signal mem_reg_ALU			:	std_logic_vector(INSTR_WIDTH-1 downto 0);
	 signal mem_instr_out		:	std_logic_vector(INSTR_WIDTH-1 downto 0);
	 
	 --write back signals
	 signal wb_en					:	std_logic;
	 signal wb_data				:	std_logic_vector(INSTR_WIDTH-1 downto 0);
	 signal wb_addr				:	std_logic_vector(WIDTH downto 0);

begin

	 -- Jump address is the lower bits of the ALU result
	 jump_addr <= exec_alu_result(WIDTH-1 downto 0);

    -- Fetch Stage
    fetch_inst: fetch
        generic map (
            N => WIDTH,
            M => INSTR_WIDTH
        )
        port map (
            jump_addr   => jump_addr,
            pc_select   => exec_branch_en,
            rst         => rst,
            clk         => clk,
            decode_addr => internal_pc_inc,
            instruction => internal_instr
        );

    -- Decode Stage
    decode_inst: entity work.decode
        generic map (
            FUNC_WIDTH => 6, 
            ADDR_WIDTH => 5, 
            DATA_WIDTH => 32
        )
        port map (
            clk             => clk,
            rst             => rst,
            instruction_in  => internal_instr,
            pc_inc          => internal_pc_inc,
            wb_data         => wb_data,
            wb_addr         => wb_addr,
            wb_en           => wb_en,
            rs1_data        => dec_rs1_data,
            rs2_data        => dec_rs2_data,
            sign_ext_imm    => dec_imm32,
            rd_addr_out     => dec_rd_addr,
            pc_inc_out      => dec_pc_inc,
				instruction_out => dec_instruction
        );

    -- Execute Stage
    execute_inst: entity work.execute
        generic map (
            DATA_WIDTH => INSTR_WIDTH,
            PC_WIDTH   => WIDTH
        )
        port map (
            clk             => clk,
            rst             => rst,
            instruction     => dec_instruction,
            pc_inc          => dec_pc_inc,
            rs1_data        => dec_rs1_data,
            rs2_data        => dec_rs2_data,
            sign_ext_imm    => dec_imm32,
            rd_addr_in      => dec_rd_addr,
            Branch_en       => exec_branch_en,
            ALU_result      => exec_alu_result,
            rs2_data_out    => exec_rs2_data,
            instr_out       => exec_instr,
            rd_addr_out     => exec_rd_addr
        );
		  
	 -- Memory stage
	 memory_inst:	entity work.memory
		  generic map(
				DATA_WIDTH=> INSTR_WIDTH
		  )
		  port map(
				clk=>clk,
				rst=>rst,
				instruction=>exec_instr,
				ALU_result=>exec_alu_result,
				rs2_data=>exec_rs2_data,
				RAM_output=>mem_RAM_output,
				reg_ALU=>mem_reg_ALU,
				instr_out=>mem_instr_out
		  )
	 
	 write_back_inst:	entity work.write_back
	 	  generic map(
				DATA_WIDTH=> INSTR_WIDTH
		  )
		  port map(
				RAM_output=>mem_RAM_output,
				reg_ALU=>mem_reg_ALU,
				instruction=>mem_instr_out,
				wb_en=>wb_en,
				wb_data=>wb_data,
				wb_addr=>wb_addr 
		  )

end architecture structural;
