library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--insert name of file i.e. debouncer_tb
entity tb_TX_UART is
end tb_TX_UART;

architecture behavioral of tb_TX_UART is
	
	component TX_UART 
		port (
		   Pclk		: in  std_logic;
			empty 	: in 	std_logic;
			data_in	: in 	std_logic_vector(7 downto 0);
			
			Tx 		: out	std_logic;
			rdreq		: out std_logic
		);
	end component TX_UART;
	
	signal Pclk : std_logic;
	signal empty: std_logic := '1';
	signal data_in: std_logic_vector(7 downto 0);
	
	signal Tx	: std_logic;
	signal rdreq: std_logic;
	
	--necessary to progress simulation
	constant CLK_PERIOD : time := 10 ns;
	
begin
	
	-- use ports and signals declared to map to module
	uut : TX_UART
		port map(
			--insert signals to module like below
			Pclk => Pclk,
			empty => empty,
			data_in => data_in,
			Tx => Tx,
			rdreq => rdreq
		);
		
	--process to set the clock
	--keep this the same for all simulations
	clk_process : process
	begin
		Pclk <= '0';
		wait for clk_period / 2;
		Pclk <= '1';
		wait for clk_period/2;
	end process;

	--manipulate inputs to module to view results you want
	stm_process : process
	begin
		data_in <= "01010101";
		wait for clk_period * 3;
		empty <= '0';
		wait for CLK_PERIOD;
		empty <= '1';
		wait for CLK_PERIOD*10;
	end process;
	
end architecture behavioral;