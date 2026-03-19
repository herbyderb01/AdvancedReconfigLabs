library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

use work.decode_reg_pkg.all;

entity char_translator is
    port (
        clk :   in  std_logic;
        fifo_wr :   in  std_logic;
        fifo_data : in  std_logic_vector(31 downto 0);
        fifo_instr : in std_logic_vector(31 downto 0);

        char    :   out std_logic_vector(7 downto 0);
        char_wr :   out std_logic;
        fifo_full   :   out std_logic
    );
end char_translator;

architecture behavioral of char_translator is

    type state_type is (idle, fifo_ready, compute_div, wait_for_div, push_wait, wait_for_stack);
    signal state    :   state_type  := idle;

    signal stack_char  :   std_logic_vector(7 downto 0);
    signal stack_full   :   std_logic;
    signal stack_empty  :   std_logic;
    signal char_out    :   std_logic_vector(7 downto 0);
    signal sign_tracker:    std_logic := '0';

    signal rdreq :  std_logic := '0';
    
    signal data  :  std_logic_vector(31 downto 0);
    signal data_rdempty :   std_logic;
    signal data_full    :   std_logic;

    signal instr    :   std_logic_vector(31 downto 0);
    signal instr_rdempty    :   std_logic;
    signal instr_full       :   std_logic;

    signal numer    :   std_logic_vector(31 downto 0) := (others => '0');
    signal quotient :   std_logic_vector(31 downto 0);
    signal remain   :   std_logic_vector(3 downto 0);
    signal temp     :   std_logic_vector(31 downto 0) := (others => '0');

    signal div_counter  :   integer := 0;
    signal push_counter  :   integer := 0;
    signal pop_counter  :   integer := 0;

    signal push :   std_logic := '0';
    signal pop  :   std_logic := '0';

begin

    fifo_full <= instr_full or data_full;

    data_fifo : entity work.UART_TX_DATA
    port map (
        data => fifo_data,
        clock => clk,
        rdreq => rdreq,
        wrreq => fifo_wr,
        q => data,
        empty => data_rdempty,
        full => data_full
    );

    instr_fifo : entity work.UART_TX_DATA
    port map (
        data => fifo_instr,
        clock => clk,
        rdreq => rdreq,
        wrreq => fifo_wr,
        q => instr,
        empty => instr_rdempty,
        full => instr_full 
    );

    char <= char_out;
    
    process (clk) begin
        if rising_edge(clk) then
        case state is

            when idle =>
                rdreq <= '0';
                push <= '0';
                pop  <= '0';
                if data_rdempty = '0' and instr_rdempty = '0' then
                    -- Wait 1 cycle for FIFO output register to present valid data
                    state <= fifo_ready;
                end if;

            when fifo_ready =>
                -- FIFO q outputs are now valid (output register has settled)
                if instr(31 downto 26) = OP_PD then
                    if data(31) = '1' then
                        temp <= std_logic_vector(-signed(data));
                    else
                        temp <= data;
                    end if;
                else
                    temp <= data;
                end if;
                state <= compute_div;
            
            when compute_div =>
                push <= '0';
                if instr(31 downto 26) = OP_PCH then
                    state <= push_wait;
                    stack_char <= temp(7 downto 0);
                    push <= '1';
                else
                    numer <= temp;
                    state <= wait_for_div;
                    stack_char <= "00110000"; --48
                end if;
            
            when wait_once_for_push =>
                push <= '0';
                if push_counter < 2 then
                    push_counter <= push_counter + 1;
                else    
                    state <= wait_for_stack;
                    push_counter <= 0;
                end if;

            when wait_for_div =>
                push <= '0';
                if div_counter < 8 then
                    state <= wait_for_div;
                    div_counter <= div_counter + 1;
                else
                    if quotient = (quotient'range => '0') and remain = (remain'range => '0') then
                        state <= wait_once_for_push;
                    else
                        stack_char(3 downto 0) <= remain;
                        push <= '1';
                        temp <= quotient;
                        state <= push_wait;
                    end if;
                    div_counter <= 0;
                end if;

            when push_wait =>
                -- Wait 1 cycle for the stack to process the push
                push <= '0';
                if instr(31 downto 26) = OP_PCH then
                    state <= wait_for_stack;
                else
                    state <= compute_div;
                end if;

            when wait_for_stack =>
                push <= '0';
                pop <= '0';
                if stack_empty = '0' then
                    pop <= '1';
                    char_wr <= '1';
                    state <= wait_for_pop;
                else
                    pop <= '0';
                    char_wr <= '0';
                    rdreq <= '1';
                    state <= wait_once_for_idle;
                end if;

            when wait_for_pop =>
                pop <= '0';
                char_wr <= '0';
                if pop_counter < 2 then
                    pop_counter <= pop_counter + 1;
                else 
                    state <= wait_for_stack;
                    pop_counter <= 0;
                end if;
            
            when wait_once_for_idle =>
                rdreq <= '0';
                state <= idle;

        end case;
        end if;
    end process;

    char_stack  :   entity work.stack
    port map(
        clk => clk,
        char_in => stack_char,

        push => push,
        pop  => pop,
        stack_full => stack_full,
        stack_empty => stack_empty,
        char_out => char_out
    );

    div_inst    :   entity work.division
    port map(
        clock => clk,
        denom => "1010",
        numer => numer,
        quotient => quotient,
        remain => remain
    );

end behavioral;