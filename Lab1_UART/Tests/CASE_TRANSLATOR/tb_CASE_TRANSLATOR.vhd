library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--insert name of file i.e. debouncer_tb
entity tb_CASE_TRANSLATOR is
end tb_CASE_TRANSLATOR;

architecture behavioral of tb_CASE_TRANSLATOR is
	
	component CASE_TRANSLATOR 
		port (
		   wrclk	:	in	std_logic;
			rdclk	:	in	std_logic;
			
			data_in : in std_logic_vector(7 downto 0);
			
			translate_req : in std_logic;
			read_req : in std_logic;
			
			data_out : out std_logic_vector(7 downto 0);
			empty	: out std_logic
		);
	end component CASE_TRANSLATOR;
	
	signal wrclk : std_logic;
	signal rdclk : std_logic;
	signal data_in : std_logic_vector(7 downto 0) := "01010101";
	signal translate_req : std_logic := '0';
	signal read_req : std_logic := '0';
	signal data_out : std_logic_vector(7 downto 0);
	signal empty : std_logic;
	
	--necessary to progress simulation
	constant WR_CLK_PERIOD : time := 10 ns;
	constant RD_CLK_PERIOD : time := 20 ns;
	
begin
	
	-- use ports and signals declared to map to module
	uut : CASE_TRANSLATOR
		port map(
			wrclk => wrclk,
			rdclk => rdclk,
			data_in => data_in,
			translate_req => translate_req,
			read_req => read_req,
			data_out => data_out,
			empty => empty
		);
		
	--process to set the clock
	--keep this the same for all simulations
	wr_clk_process : process
	begin
		wrclk <= '0';
		wait for WR_CLK_PERIOD / 2;
		wrclk <= '1';
		wait for WR_CLK_PERIOD/2;
	end process;
	
	rd_clk_process : process
	begin
		rdclk <= '0';
		wait for RD_CLK_PERIOD / 2;
		rdclk <= '1';
		wait for RD_CLK_PERIOD/2;
	end process;

	--manipulate inputs to module to view results you want
	stm_process : process
	begin
		wait for WR_CLK_PERIOD * 2; translate_req <= '1';
		wait for WR_CLK_PERIOD; translate_req <= '0';
		wait for RD_CLK_PERIOD * 12; 
	end process;
	
end architecture behavioral;