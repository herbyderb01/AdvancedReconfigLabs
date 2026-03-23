library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--insert name of file i.e. debouncer_tb
entity FILENAME is
end FILENAME;

architecture behavioral of FILENAME is
	
	component MODULE_NAME 
		generic (
			--insert generics if applicable
		);
		port (
		    --insert ports to module
		);
	end component MODULE_NAME;
	
	signal clk : std_logic;
	--create signals that match component ports to simulate
	--signal en : std_logic := '1';
	--signal rst : std_logic := '1';
	--signal rn : std_logic_vector(7 downto 0);
	
	--necessary to progress simulation
	constant CLK_PERIOD : time := 10 ns;
	
begin
	
	-- use ports and signals declared to map to module
	uut : MODULE_NAME
		generic map (
			--insert generics if applicable 
			--ie N => 8,
		)
		port map(
			--insert signals to module like below
			--clk => clk,
			--en => en,
			--rst => rst,
			--rn => rn
		);
		
	--process to set the clock
	--keep this the same for all simulations
	clk_process : process
	begin
		clk <= '0';
		wait for clk_period / 2;
		clk <= '1';
		wait for clk_period/2;
	end process;

	--manipulate inputs to module to view results you want
	stm_process : process
	begin
		-- ie
		--wait for clk_period *10;
		--en <= '0';
		--wait for clk_period * 20;
		--en <= '1';
		--wait;
	end process;
	
end architecture behavioral;