library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ASCII-to-Integer Converter
--
-- Reads characters from an RX FIFO and converts decimal digit sequences
-- into 32-bit integers. Conversion begins immediately when characters
-- arrive (does not wait for a GD/GDU instruction).
--
-- Protocol:
--   - Digits '0'-'9' are accumulated: n = n * 10 + (digit - 48)
--   - A leading '-' sets the negative flag (for signed GD)
--   - Newline (0x0A) or carriage return (0x0D) terminates the integer
--   - All other characters are ignored
--   - Result is held on scan_data with scan_ready='1' until scan_rdreq
--     pulses to consume it
--
-- Uses the Quartus LPM_MULT IP (8 pipeline stages) for the multiply-by-10.

entity ascii_to_int is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;

        -- RX FIFO interface (8-bit, read side at 50 MHz)
        rx_char    : in  std_logic_vector(7 downto 0);
        rx_empty   : in  std_logic;
        rx_rdreq   : out std_logic;

        -- DLX processor interface
        scan_data  : out std_logic_vector(31 downto 0);
        scan_ready : out std_logic;
        scan_rdreq : in  std_logic
    );
end entity ascii_to_int;

architecture behavioral of ascii_to_int is

    type state_type is (idle, read_char, process_char, wait_mult, add_digit, done);
    signal state : state_type := idle;

    signal n           : unsigned(31 downto 0) := (others => '0');
    signal is_negative : std_logic := '0';
    signal has_digits  : std_logic := '0';

    -- Saved digit value while waiting for multiplier
    signal saved_digit : unsigned(3 downto 0) := (others => '0');

    -- Multiplier pipeline counter (8 stages)
    signal mult_count  : integer range 0 to 8 := 0;

    -- Multiplier interface signals
    signal mult_in     : std_logic_vector(31 downto 0);
    signal mult_out    : std_logic_vector(35 downto 0);

    -- Character classification helpers
    signal char_val    : unsigned(3 downto 0);
    signal is_digit    : std_logic;
    signal is_newline  : std_logic;
    signal is_minus    : std_logic;

begin

    -- Combinational character classification
    char_val   <= unsigned(rx_char(3 downto 0));
    is_digit   <= '1' when rx_char >= x"30" and rx_char <= x"39" else '0';
    is_newline <= '1' when rx_char = x"0A" or rx_char = x"0D" else '0';
    is_minus   <= '1' when rx_char = x"2D" else '0';

    -- Multiplier input is always n
    mult_in <= std_logic_vector(n);

    -- LPM_MULT instance: 32-bit * constant 10, 8 pipeline stages, 36-bit result
    mult_inst : entity work.multiplication
        port map (
            clock  => clk,
            dataa  => mult_in,
            result => mult_out
        );

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state       <= idle;
                n           <= (others => '0');
                is_negative <= '0';
                has_digits  <= '0';
                saved_digit <= (others => '0');
                mult_count  <= 0;
                scan_ready  <= '0';
                rx_rdreq    <= '0';
            else

                -- Default: deassert one-cycle signals
                rx_rdreq <= '0';

                case state is

                    when idle =>
                        -- In show-ahead mode, rx_char is already valid when
                        -- rx_empty='0'. Go straight to process_char.
                        if rx_empty = '0' then
                            state <= process_char;
                        end if;

                    when read_char =>
                        -- After consuming a character (rdreq pulse), wait
                        -- one cycle for the FIFO to present the next value
                        -- and update rdempty. Then return to idle.
                        rx_rdreq <= '0';
                        state    <= idle;

                    when process_char =>
                        -- Consume this character from FIFO (advance to next)
                        rx_rdreq <= '1';
                        if is_newline = '1' then
                            -- End of integer input
                            if has_digits = '1' then
                                if is_negative = '1' then
                                    scan_data <= std_logic_vector(-signed(n));
                                else
                                    scan_data <= std_logic_vector(n);
                                end if;
                                scan_ready <= '1';
                                state      <= done;
                            else
                                -- Empty enter (e.g. stray CR after LF) — ignore
                                state <= read_char;
                            end if;

                        elsif is_digit = '1' then
                            -- Save the digit, start waiting for n*10 from multiplier.
                            -- Multiplier input (mult_in = n) is already being fed;
                            -- the result will be valid after 8 clock cycles.
                            saved_digit <= char_val;
                            has_digits  <= '1';
                            mult_count  <= 0;
                            state       <= wait_mult;

                        elsif is_minus = '1' and has_digits = '0' then
                            -- Leading minus sign
                            is_negative <= '1';
                            state       <= read_char;

                        else
                            -- Ignore any other character
                            state <= read_char;
                        end if;

                    when wait_mult =>
                        -- Wait 8 clock cycles for multiplier pipeline
                        if mult_count < 8 then
                            mult_count <= mult_count + 1;
                        else
                            state <= add_digit;
                        end if;

                    when add_digit =>
                        -- n = (n * 10) + digit
                        -- Take lower 32 bits of 36-bit multiply result
                        n     <= unsigned(mult_out(31 downto 0)) + resize(saved_digit, 32);
                        state <= idle;

                    when done =>
                        -- Hold result until the processor consumes it
                        if scan_rdreq = '1' then
                            scan_ready  <= '0';
                            n           <= (others => '0');
                            is_negative <= '0';
                            has_digits  <= '0';
                            state       <= idle;
                        end if;

                end case;
            end if;
        end if;
    end process;

end behavioral;
