library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fetch_decode_execute is
end entity tb_fetch_decode_execute;

architecture behavioral of tb_fetch_decode_execute is
    
    component DLX_Processor 
        generic (
            WIDTH       : integer := 10;
            INSTR_WIDTH : integer := 32
        );
        port (
            clk              : in  std_logic;
            rst              : in  std_logic;
            write_addr_in    : in  std_logic_vector(4 downto 0);
            write_data_in    : in  std_logic_vector(31 downto 0);
            write_en_in      : in  std_logic;
            branch_en_out    : out std_logic;
            alu_result_out   : out std_logic_vector(INSTR_WIDTH-1 downto 0);
            rs2_data_out     : out std_logic_vector(INSTR_WIDTH-1 downto 0);
            exec_instr_out   : out std_logic_vector(INSTR_WIDTH-1 downto 0);
            exec_rd_addr_out : out std_logic_vector(4 downto 0)
        );
    end component DLX_Processor;
    
    -- Clock
    signal clk : std_logic := '0';
    constant CLK_PERIOD : time := 10 ns;

    -- Inputs
    signal tb_rst       : std_logic := '1';
    signal tb_wb_addr   : std_logic_vector(4 downto 0)  := (others => '0');
    signal tb_wb_data   : std_logic_vector(31 downto 0) := (others => '0');
    signal tb_wb_en     : std_logic := '0';
    
    -- Execute stage outputs
    signal tb_branch_en    : std_logic;
    signal tb_alu_result   : std_logic_vector(31 downto 0);
    signal tb_rs2_data     : std_logic_vector(31 downto 0);
    signal tb_exec_instr   : std_logic_vector(31 downto 0);
    signal tb_exec_rd_addr : std_logic_vector(4 downto 0);

begin
    
    -- Instantiate the DLX Processor (Fetch + Decode + Execute)
    uut : DLX_Processor
        generic map (
            WIDTH       => 10,
            INSTR_WIDTH => 32
        )
        port map (
            clk              => clk,
            rst              => tb_rst,
            write_addr_in    => tb_wb_addr,
            write_data_in    => tb_wb_data,
            write_en_in      => tb_wb_en,
            branch_en_out    => tb_branch_en,
            alu_result_out   => tb_alu_result,
            rs2_data_out     => tb_rs2_data,
            exec_instr_out   => tb_exec_instr,
            exec_rd_addr_out => tb_exec_rd_addr
        );
        
    -- Clock process
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- ================================================================
    -- FACTORIAL PROGRAM IN ROM (factorial_NOops.mif):
    -- NOP-padded to avoid data hazards (2 NOPs after every
    -- register-writing instruction and every branch/jump).
    --
    -- 000: 04A00001  LW   R5, n(R0)              [writes R5]
    -- 001: 00000000  NOP
    -- 002: 00000000  NOP
    -- 003: 10800001  ADDI R4, R0, 1               [writes R4]
    -- 004: 00000000  NOP
    -- 005: 00000000  NOP
    -- 006: 081F0000  SW   R4, f(R0)
    -- 007: 10E5FFFF  ADDI R7, R5, -1              [writes R7]
    -- 008: 00000000  NOP
    -- 009: 00000000  NOP
    -- 00A: ACE00000  BEQZ R7, done(02C)           [branch]
    -- 00B: 00000000  NOP  (delay slot)
    -- 00C: 00000000  NOP  (delay slot)
    -- 00D: BC000000  JAL  factorial(016)           [jump, writes R31]
    -- 00E: 00000000  NOP  (delay slot)
    -- 00F: 00000000  NOP  (delay slot)
    -- 010: 20A50001  SUBI R5, R5, 1               [writes R5]
    -- 011: 00000000  NOP
    -- 012: 00000000  NOP
    -- 013: B4000000  J    loop(007)                [jump]
    -- 014: 00000000  NOP  (delay slot)
    -- 015: 00000000  NOP  (delay slot)
    -- 016: 04C00000  LW   R6, f(R0)               [writes R6]
    -- 017: 00000000  NOP
    -- 018: 00000000  NOP
    -- 019: 0D002800  ADD  R8, R0, R5              [writes R8]
    -- 01A: 00000000  NOP
    -- 01B: 00000000  NOP
    -- 01C: 10600000  ADDI R3, R0, 0               [writes R3]
    -- 01D: 00000000  NOP
    -- 01E: 00000000  NOP
    -- 01F: 0C633000  ADD  R3, R3, R6              [writes R3]
    -- 020: 00000000  NOP
    -- 021: 00000000  NOP
    -- 022: 21080001  SUBI R8, R8, 1               [writes R8]
    -- 023: 00000000  NOP
    -- 024: 00000000  NOP
    -- 025: B1000000  BNEZ R8, multiply_loop(01F)  [branch]
    -- 026: 00000000  NOP  (delay slot)
    -- 027: 00000000  NOP  (delay slot)
    -- 028: 081F0000  SW   R3, f(R0)
    -- 029: B800001F  JR   R31                     [jump]
    -- 02A: 00000000  NOP  (delay slot)
    -- 02B: 00000000  NOP  (delay slot)
    -- 02C: B4000000  J    done(02C)               [jump]
    -- 02D: 00000000  NOP  (delay slot)
    -- 02E: 00000000  NOP  (delay slot)
    --
    -- NOTES:
    -- 1. Branches/jumps are SELF-DRIVEN by execute. No testbench
    --    control of PC needed. Only writeback is TB-driven.
    --
    -- 2. Jump target addresses in the MIF are encoded as 0, so all
    --    branches/jumps redirect PC to 000 (program restart).
    --
    -- 3. Without a memory or writeback stage, register values only
    --    change when the TB writes them. The NOPs prevent timing
    --    misalignment in the pipeline, but the actual register
    --    contents depend entirely on TB writeback signals.
    --
    -- 4. Pipeline timing (3-stage, approx):
    --    Instruction at addr N appears at exec_instr_out ~N+2 cycles
    --    after pipeline start. Branch_en effect reaches fetch 1 cycle
    --    after it appears at execute output.
    --
    -- 5. Expected linear flow (R7 nonzero, BEQZ not taken):
    --    000-006: setup (LW, NOPs, ADDI, NOPs, SW)
    --    007-009: ADDI R7, NOPs
    --    00A-00C: BEQZ (not taken), NOPs
    --    00D:     JAL → branch_en='1' → PC redirects to 000
    --    00E-00F: NOPs (garbage in pipeline, harmless)
    --    Then repeats from 000.
    -- ================================================================

    stm_process : process
    begin
        -- =====================================================
        -- PHASE 1: RESET
        -- =====================================================
        tb_rst <= '1';
        tb_wb_en <= '0';
        tb_wb_addr <= (others => '0');
        tb_wb_data <= (others => '0');
        wait for CLK_PERIOD * 2;
        tb_rst <= '0';

        -- =====================================================
        -- PHASE 2: PRE-POPULATE REGISTERS
        -- Write register values immediately after reset.
        -- Pipeline is starting but the first instructions that
        -- read these registers don't reach decode for several
        -- cycles (NOPs give us plenty of margin).
        --
        -- Without a writeback stage, the ALU computes results
        -- but can't write them to registers. The TB must provide
        -- all register values that instructions depend on.
        -- =====================================================

        -- R5 = 5 (n, the factorial input)
        -- Used by: ADDI R7,R5,-1 at addr 007
        tb_wb_en <= '1';
        tb_wb_addr <= "00101";
        tb_wb_data <= x"00000005";
        wait for CLK_PERIOD;

        -- R4 = 1 (initial f value)
        -- Used by: SW R4,f(R0) at addr 006
        tb_wb_addr <= "00100";
        tb_wb_data <= x"00000001";
        wait for CLK_PERIOD;

        -- R7 = 4 (n-1, nonzero so BEQZ at 00A is NOT taken)
        -- Used by: BEQZ R7 at addr 00A
        tb_wb_addr <= "00111";
        tb_wb_data <= x"00000004";
        wait for CLK_PERIOD;

        -- R31 = 16 (return address, simulates JAL writeback)
        -- Used by: JR R31 at addr 029 (unreachable in first pass)
        tb_wb_addr <= "11111";
        tb_wb_data <= x"00000010";
        wait for CLK_PERIOD;

        -- R6 = 1 (f loaded from memory)
        -- Used by: ADD R3,R3,R6 at addr 01F (unreachable in first pass)
        tb_wb_addr <= "00110";
        tb_wb_data <= x"00000001";
        wait for CLK_PERIOD;

        -- R8 = 5 (multiply loop counter = n)
        -- Used by: SUBI R8,R8,1 at addr 022 (unreachable in first pass)
        tb_wb_addr <= "01000";
        tb_wb_data <= x"00000005";
        wait for CLK_PERIOD;

        -- R3 = 0 (accumulator)
        -- Used by: ADD R3,R3,R6 at addr 01F (unreachable in first pass)
        tb_wb_addr <= "00011";
        tb_wb_data <= x"00000000";
        wait for CLK_PERIOD;

        tb_wb_en <= '0';

        -- =====================================================
        -- PHASE 3: FIRST PASS (addresses 000 through 00D)
        -- The pipeline runs linearly from 000. With R7=4 (nonzero),
        -- BEQZ at 00A is NOT taken. JAL at 00D fires branch_en='1'
        -- with target=0, looping back to 000.
        --
        -- In waveform, verify:
        --  - exec_instr_out shows LW, NOP, NOP, ADDI, NOP, NOP, SW,
        --    ADDI, NOP, NOP, BEQZ, NOP, NOP, JAL in sequence
        --  - alu_result_out for ADDI R4,R0,1 (addr 003) = 0x00000001
        --  - alu_result_out for ADDI R7,R5,-1 (addr 007) = 0x00000004
        --  - branch_en_out stays '0' for BEQZ (R7 nonzero)
        --  - branch_en_out goes '1' for JAL at addr 00D
        --  - After JAL, PC redirects to 000 (2 NOPs flush harmlessly)
        --
        -- 14 instructions (000-00D) + 2 pipeline fill + 2 delay slots
        -- = ~18 cycles minimum. Use 20 for margin.
        -- =====================================================
        wait for CLK_PERIOD * 20;

        -- =====================================================
        -- PHASE 4: SECOND PASS (pipeline has restarted at 000)
        -- Update registers to simulate progress from first pass.
        -- The processor loops back through the same instructions.
        -- =====================================================

        -- R5 = 4 (decremented n, simulating SUBI R5,R5,1)
        tb_wb_en <= '1';
        tb_wb_addr <= "00101";
        tb_wb_data <= x"00000004";
        wait for CLK_PERIOD;

        -- R7 = 3 (new n-1 = 4-1)
        tb_wb_addr <= "00111";
        tb_wb_data <= x"00000003";
        wait for CLK_PERIOD;

        -- R3 = 5 (accumulator after first multiply: 1 * 5 = 5)
        tb_wb_addr <= "00011";
        tb_wb_data <= x"00000005";
        wait for CLK_PERIOD;

        -- R6 = 5 (f updated)
        tb_wb_addr <= "00110";
        tb_wb_data <= x"00000005";
        wait for CLK_PERIOD;

        -- R8 = 4 (new loop counter)
        tb_wb_addr <= "01000";
        tb_wb_data <= x"00000004";
        wait for CLK_PERIOD;

        tb_wb_en <= '0';

        -- Let second pass run (same flow: 000→00D→loop to 000)
        wait for CLK_PERIOD * 20;

        -- =====================================================
        -- PHASE 5: BEQZ TAKEN PATH
        -- Set R7=0 so BEQZ at 00A fires.
        -- This tests that the branch checker correctly evaluates
        -- BEQZ when rs1=0 and produces branch_en='1'.
        -- Target is still 0, so PC goes to 000 either way,
        -- but branch_en will go HIGH at the BEQZ instruction
        -- instead of waiting for JAL at 00D.
        --
        -- Verify in waveform:
        --  - branch_en_out goes '1' when BEQZ (opcode 0x2B)
        --    appears at exec_instr_out
        -- =====================================================

        tb_wb_en <= '1';
        tb_wb_addr <= "00111"; -- R7
        tb_wb_data <= x"00000000"; -- R7 = 0 → BEQZ taken
        wait for CLK_PERIOD;

        tb_wb_en <= '0';

        -- Let pipeline run: 000→00A(BEQZ taken)→000
        -- BEQZ at 00A, faster loop: ~12 instructions + pipeline
        wait for CLK_PERIOD * 20;

        -- =====================================================
        -- PHASE 6: FINAL OBSERVATION
        -- Pipeline continues looping. All branches/jumps go to 0.
        -- Let it run a few more cycles for waveform capture.
        -- =====================================================
        wait for CLK_PERIOD * 10;

        wait;
    end process;
    
end architecture behavioral;