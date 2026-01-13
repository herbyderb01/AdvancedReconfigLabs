library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_RX_UART is
end tb_RX_UART;

architecture behavioral of tb_RX_UART is

    component RX_UART
        port (
            clk    : in  std_logic;
            Rx      : in  std_logic;
            wrreq   : out std_logic;
            data_in : out std_logic_vector(7 downto 0)
        );
    end component;

    signal clk     : std_logic := '0';
    signal Rx      : std_logic := '1';  -- UART idle is HIGH
    signal wrreq   : std_logic;
    signal data_in : std_logic_vector(7 downto 0);

    constant CLK_PERIOD : time := 10 ns;
    constant BIT_TIME   : time := CLK_PERIOD * 8;

begin

    -- DUT instantiation
    uut : RX_UART
        port map (
            clk    => clk,
            Rx      => Rx,
            wrreq   => wrreq,
            data_in => data_in
        );

    -- Clock generation (100 MHz)
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- =========================
    -- UART RX Stimulus
    -- =========================
    stim_process : process
    begin
        -- idle line
        Rx <= '1';
        wait for BIT_TIME * 2;

        -- =====================
        -- START BIT
        -- =====================
        Rx <= '0';
        wait for BIT_TIME;

        -- =====================
        -- DATA BITS (0x55 = 01010101, LSB first)
        -- =====================
        Rx <= '1'; wait for BIT_TIME; -- bit 0
        Rx <= '0'; wait for BIT_TIME; -- bit 1
        Rx <= '1'; wait for BIT_TIME; -- bit 2
        Rx <= '0'; wait for BIT_TIME; -- bit 3
        Rx <= '1'; wait for BIT_TIME; -- bit 4
        Rx <= '0'; wait for BIT_TIME; -- bit 5
        Rx <= '1'; wait for BIT_TIME; -- bit 6
        Rx <= '0'; wait for BIT_TIME; -- bit 7

        -- =====================
        -- STOP BIT
        -- =====================
        Rx <= '1';
        wait for BIT_TIME;

        -- wait so we can observe wrreq
        wait for BIT_TIME * 4;

        -- end simulation
        wait;
    end process;

end architecture behavioral;
