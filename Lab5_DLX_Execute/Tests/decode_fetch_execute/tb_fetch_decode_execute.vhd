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
    -- FACTORIAL PROGRAM IN ROM (factorial_code_passOff.mif):
    --
    -- 000: 04A00001  LW   R5, n(R0)          opcode=01
    -- 001: 10800001  ADDI R4, R0, 1           opcode=04
    -- 002: 081F0000  SW   R4, f(R0)           opcode=02
    -- 003: 10E5FFFF  ADDI R7, R5, -1          opcode=04
    -- 004: ACE00000  BEQZ R7, done(010)       opcode=2B
    -- 005: BC000000  JAL  factorial(008)       opcode=2F
    -- 006: 20A50001  SUBI R5, R5, 1           opcode=08
    -- 007: B4000000  J    loop(004)            opcode=2D
    -- 008: 04C00000  LW   R6, f(R0)           opcode=01
    -- 009: 0D002800  ADD  R8, R0, R5           opcode=03
    -- 00A: 10600000  ADDI R3, R0, 0           opcode=04
    -- 00B: 0C633000  ADD  R3, R3, R6           opcode=03
    -- 00C: 21080001  SUBI R8, R8, 1           opcode=08
    -- 00D: B1000000  BNEZ R8, multiply(00B)   opcode=2C
    -- 00E: 081F0000  SW   R3, f(R0)           opcode=02
    -- 00F: B800001F  JR   R31                 opcode=2E
    -- 010: B4000000  J    done(010)            opcode=2D
    --
    -- NOTES:
    -- 1. Branches and jumps are now SELF-DRIVEN by the execute stage.
    --    Only writeback signals are testbench-driven (no memory/WB stages yet).
    --
    -- 2. The branch/jump target addresses in the MIF are encoded as 0
    --    in the immediate field. This means ALL branches/jumps will
    --    redirect PC to address 0, creating a restart loop.
    --    This is expected with the current assembler output.
    --
    -- 3. Per the professor: "your simulation probably isn't going to
    --    execute the program the way you want it to. And that's okay."
    --    Verify that the pipeline mechanics work:
    --    - Instructions flow through Fetch -> Decode -> Execute
    --    - ALU computes results (check alu_result_out)
    --    - branch_en_out goes HIGH for BEQZ/BNEZ/J/JR/JAL/JALR
    --    - After branch_en goes high, fetch redirects (2 garbage cycles)
    --
    -- 4. Pipeline timing (approximate):
    --    Cycle N:   Instruction fetched
    --    Cycle N+1: Instruction in decode (register file read)
    --    Cycle N+2: Execute output registers latch ALU result
    --    Cycle N+3: Branch_en takes effect at fetch
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
        -- Write key register values before instructions need
        -- them. This simulates what memory/writeback stages
        -- would do in a complete processor.
        -- =====================================================

        -- R5 = 5 (n, the factorial input)
        tb_wb_en <= '1';
        tb_wb_addr <= "00101";
        tb_wb_data <= x"00000005";
        wait for CLK_PERIOD;

        -- R4 = 1 (initial f value)
        tb_wb_addr <= "00100";
        tb_wb_data <= x"00000001";
        wait for CLK_PERIOD;

        -- R7 = 4 (n-1, for BEQZ check -- nonzero so branch NOT taken)
        tb_wb_addr <= "00111";
        tb_wb_data <= x"00000004";
        wait for CLK_PERIOD;

        -- R31 = 6 (return address for JAL -- simulates JAL writeback)
        tb_wb_addr <= "11111";
        tb_wb_data <= x"00000006";
        wait for CLK_PERIOD;

        -- R6 = 1 (f loaded from memory)
        tb_wb_addr <= "00110";
        tb_wb_data <= x"00000001";
        wait for CLK_PERIOD;

        -- R8 = 5 (multiply loop counter = n)
        tb_wb_addr <= "01000";
        tb_wb_data <= x"00000005";
        wait for CLK_PERIOD;

        -- R3 = 0 (accumulator)
        tb_wb_addr <= "00011";
        tb_wb_data <= x"00000000";
        wait for CLK_PERIOD;

        tb_wb_en <= '0';

        -- =====================================================
        -- PHASE 3: LET PIPELINE RUN (First pass through program)
        -- Pipeline is now running through instructions 000-010.
        -- Watch the waveform for:
        --   exec_instr_out: instruction currently at execute output
        --   alu_result_out: ALU computation result
        --   branch_en_out: goes HIGH when branch/jump fires
        --
        -- When a branch/jump instruction reaches execute and
        -- branch_en goes HIGH, the processor will redirect PC.
        -- The MIF encodes all jump targets as 0, so all jumps
        -- redirect to address 000 (program restart).
        --
        -- Expect ~2 garbage instructions in the pipeline after
        -- each branch/jump (instructions already fetched before
        -- the redirect takes effect).
        -- =====================================================
        wait for CLK_PERIOD * 15;

        -- =====================================================
        -- PHASE 4: ADDITIONAL WRITEBACK UPDATES
        -- As the processor loops (jumps back to addr 0), feed
        -- updated register values to simulate computation progress.
        -- =====================================================

        -- Simulate factorial progress: R5 decremented
        tb_wb_en <= '1';
        tb_wb_addr <= "00101"; -- R5
        tb_wb_data <= x"00000004"; -- n = 4 (decremented from 5)
        wait for CLK_PERIOD;

        -- R7 = 3 (new n-1)
        tb_wb_addr <= "00111";
        tb_wb_data <= x"00000003";
        wait for CLK_PERIOD;

        -- R3 = 5 (accumulator after first multiply: 1 * 5 = 5)
        tb_wb_addr <= "00011";
        tb_wb_data <= x"00000005";
        wait for CLK_PERIOD;

        -- R6 = 5 (f updated from R3)
        tb_wb_addr <= "00110";
        tb_wb_data <= x"00000005";
        wait for CLK_PERIOD;

        -- R8 = 4 (new loop counter)
        tb_wb_addr <= "01000";
        tb_wb_data <= x"00000004";
        wait for CLK_PERIOD;

        tb_wb_en <= '0';

        -- Let pipeline run through another iteration
        wait for CLK_PERIOD * 15;

        -- =====================================================
        -- PHASE 5: FORCE END CONDITION
        -- Set R7 = 0 so that when BEQZ R7 reaches execute,
        -- the branch WILL be taken (to "done").
        -- =====================================================

        tb_wb_en <= '1';
        tb_wb_addr <= "00111"; -- R7
        tb_wb_data <= x"00000000"; -- R7 = 0, BEQZ will fire
        wait for CLK_PERIOD;

        -- Also set R8 = 0 so BNEZ in multiply loop exits
        tb_wb_addr <= "01000"; -- R8
        tb_wb_data <= x"00000000";
        wait for CLK_PERIOD;

        tb_wb_en <= '0';

        -- =====================================================
        -- PHASE 6: FINAL OBSERVATION
        -- Let the pipeline process remaining instructions.
        -- The processor should keep looping since all jumps
        -- go to address 0 with the current MIF encoding.
        -- In the waveform, verify:
        --   1. exec_instr_out cycles through instructions
        --   2. alu_result_out shows non-zero computed values
        --   3. branch_en_out pulses HIGH for branch/jump instrs
        --   4. After branch_en goes HIGH, instructions restart
        --      from address 000 (with 2 garbage cycles)
        -- =====================================================
        wait for CLK_PERIOD * 20;

        wait;
    end process;
    
end architecture behavioral;