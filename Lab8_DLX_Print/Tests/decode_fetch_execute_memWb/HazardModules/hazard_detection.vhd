library ieee;
use ieee.std_logic_1164.all;

library work;
use work.decode_reg_pkg.all;

-- Hazard Detection Unit
--
-- Detects two types of pipeline hazards:
--
-- 1. LOAD-USE HAZARD (stall):
--    A LW in Execute (ID/EX) writes to a register that the instruction
--    in Decode (IF/ID) needs to read. Even forwarding can't help because
--    the load data won't be available until after the Memory stage.
--    Solution: stall for 1 cycle, then forward from MEM/WB.
--
-- 2. CONTROL HAZARD (flush):
--    A branch/jump is taken. The 2 instructions that entered the pipeline
--    behind the branch are wrong and must be squashed (replaced with NOPs).
--
-- When stall = '1':
--    - Fetch freezes (PC and IF/ID registers don't update)
--    - Decode outputs NOP to Execute (bubble inserted)
--    - The LW proceeds through Execute → Memory normally
--
-- When flush = '1':
--    - Decode outputs NOP to Execute (squash wrong instruction)
--    - Execute output registers latch NOP (squash wrong instruction)
--    - Fetch PC is already redirected by branch_en/jump_addr
--
-- Flush takes priority over stall.

entity hazard_detection is
    port (
        -- Instruction entering Execute (from decode's registered output, ID/EX)
        id_ex_instruction : in  std_logic_vector(31 downto 0);

        -- Instruction entering Decode (from fetch output, IF/ID)
        if_id_instruction : in  std_logic_vector(31 downto 0);

        -- Branch/jump taken signal from Execute stage output register
        branch_en         : in  std_logic;

        -- Stall: freeze Fetch, inject NOP bubble into Execute
        stall             : out std_logic;

        -- Flush: inject NOP at Decode output and Execute output
        flush             : out std_logic
    );
end entity hazard_detection;

architecture behavioral of hazard_detection is

    -- ID/EX (Execute) instruction fields
    signal id_ex_opcode : std_logic_vector(5 downto 0);
    signal id_ex_rd     : std_logic_vector(4 downto 0);

    -- IF/ID (Decode) instruction fields
    signal if_id_opcode : std_logic_vector(5 downto 0);
    signal if_id_rs1    : std_logic_vector(4 downto 0);
    signal if_id_rs2    : std_logic_vector(4 downto 0);

    -- Does the IF/ID instruction actually read these source registers?
    signal uses_rs1     : std_logic;
    signal uses_rs2     : std_logic;

    -- Internal hazard flag
    signal load_use     : std_logic;

begin

    ---------------------------------------------------------------------------
    -- Field extraction
    ---------------------------------------------------------------------------
    id_ex_opcode <= id_ex_instruction(31 downto 26);
    id_ex_rd     <= id_ex_instruction(25 downto 21);

    if_id_opcode <= if_id_instruction(31 downto 26);

    -- IF/ID rs1 address (same extraction logic as decode.vhd)
    --   BEQZ/BNEZ: register to test is at bits [25:21]
    --   All others: rs1 is at bits [20:16]
    if_id_rs1 <= if_id_instruction(25 downto 21)
                    when (if_id_opcode = OP_BEQZ or if_id_opcode = OP_BNEZ)
                 else if_id_instruction(20 downto 16);

    -- IF/ID rs2 address (same extraction logic as decode.vhd)
    --   SW/JR/JALR: second source register is at bits [25:21]
    --   R-type:     rs2 is at bits [15:11]
    if_id_rs2 <= if_id_instruction(25 downto 21)
                    when (if_id_opcode = OP_SW or
                          if_id_opcode = OP_JR or
                          if_id_opcode = OP_JALR)
                 else if_id_instruction(15 downto 11);

    ---------------------------------------------------------------------------
    -- Determine which source registers are actually used by IF/ID instruction
    ---------------------------------------------------------------------------

    -- rs1 is used by everything EXCEPT: NOP, J, JAL, JR, JALR
    uses_rs1 <= '0' when (if_id_opcode = OP_NOP  or
                          if_id_opcode = OP_J    or
                          if_id_opcode = OP_JAL  or
                          if_id_opcode = OP_JR   or
                          if_id_opcode = OP_JALR)
                else '1';

    -- rs2 is used only by: R-type ALU ops, SW, JR, JALR
    uses_rs2 <= '1' when (if_id_opcode = OP_ADD  or if_id_opcode = OP_ADDU or
                          if_id_opcode = OP_SUB  or if_id_opcode = OP_SUBU or
                          if_id_opcode = OP_AND  or if_id_opcode = OP_OR   or
                          if_id_opcode = OP_XOR  or
                          if_id_opcode = OP_SLL  or if_id_opcode = OP_SRL  or
                          if_id_opcode = OP_SRA  or
                          if_id_opcode = OP_SLT  or if_id_opcode = OP_SLTU or
                          if_id_opcode = OP_SGT  or if_id_opcode = OP_SGTU or
                          if_id_opcode = OP_SLE  or if_id_opcode = OP_SLEU or
                          if_id_opcode = OP_SGE  or if_id_opcode = OP_SGEU or
                          if_id_opcode = OP_SEQ  or if_id_opcode = OP_SNE  or
                          if_id_opcode = OP_SW   or
                          if_id_opcode = OP_JR   or if_id_opcode = OP_JALR)
                else '0';

    ---------------------------------------------------------------------------
    -- Load-use hazard detection
    ---------------------------------------------------------------------------
    -- Stall required when:
    --   1. Instruction in Execute is LW
    --   2. LW destination is not R0
    --   3. IF/ID instruction reads from the LW destination
    load_use <= '1' when (id_ex_opcode = OP_LW and
                          id_ex_rd /= "00000" and
                          ((uses_rs1 = '1' and if_id_rs1 = id_ex_rd) or
                           (uses_rs2 = '1' and if_id_rs2 = id_ex_rd)))
                else '0';

    ---------------------------------------------------------------------------
    -- Output signals
    ---------------------------------------------------------------------------
    -- Flush overrides stall (branch squashes everything)
    stall <= load_use and not branch_en;
    flush <= branch_en;

end architecture behavioral;
