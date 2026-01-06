library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--insert name of file i.e. debouncer_tb
entity tb_RX_UART is
end tb_RX_UART;

architecture behavioral of tb_RX_UART is
	
	component RX_UART 
		port (
		   Pclk : in std_logic;
			Rx : in std_logic;
			wrreq : out std_logic;
			data_in : out std_logic_vector(7 downto 0)
		);
	end component RX_UART;
	
	signal clk : std_logic;
	signal Rx : std_logic;
	signal  wrreq : std_logic;
	signal data_in : std_logic_vector(7 downto 0);
	--create signals that match component ports to simulate
	--signal en : std_logic := '1';
	--signal rst : std_logic := '1';
	--signal rn : std_logic_vector(7 downto 0);
	
	--necessary to progress simulation
	constant CLK_PERIOD : time := 10 ns;
	
begin
	
	-- use ports and signals declared to map to module
	uut : RX_UART
		port map(
			--insert signals to module like below
			Pclk => clk,
			Rx => Rx,
			wrreq => wrreq,
			data_in => data_in
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