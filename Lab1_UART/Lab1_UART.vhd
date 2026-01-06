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


	-- Signals
	signal Rx : std_logic;
	signal Tx : std_logic;

begin

	-- UART IO Assignments
	Rx <= ARDUINO_IO(0);          -- Read from IO0
	ARDUINO_IO(0) <= 'Z';         -- Tri-state IO0 so it can be used as input
	
	ARDUINO_IO(1) <= Tx;          -- Write internal Tx to IO1
	
	ARDUINO_IO(15 downto 2) <= (others => 'Z'); -- Set unused pins to high-Z

end component_list;