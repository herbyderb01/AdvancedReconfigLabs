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
                result := signed(shift_left(AU, to_integer(BU(DATA_WIDTH-1 downto DATA_WIDTH-5))));

            when 19 | 20 => -- logical right
                result := signed(shift_right(AU, to_integer(BU(DATA_WIDTH-1 downto DATA_WIDTH-5))));

            when 21 | 22 => -- arithmetic right
                result := shift_right(A, to_integer(BU(DATA_WIDTH-1 downto DATA_WIDTH-5)));

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

            when 39 | 40 => -- signed =
                result := (others => '0');
                if A = B then
                    result(0) := '1';
                end if;

            when 41 | 42 => -- unsigned =
                result := (others => '0');
                if AU = BU then
                    result(0) := '1';
                end if;

            when 43 | 44 => -- signed /=
                result := (others => '0');
                if A /= B then
                    result(0) := '1';
                end if;

            when 45 | 46 => -- unsigned /=
                result := (others => '0');
                if AU /= BU then
                    result(0) := '1';
                end if;

            when others =>
                result := (others => '0');
        end case;

        data_out1 <= std_logic_vector(result);

    end process ALU_proc;
end architecture behavioral;
