library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity tb_hazard_factorial is
end entity tb_hazard_factorial;

architecture behavioral of tb_hazard_factorial is

    -- Clock
    signal clk : std_logic := '0';
    constant CLK_PERIOD : time := 10 ns;
    
    signal tb_rst : std_logic := '1';
    signal tb_ARDUINO_IO    :   std_logic_vector(15 downto 0);

begin

    -- Instantiate the DLX Processor (all 5 stages + hazard logic)
    uut : entity work.Lab8_DLX_Print
        port map (
            ADC_CLK_10 => clk,
            MAX10_CLK1_50 => clk,
            MAX10_CLK2_50 => clk,

            ARDUINO_IO => tb_ARDUINO_IO,
            ARDUINO_RESET_N => tb_rst  
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
    -- FACTORIAL PROGRAM (NO NOPs) — factorial_code.mif
    --
    -- 000: 04A00001  LW   R5, n(R0)           — load n (=6)
    -- 001: 10800001  ADDI R4, R0, 1           — R4 = 1
    -- 002: 081F0000  SW   R4, f(R0)           — f = 1
    -- 003: 10E5FFFF  ADDI R7, R5, -1          — R7 = n-1
    -- 004: ACE00010  BEQZ R7, done(010)       — if n==1 → done
    -- 005: BC000008  JAL  factorial(008)       — call factorial
    -- 006: 20A50001  SUBI R5, R5, 1           — n--
    -- 007: B4000003  J    loop(003)            — repeat
    --
    -- 008: 04C00000  LW   R6, f(R0)           — R6 = f
    -- 009: 0D002800  ADD  R8, R0, R5           — R8 = n (counter)
    -- 00A: 10600000  ADDI R3, R0, 0           — R3 = 0 (accumulator)
    -- 00B: 0C633000  ADD  R3, R3, R6           — R3 += f
    -- 00C: 21080001  SUBI R8, R8, 1           — R8--
    -- 00D: B100000B  BNEZ R8, multiply_loop(00B)
    -- 00E: 081F0000  SW   R3, f(R0)           — f = R3
    -- 00F: B800001F  JR   R31                 — return
    -- 010: B4000010  J    done(010)            — infinite loop (halt)
    --
    -- DATA MEMORY (factorial_data_passOff.mif):
    --   addr 000: f = 0 (result)
    --   addr 001: n = 6 (input)
    --
    -- EXPECTED RESULT:
    --   After completion, data memory addr 000 should contain
    --   720 (0x000002D0), which is 6!
    --
    -- The program has NO NOPs. All data and control hazards are
    -- handled by the forwarding unit, hazard detection unit,
    -- pipeline stalls, and branch flushing implemented in Lab 7.
    --
    -- HAZARDS PRESENT (non-exhaustive):
    --  Data (RAW, forwarding resolves):
    --    001→002: R4 written then immediately used in SW
    --    003→004: R7 written then immediately tested in BEQZ
    --    009→00B: R8 used as loop counter
    --    00B→00C: R3 accumulator write→read
    --    00C→00D: R8 decrement→branch test
    --
    --  Load-use (stall + forward):
    --    000→001: LW R5 then ADDI uses R5 (actually no, ADDI uses R0)
    --    000→003: LW R5 then ADDI R7,R5,-1 (forwarded from MEM/WB)
    --    008→009: LW R6 then ADD R8,R0,R5 (R6 not used until 00B, ok)
    --    008→00B: LW R6 used in ADD R3,R3,R6 (depends on timing)
    --
    --  Control (flush):
    --    004: BEQZ — flush 2 instructions behind if taken
    --    005: JAL  — always flush 2 behind
    --    007: J    — always flush 2 behind
    --    00D: BNEZ — flush 2 behind if taken
    --    00F: JR   — always flush 2 behind
    --    010: J    — always flush 2 behind (halt loop)
    -- ================================================================

    stm_process : process
    begin
        -- ===========================================
        -- RESET
        -- ===========================================
        tb_rst <= '1';
        wait for CLK_PERIOD * 3;
        tb_rst <= '0';

        -- ===========================================
        -- RUN
        -- The processor is now fully autonomous.
        -- No testbench-driven writeback needed —
        -- the write-back stage handles everything.
        --
        -- Factorial(6) computation estimate:
        --   5 outer loop iterations ×
        --   (function call overhead + multiply inner loop)
        --   + stalls + branch flush penalties
        --   ≈ 400-600 cycles
        --
        -- We run 1500 cycles to be safe.
        -- ===========================================
        wait for CLK_PERIOD * 1500;

        -- ===========================================
        -- VERIFICATION
        -- At this point the processor should be stuck
        -- in the "J done" infinite loop at address 010.
        --
        -- Check in the waveform viewer:
        --   1. Memory write to address 000 with value
        --      0x000002D0 (720) — this is the final
        --      SW R3, f(R0) that stores the factorial result
        --   2. The PC should be cycling at address 010
        --      (the halt loop)
        --
        -- To verify in wave.do, inspect:
        --   - uut/memory_inst/DATA_MEM address & data & wren
        --   - uut/fetch_inst/PC_counter/data_out (should show 010)
        --   - uut/decode_inst/reg_file/registers (R3 should = 720)
        -- ===========================================

        -- Let it run a bit more for waveform capture
        wait for CLK_PERIOD * 100;

        assert false report "Simulation complete - check waveform for factorial(6) = 720 at data memory address 0" severity note;
        wait;
    end process;

end architecture behavioral;
