library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.decode_reg_pkg.all;
use work.sign_extend_pkg.all;

entity decode is
    generic (
        FUNC_WIDTH : integer := 6;
        ADDR_WIDTH : integer := 5;
        DATA_WIDTH : integer := 32
    );
    port (
        clk             : in  std_logic;
        rst             : in  std_logic;
        
        -- From Fetch
        instruction_in  : in  std_logic_vector(31 downto 0);
        pc_inc          : in  std_logic_vector(9 downto 0);
        
        -- From Writeback
        wb_data         : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        wb_addr         : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        wb_en           : in  std_logic;
        
        -- To Execute
		  instruction_out : out std_logic_vector(31 downto 0);
        rs1_data        : out std_logic_vector(DATA_WIDTH-1 downto 0);
        rs2_data        : out std_logic_vector(DATA_WIDTH-1 downto 0);
        sign_ext_imm    : out std_logic_vector(31 downto 0);
        rd_addr_out     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        pc_inc_out      : out std_logic_vector(9 downto 0)
    );
end entity decode;

architecture structural of decode is
    signal opcode : std_logic_vector(5 downto 0);
    signal rs1_addr, rs2_addr, rd_addr_r : std_logic_vector(4 downto 0);
    signal imm16 : std_logic_vector(15 downto 0);
	 signal sign_ext :	std_logic_vector(31 downto 0);
	 
    signal reg_dest_sel : std_logic_vector(1 downto 0); -- 00: I-Type(20-16), 01: R-Type(15-11), 10: 31
    -- 00 is also used for instructions that don't write back (Stores, Branches), since wb_en is 0 anyway.

begin
    opcode <= instruction_in(31 downto 26);
    rs1_addr <= instruction_in(25 downto 21);
    rs2_addr <= instruction_in(20 downto 16); -- Also acts as RD for I-Type
    rd_addr_r <= instruction_in(15 downto 11);
    imm16 <= instruction_in(15 downto 0);
	 
	 instr_reg	:	entity work.reggi
		generic map(
			N => 32
		)
		port map(
			data_in => instruction_in,
			rst	  => rst,
			clk 	  => clk,
			data_out=> instruction_out
		);

    -- Sign Extender
    sign_extER: sign_extend port map (
        input_data  => imm16,
        output_data => sign_ext
    );
	 
	 Sign_reg	:	entity work.reggi
		generic map(
			N => 32
		)
		port map(
			data_in => sign_ext,
			rst	  => rst,
			clk	  => clk,
			data_out=> sign_ext_imm
		);
	 

    -- Register File
    reg_file: decode_reg 
        generic map (DATA_WIDTH => 32, ADDR_WIDTH => 5)
        port map (
            clk => clk,
            rst => rst,
            reg_read_addr1 => rs1_addr,
            reg_read_addr2 => rs2_addr,
            reg_write_addr => wb_addr,
            reg_write_data => wb_data,
            reg_write_en   => wb_en,
            reg_read_data1 => rs1_data,
            reg_read_data2 => rs2_data
        );
        
    -- Pass PC
    PC_register	:	entity work.reggi
		generic map(
			N => 10
		)
		port map(
			data_in => pc_inc,
			rst 	  => rst,
			clk	  => clk,
			data_out=> pc_inc_out
		);

end architecture structural;


-- Control Logic for RegDst
    --process(opcode)
    --begin
        --case opcode is
            --when OP_NOP => 
                --reg_dest_sel <= "00";
            --when OP_JAL | OP_JALR =>
                 --reg_dest_sel <= "10"; -- Link R31
            -- R-Types
            --when OP_ADD   |
                 --OP_ADDU  |
                 --OP_SUB   |
                 --OP_SUBU  |
                 --OP_AND   |
                 --OP_OR    |
                 --OP_XOR   |
                 --OP_SLL   |
                 --OP_SRL   |
                 --OP_SRA   |
                 --OP_SLT   |
                 --OP_SLTU  |
                 --OP_SGT   |
                 --OP_SGTU  |
                 --OP_SLE   |
                 --OP_SLEU  |
                 --OP_SGE   |
                 --OP_SGEU  |
                 --OP_SEQ   |
                 --OP_SNE   =>
                --reg_dest_sel <= "01"; -- Rd (15-11)

            -- I-Types (default)
--            when others =>
          --      reg_dest_sel <= "00"; -- Rt (20-16)
        --end case;
    --end process;