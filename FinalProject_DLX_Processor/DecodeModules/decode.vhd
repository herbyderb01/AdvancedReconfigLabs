-- =============================================================================
-- decode.vhd  --  Decode (ID) stage
-- =============================================================================
-- Reads the source registers from the register file, sign-extends the I-type
-- immediate, and registers the IF/ID pipeline outputs (instruction, sign-
-- extended immediate, PC+1) so the Execute stage can use them.
--
-- Source-register address extraction (mirrors DLX_Processor and
-- hazard_detection so they all agree on what the live source registers are):
--   rs1_addr = instruction[25:21]   for BEQZ, BNEZ, PCH, PD, PDU
--            = instruction[20:16]   otherwise
--   rs2_addr = instruction[25:21]   for SW, JR, JALR
--            = instruction[15:11]   otherwise
--   rd_addr  = instruction[15:11]   (R-type only, unused for other formats)
--
-- Stall behavior:
--   * For a regular load-use stall (stall='1', scan_stall='0'): the output
--     instruction register is reset to all-zeros, inserting a NOP bubble
--     into Execute. PC is held by fetch. Decode's other registers (sign_ext,
--     pc_inc) are also reset.
--   * For a scan stall (stall='1' AND scan_stall='1'): the output instruction
--     register HOLDS its current value (so the GD/GDU stays in decode and
--     re-issues every cycle until scan_ready arrives). instr_next is fed
--     back from the register's own output to keep the value alive.
-- =============================================================================

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
        
        -- Hazard control
        stall           : in  std_logic;
        flush           : in  std_logic;
        scan_stall      : in  std_logic;
        
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
	 
	 -- Bubble: insert NOP into pipeline on stall or flush
	 signal bubble : std_logic;
	 signal decode_rst : std_logic;
     signal instr_next : std_logic_vector(31 downto 0);
     signal pc_next    : std_logic_vector(9 downto 0);
     signal imm_next   : std_logic_vector(31 downto 0);
     signal reg_instr_out : std_logic_vector(31 downto 0);
     signal reg_sign_ext :  std_logic_vector(31 downto 0);
     signal reg_pc_out :  std_logic_vector(9 downto 0);

begin
    opcode <= instruction_in(31 downto 26);
	 
	 -- When flush or load-use stall, output registers are cleared (NOP bubble).
	 -- During scan_stall, output registers HOLD their value (GDU stays in Decode).
	 bubble <= flush or (stall and not scan_stall);
	 decode_rst <= rst or bubble;
	 
	 --look at (20 downto 16) for all other opcodes execpt BEQZ BNEZ
    rs1_addr <= instruction_in(25 downto 21)
                        when (opcode = OP_BEQZ or opcode = OP_BNEZ or
                              opcode = OP_PCH or opcode = OP_PD or opcode = OP_PDU)
                      else instruction_in(20 downto 16);
    -- rs1_addr <= instruction_in(20 downto 16) when opcode /= OP_BEQZ and
	-- 															  opcode /= OP_BNEZ 
	-- 															  --for Branch instructions look here
	-- 															  --for address from register
	-- 															  else instruction_in(25 downto 21);
	 --look at (15 downto 11) for all other opcodes except SW, JR, JALR
    rs2_addr <= instruction_in(25 downto 21) when opcode = OP_SW or opcode = OP_JR or opcode = OP_JALR
                                             else instruction_in(15 downto 11);
    -- rs2_addr <= instruction_in(15 downto 11) when opcode /= OP_SW and
	-- 															  opcode /= OP_JR and
	-- 															  opcode /= OP_JALR
	-- 															  --for SW, JR, JALR look here 
	-- 															  --for address from register
	-- 															  else instruction_in(25 downto 21); -- Also acts as RD for I-Type
    rd_addr_r <= instruction_in(15 downto 11);
    imm16 <= instruction_in(15 downto 0);
	 
    instr_next <= instruction_in  when stall = '0'
              else reg_instr_out when scan_stall = '1'  -- hold GDU during scan stall
              else (others => '0');                       -- NOP bubble for other stalls

    instruction_out <= reg_instr_out;

	 instr_reg	:	entity work.reggi_async
		generic map(
			N => 32
		)
		port map(
			data_in => instr_next,
			rst	  => decode_rst,
			clk 	  => clk,
			data_out=> reg_instr_out
		);

    -- Sign Extender
    sign_extER: sign_extend port map (
        input_data  => imm16,
        output_data => sign_ext
    );
	
    sign_ext_imm <= reg_sign_ext;
    imm_next <= sign_ext when stall='0'
            else reg_sign_ext;
    
	 Sign_reg	:	entity work.reggi
		generic map(
			N => 32
		)
		port map(
			data_in => imm_next,
			rst	  => decode_rst,
			clk	  => clk,
			data_out=> reg_sign_ext
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
    
    pc_inc_out <= reg_pc_out;
    pc_next <= pc_inc when stall='0'
           else reg_pc_out;    
    -- Pass PC
    PC_register	:	entity work.reggi
		generic map(
			N => 10
		)
		port map(
			data_in => pc_next,
			rst 	  => decode_rst,
			clk	  => clk,
			data_out=> reg_pc_out
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