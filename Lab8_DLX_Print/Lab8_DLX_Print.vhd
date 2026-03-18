library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity Lab8_DLX_Print is
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
end Lab8_DLX_Print;

architecture component_list of Lab8_DLX_Print is

    component FIFO
		PORT
		(
			data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			rdclk		: IN STD_LOGIC ;
			rdreq		: IN STD_LOGIC ;
			wrclk		: IN STD_LOGIC ;
			wrreq		: IN STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
			rdempty		: OUT STD_LOGIC 
		);
	end COMPONENT;

	-- Component Declarations
	
	component PLL_UART
		PORT
		(
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC ;
			c1		: OUT STD_LOGIC 
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

	-- Signals
	--signal Rx : std_logic;
	signal Tx : std_logic;
	
	-- Clock Signals
	signal clk_rx_8x : std_logic; -- 153.6 kHz (8 * 19200)
	signal clk_tx_1x : std_logic; -- 19.2 kHz
	
	-- Interconnect Signals
	--signal rx_data_byte : std_logic_vector(7 downto 0);
	--signal rx_data_valid : std_logic;

	constant DATA_WIDTH : integer := 32;
	
	signal tx_data_byte : std_logic_vector(7 downto 0);
	signal tx_read_req : std_logic;
	signal fifo_empty : std_logic;
    signal fifo_full  : std_logic;
    signal fifo_wr          : std_logic;
    signal fifo_data        : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fifo_instr       : std_logic_vector(DATA_WIDTH-1 downto 0);

	signal char_wr			:	std_logic;
	signal char			:	std_logic_vector(7 downto 0);

begin

	-- UART IO Assignments
	--Rx <= ARDUINO_IO(0);          -- Read from IO0
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
	
	-- TX UART Instantiation
	tx_inst : TX_UART
	PORT MAP (
		Pclk    => clk_tx_1x,
		Tx      => Tx,
		rdreq   => tx_read_req,
		empty   => fifo_empty,
		data_in => tx_data_byte
	);

    character_fifo : FIFO
	PORT MAP
	(
		data		=> char,
		rdclk		=> clk_tx_1x,
		rdreq		=> tx_read_req,
		wrclk		=> MAX10_CLK1_50,
		wrreq		=> char_wr,
		q		=> tx_data_byte,
		rdempty		=> fifo_empty
	);

    char_translator_inst :  entity work.char_translator
    port map (
        clk => MAX10_CLK1_50,
        fifo_wr => fifo_wr,
        fifo_data => fifo_data,
        fifo_instr => fifo_instr,

        char => char,
		char_wr => char_wr,
        fifo_full => fifo_full
    );

    --DLX processor
    processor_inst : entity work.DLX_Processor 
    generic map (
        WIDTH => 10,
        INSTR_WIDTH => 32
    )
    port map (
        clk => MAX10_CLK1_50,
        fifo_full => fifo_full, 
        rst => ARDUINO_RESET_N,
        fifo_wr => fifo_wr,
		fifo_data => fifo_data,	
		fifo_instr => fifo_instr
    );

end component_list;