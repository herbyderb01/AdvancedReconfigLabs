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
    type reg_array_type is array (0 to 2**32-1) of std_logic_vector(7 downto 0);
    signal stack_mem    :   reg_array_type  := (others => (others => '0'));

    signal stack_head   :   integer := 0;
begin

    process(clk) begin
        if rising_edge(clk) then
            if push = '1' then
                stack_mem(stack_head) <= char_in;
                stack_head <= stack_head + 1;
            elsif pop = '1' then
                stack_head <= stack_head - 1;
                char_out <= stack_mem(stack_head);
            end if;

            if stack_head = 0 then
                stack_empty <= '1';
            else
                stack_empty <= '0';
            end if;

            if stack_head = 2**31 then
                stack_full <= '1';
            else
                stack_full <= '0';
            end if;

        end if;
    end process;

end behavioral;