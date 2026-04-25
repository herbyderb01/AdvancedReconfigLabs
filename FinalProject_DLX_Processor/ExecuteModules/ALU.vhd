-- =============================================================================
-- ALU.vhd  --  32-bit Arithmetic-Logic Unit
-- =============================================================================
-- Combinational ALU. Reads the 6-bit opcode from the executing instruction
-- and produces a 32-bit result. Supports the standard DLX operations:
--   * Add / sub (signed and unsigned, R-type and I-type)
--   * Logical and / or / xor
--   * Shifts: SLL, SRL (logical), SRA (arithmetic)
--   * Set-on-comparison: SLT/SLTU/SGT/SGTU/SLE/SLEU/SGE/SGEU/SEQ/SNE
--   * Branches and jumps pass through data_in2 (the immediate target) or
--     data_in1 (the register target for JR/JALR). execute.vhd takes the
--     low 10 bits of reg_ALU as jump_addr (1024-deep ROM).
--
-- The ALU is purely combinational; the result is registered at the end of
-- Execute by reg_ALU.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU is
    generic(
        DATA_WIDTH      : integer := 32;
        OP_CODE_WIDTH   : integer := 6
    );
    port(
        data_in1    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        data_in2    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        op_sel      : in  std_logic_vector(OP_CODE_WIDTH-1 downto 0);

        data_out1  : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity ALU;

architecture behavioral of ALU is
begin
    ALU_proc: process(data_in1, data_in2, op_sel)
        variable A       : signed(DATA_WIDTH-1 downto 0);
        variable B       : signed(DATA_WIDTH-1 downto 0);
        variable AU      : unsigned(DATA_WIDTH-1 downto 0);
        variable BU      : unsigned(DATA_WIDTH-1 downto 0);
        variable result  : signed(DATA_WIDTH-1 downto 0);
        variable opcode  : integer;
    begin
        -- Convert inputs
        A      := signed(data_in1);
        B      := signed(data_in2);
        AU     := unsigned(data_in1);
        BU     := unsigned(data_in2);
        opcode := to_integer(unsigned(op_sel));

        -- Default output
        result := (others => '0');

        -- ALU operations
        case opcode is

            -- LW, SW: compute effective address (base + offset)
            when 1 | 2 =>
                result := A + B;

            -- ADD (signed)
            when 3 | 4 =>
                result := resize(A + B, DATA_WIDTH);

            -- ADD (unsigned)
            when 5 | 6 =>
                result := signed(resize(AU + BU, DATA_WIDTH));

            -- SUB (signed)
            when 7 | 8 =>
                result := resize(A - B, DATA_WIDTH);

            -- SUB (unsigned)
            when 9 | 10 =>
                result := signed(resize(AU - BU, DATA_WIDTH));

            -- Logic operations
            when 11 | 12 =>
                result := A and B;

            when 13 | 14 =>
                result := A or B;

            when 15 | 16 =>
                result := A xor B;

            -- Shifts
            when 17 | 18 => -- logical left
                result := signed(shift_left(AU, to_integer(BU(4 downto 0))));

            when 19 | 20 => -- logical right
                result := signed(shift_right(AU, to_integer(BU(4 downto 0))));

            when 21 | 22 => -- arithmetic right
                result := shift_right(A, to_integer(BU(4 downto 0)));

            -- Comparisons (set-on-less-than, etc.)
            when 23 | 24 => -- SLT signed <
                result := (others => '0');
                if A < B then
                    result(0) := '1';
                end if;

            when 25 | 26 => -- SLT unsigned <
                result := (others => '0');
                if AU < BU then
                    result(0) := '1';
                end if;

            when 27 | 28 => -- signed >
                result := (others => '0');
                if A > B then
                    result(0) := '1';
                end if;

            when 29 | 30 => -- unsigned >
                result := (others => '0');
                if AU > BU then
                    result(0) := '1';
                end if;

            when 31 | 32 => -- signed <=
                result := (others => '0');
                if A <= B then
                    result(0) := '1';
                end if;

            when 33 | 34 => -- unsigned <=
                result := (others => '0');
                if AU <= BU then
                    result(0) := '1';
                end if;

            when 35 | 36 => -- signed >=
                result := (others => '0');
                if A >= B then
                    result(0) := '1';
                end if;

            when 37 | 38 => -- unsigned >=
                result := (others => '0');
                if AU >= BU then
                    result(0) := '1';
                end if;

            when 39 | 40 => -- SEQ, SEQI (equal)
                result := (others => '0');
                if A = B then
                    result(0) := '1';
                end if;

            when 41 | 42 => -- SNE, SNEI (not equal)
                result := (others => '0');
                if A /= B then
                    result(0) := '1';
                end if;

            -- BEQZ, BNEZ: pass through branch target address (data_in2)
            when 43 | 44 =>
                result := signed(data_in2);

            -- J, JAL: pass through jump target address (data_in2 = sign_ext_imm)
            when 45 | 47 =>
                result := signed(data_in2);

            -- JR, JALR: pass through jump target from register (data_in1 = rs1)
            when 46 | 48 =>
                result := A;

            when others =>
                result := (others => '0');
        end case;

        data_out1 <= std_logic_vector(result);

    end process ALU_proc;
end architecture behavioral;
