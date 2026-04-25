-- =============================================================================
-- stack.vhd  --  Tiny LIFO byte stack (12 entries deep)
-- =============================================================================
-- Used by char_translator while converting an integer to decimal: divide by
-- 10 repeatedly produces digits in least-significant-first order, but they
-- must be transmitted most-significant-first. The stack reverses the order:
-- push each digit as it comes out of the divider, then pop them all into
-- the TX FIFO.
--
-- Depth = 12 covers a 10-digit unsigned 32-bit value plus an optional sign
-- byte plus a small safety margin.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity stack is
    port(
        clk :   in  std_logic;
        char_in :   in  std_logic_vector(7 downto 0);

        push    :   in  std_logic;
        pop     :   in  std_logic;

        stack_full  :   out std_logic;
        stack_empty :   out std_logic;
        char_out    :   out std_logic_vector(7 downto 0)
    );
end stack;

architecture behavioral of stack is
    constant STACK_DEPTH : integer := 12; -- 10 digits + sign + margin
    type reg_array_type is array (0 to STACK_DEPTH-1) of std_logic_vector(7 downto 0);
    signal stack_mem    :   reg_array_type  := (others => (others => '0'));

    signal stack_head   :   integer range 0 to STACK_DEPTH := 0;
begin

    -- Combinational outputs: no 1-cycle delay
    stack_empty <= '1' when stack_head = 0 else '0';
    stack_full  <= '1' when stack_head = STACK_DEPTH else '0';
    char_out    <= stack_mem(stack_head - 1) when stack_head > 0 else (others => '0');

    process(clk) begin
        if rising_edge(clk) then
            if push = '1' then
                stack_mem(stack_head) <= char_in;
                stack_head <= stack_head + 1;
            elsif pop = '1' and stack_head > 0 then
                stack_head <= stack_head - 1;
            end if;
        end if;
    end process;

end behavioral;
