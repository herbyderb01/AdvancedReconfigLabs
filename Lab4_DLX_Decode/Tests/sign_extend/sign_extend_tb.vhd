library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--insert name of file i.e. debouncer_tb
entity sign_extend_tb is
end sign_extend_tb;

architecture behavioral of sign_extend_tb is
	
	component sign_extend 
		port (
			input_data 		:	in		std_logic_vector(15 downto 0);
			output_data		:	out	std_logic_vector(31 downto 0)
		    --insert ports to module
		);
	end component sign_extend;
	
	constant INPUT_LENGTH	:	integer	:= 16;
	constant	OUTPUT_LENGTH	:	integer	:= 32;
	signal clk : std_logic;
	signal tb_immediate	:	std_logic_vector(INPUT_LENGTH-1 downto 0);
	signal tb_ext_sign	:	std_logic_vector(OUTPUT_LENGTH-1 downto 0);
	
	--necessary to progress simulation
	constant CLK_PERIOD : time := 10 ns;
	
begin
	
	-- use ports and signals declared to map to module
	uut : sign_extend
		port map(
			input_data=>tb_immediate,
			output_data=>tb_ext_sign
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
		tb_immediate <= "1001100000101010";
		wait for CLK_PERIOD*2;
		tb_immediate <= "0111100000101010";
		wait for CLK_PERIOD*2;
	end process;
	
end architecture behavioral;