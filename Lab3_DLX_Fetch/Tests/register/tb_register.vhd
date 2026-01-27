library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_register is
end tb_register;

architecture behavioral of tb_register is
    
    component reggi 
        generic (
            N : integer := 10
        );
        port (
            data_in	:	in 	std_logic_vector(N-1 downto 0);
            rst		:	in		std_logic;
            clk		:	in		std_logic;
            data_out	:	out	std_logic_vector(N-1 downto 0)
        );
    end component reggi;
    
    -- Clock
    signal clk : std_logic;
    constant CLK_PERIOD : time := 10 ns;

    --create signals that match component ports to simulate
    signal tb_data_in : std_logic_vector(9 downto 0) := (others => '0');
    signal tb_rst : std_logic := '1';
    signal tb_data_out : std_logic_vector(9 downto 0);
    
begin
    
    -- use ports and signals declared to map to module
    uut : reggi
        generic map (
            N => 10
        )
        port map(
            data_in => tb_data_in,
            rst => tb_rst,
            clk => clk,
            data_out => tb_data_out
        );
        
    --process to set the clock
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    --manipulate inputs to module to view results you want
    stm_process : process
    begin
        -- Start with reset asserted
        tb_rst <= '1';
        wait for CLK_PERIOD * 2;

        -- De-assert reset and load a value
        tb_rst <= '0';
        tb_data_in <= "1101111010";
        wait for CLK_PERIOD;

        -- Load another value
        tb_data_in <= "1100101011";
        wait for CLK_PERIOD;

        -- Assert reset again
        tb_rst <= '1';
        wait for CLK_PERIOD;
        
        -- De-assert reset, should be 0
        tb_rst <= '0';
        wait;
    end process;
    
end architecture behavioral;