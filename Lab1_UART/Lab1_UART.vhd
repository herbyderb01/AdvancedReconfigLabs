library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Lab1_UART is
	port (
	
	-- Clock
	ADC_CLK_10 : in std_logic;
	MAX10_CLK1_50 : in std_logic;
	MAX10_CLK2_50 : in std_logic;
	
	-- Arduino Header
	-- I/O 0 - Rx
	-- I/O 1 - Tx

	ARDUINO_IO      : inout std_logic_vector(15 downto 0);
	ARDUINO_RESET_N : inout std_logic

	);
end Lab1_UART;

architecture component_list of Lab1_UART is

	-- Component Declarations
	
	component PLL_UART
		PORT
		(
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC ;
			c1		: OUT STD_LOGIC 
		);
	end component;

	component RX_UART
		port 
		(
			clk : in std_logic;
			Rx: in std_logic;
			wrreq: out std_logic;
			data_out: out std_logic_vector(7 downto 0)
		);
	end component;
	
	component TX_UART
		port 
		(
			Pclk : in std_logic;
			Tx: out std_logic;
			rdreq: out std_logic;
			empty: in std_logic;
			data_in: in std_logic_vector(7 downto 0)
		);
	end component;
	
	component CASE_TRANSLATOR
		port 
		(
			wrclk : in std_logic;
			rdclk : in std_logic;
			data_in: in std_logic_vector(7 downto 0);
			translate_req: in std_logic;
			read_req: in std_logic;
			data_out: out std_logic_vector(7 downto 0);
			empty: out std_logic
		);
	end component;

	-- Signals
	signal Rx : std_logic;
	signal Tx : std_logic;
	
	-- Clock Signals
	signal clk_rx_8x : std_logic; -- 153.6 kHz (8 * 19200)
	signal clk_tx_1x : std_logic; -- 19.2 kHz
	
	-- Interconnect Signals
	signal rx_data_byte : std_logic_vector(7 downto 0);
	signal rx_data_valid : std_logic;
	
	signal tx_data_byte : std_logic_vector(7 downto 0);
	signal tx_read_req : std_logic;
	signal fifo_empty : std_logic;

begin

	-- UART IO Assignments
	Rx <= ARDUINO_IO(0);          -- Read from IO0
	ARDUINO_IO(0) <= 'Z';         -- Tri-state IO0 so it can be used as input
	
	ARDUINO_IO(1) <= Tx;          -- Write internal Tx to IO1
	
	ARDUINO_IO(15 downto 2) <= (others => 'Z'); -- Set unused pins to high-Z
	
	
	-- PLL Instantiation
	pll_inst : PLL_UART
	PORT MAP (
		inclk0 => MAX10_CLK1_50,
		c0     => clk_rx_8x,
		c1     => clk_tx_1x
	);

	-- RX UART Instantiation
	rx_inst : RX_UART
	PORT MAP (
		clk     => clk_rx_8x,
		Rx      => Rx,
		wrreq   => rx_data_valid,
		data_out => rx_data_byte
	);
	
	-- Casing Translator & FIFO Instantiation
	translator_inst : CASE_TRANSLATOR
	PORT MAP (
		wrclk         => clk_rx_8x,
		rdclk         => clk_tx_1x,
		data_in       => rx_data_byte,
		translate_req => rx_data_valid,
		read_req      => tx_read_req,
		data_out      => tx_data_byte,
		empty         => fifo_empty
	);
	
	-- TX UART Instantiation
	tx_inst : TX_UART
	PORT MAP (
		Pclk    => clk_tx_1x,
		Tx      => Tx,
		rdreq   => tx_read_req,
		empty   => fifo_empty,
		data_in => tx_data_byte
	);

end component_list;