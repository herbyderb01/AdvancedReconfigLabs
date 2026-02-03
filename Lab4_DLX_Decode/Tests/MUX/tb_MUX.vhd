library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_MUX is
end tb_MUX;

architecture behavioral of tb_MUX is
	
	component MUX 
		generic (
			N : integer := 10
		);
		port (
			A		:	in		std_logic_vector(N-1 downto 0);
			B		:	in 	std_logic_vector(N-1 downto 0);
			S		:	in 	std_logic;
			OUTPUT:	out 	std_logic_vector(N-1 downto 0)
		);
	end component MUX;
	
	--create signals that match component ports to simulate
	signal tb_A : std_logic_vector(9 downto 0) := (others => '0');
	signal tb_B : std_logic_vector(9 downto 0) := (others => '0');
	signal tb_S : std_logic := '0';
	signal tb_OUTPUT : std_logic_vector(9 downto 0);
	
	signal clk : std_logic;
	--necessary to progress simulation
	constant CLK_PERIOD : time := 10 ns;
	
begin
	
	-- use ports and signals declared to map to module
	uut : MUX
		generic map (
			N => 10
		)
		port map(
			A => tb_A,
			B => tb_B,
			S => tb_S,
			OUTPUT => tb_OUTPUT
		);
		
	--process to set the clock
	--keep this the same for all simulations
	clk_process : process
	begin
		clk <= '0';
		wait for CLK_PERIOD / 2;
		clk <= '1';
		wait for CLK_PERIOD/2;
	end process;

	--manipulate inputs to module to view results you want
	stm_process : process
	begin
		-- Test case 1: S = '0', OUTPUT should be B
		tb_A <= "1010101010";
		tb_B <= "1111000011";
		tb_S <= '0';
		wait for CLK_PERIOD * 2;
		
		-- Test case 2: S = '1', OUTPUT should be A
		tb_S <= '1';
		wait for CLK_PERIOD * 2;

		-- Test case 3: Change inputs
		tb_A <= "0101010101";
		tb_B <= "0000111100";
		tb_S <= '0';
		wait for CLK_PERIOD * 2;

		-- Test case 4: S = '1' again
		tb_S <= '1';
		wait for CLK_PERIOD * 2;

		wait;
	end process;
	
end architecture behavioral;