library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ripple_adder is
end tb_ripple_adder;

architecture behavioral of tb_ripple_adder is
    
    component ripple_adder 
        generic (
            N : integer := 10
        );
        port (
            A		: in std_logic_vector(N-1 downto 0);
            B		: in std_logic_vector(N-1 downto 0);
            C_in 	: in std_logic;
            SUM	: out std_logic_vector(N-1 downto 0);
            C_out	: out std_logic
        );
    end component ripple_adder;
    
    --create signals that match component ports to simulate
    signal tb_A : std_logic_vector(9 downto 0) := (others => '0');
    signal tb_B : std_logic_vector(9 downto 0) := (others => '0');
    signal tb_C_in : std_logic := '0';
    signal tb_SUM : std_logic_vector(9 downto 0);
    signal tb_C_out : std_logic;
    
    signal clk : std_logic;
    --necessary to progress simulation
    constant CLK_PERIOD : time := 10 ns;
    
begin
    
    -- use ports and signals declared to map to module
    uut : ripple_adder
        generic map (
            N => 10
        )
        port map(
            A => tb_A,
            B => tb_B,
            C_in => tb_C_in,
            SUM => tb_SUM,
            C_out => tb_C_out
        );
        
    --process to set the clock
    --keep this the same for all simulations
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
        -- Test case 1: 5 + 5
        tb_A <= "0000000101";
        tb_B <= "0000000101";
        tb_C_in <= '0';
        wait for CLK_PERIOD * 2;
        
        -- Test case 2: 10 + 15 with carry in
        tb_A <= "0000001010";
        tb_B <= "0000001111";
        tb_C_in <= '1';
        wait for CLK_PERIOD * 2;

        -- Test case 3: Max value + 1 (should overflow)
        tb_A <= "1111111111";
        tb_B <= "0000000001";
        tb_C_in <= '0';
        wait for CLK_PERIOD * 2;

		-- Test case 4: Add 1 multiple times
        tb_A <= "0000011001";
        tb_B <= "0000000001";
        tb_C_in <= '0';
        wait for CLK_PERIOD;
		
		tb_A <= tb_C_out;
        tb_B <= "0000000001";
        tb_C_in <= '0';
        wait for CLK_PERIOD;

		tb_A <= tb_C_out;
        tb_B <= "0000000001";
        tb_C_in <= '0';
        wait for CLK_PERIOD;

		tb_A <= tb_C_out;
        tb_B <= "0000000001";
        tb_C_in <= '0';
        wait for CLK_PERIOD;

		tb_A <= tb_C_out;
        tb_B <= "0000000100";
        tb_C_in <= '0';
        wait for CLK_PERIOD;

        wait;
    end process;
    
end architecture behavioral;