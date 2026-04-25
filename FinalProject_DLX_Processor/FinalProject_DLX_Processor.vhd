library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity FinalProject_DLX_Processor is
	port (
	
	-- Clock
	ADC_CLK_10 : in std_logic;
	MAX10_CLK1_50 : in std_logic;
	MAX10_CLK2_50 : in std_logic;

	-- SEG7
	HEX0 : out std_logic_vector(7 downto 0);
	HEX1 : out std_logic_vector(7 downto 0);
	HEX2 : out std_logic_vector(7 downto 0);
	HEX3 : out std_logic_vector(7 downto 0);
	HEX4 : out std_logic_vector(7 downto 0);
	HEX5 : out std_logic_vector(7 downto 0);
	
	-- Tx	:	out	std_logic;
	
	-- Arduino Header
	-- I/O 0 - Rx
	-- I/O 1 - Tx

	ARDUINO_IO      : inout std_logic_vector(15 downto 0);
	ARDUINO_RESET_N : inout std_logic;

	-- Push buttons (active low)
	KEY : in std_logic_vector(1 downto 0)

	);
end FinalProject_DLX_Processor;

architecture component_list of FinalProject_DLX_Processor is

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
	signal Rx : std_logic;
	signal Tx : std_logic;

	-- Clock Signals
	signal clk_rx_8x : std_logic; -- 153.6 kHz (8 * 19200)
	signal clk_tx_1x : std_logic; -- 19.2 kHz

	-- RX path signals
	signal rx_byte       : std_logic_vector(7 downto 0);
	signal rx_wrreq      : std_logic;
	signal rx_fifo_data  : std_logic_vector(7 downto 0);
	signal rx_fifo_empty : std_logic;
	signal rx_fifo_rdreq : std_logic;

	-- Scan (ascii_to_int -> DLX) signals
	signal scan_data     : std_logic_vector(31 downto 0);
	signal scan_ready    : std_logic;
	signal scan_rdreq    : std_logic;

	constant DATA_WIDTH : integer := 32;

	-- TX path signals
	signal tx_data_byte : std_logic_vector(7 downto 0);
	signal tx_read_req : std_logic;
	signal fifo_empty : std_logic;
    signal fifo_full  : std_logic;
    signal fifo_wr          : std_logic;
    signal fifo_data        : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fifo_instr       : std_logic_vector(DATA_WIDTH-1 downto 0);

	signal char_wr			:	std_logic;
	signal char			:	std_logic_vector(7 downto 0);

	-- Timer control signals (from DLX processor)
	signal timer_rst   : std_logic;
	signal timer_go    : std_logic;
	signal timer_stop  : std_logic;

	--Temporary signals for HEX display
	signal temp_hex2 : std_logic_vector(7 downto 0);
	signal temp_hex4 : std_logic_vector(7 downto 0);

	signal fast_clk : std_logic;

begin
	ARDUINO_RESET_N <= 'Z';

	-- UART IO Assignments
	Rx <= ARDUINO_IO(0);          -- Read from IO0
	ARDUINO_IO(0) <= 'Z';         -- Tri-state IO0 so it can be used as input

	ARDUINO_IO(1) <= Tx;          -- Write internal Tx to IO1

	ARDUINO_IO(15 downto 2) <= (others => 'Z'); -- Set unused pins to high-Z

	HEX2 <= "01111111" and temp_hex2; -- HEX2 is used for timer, but also shows 'E' when timer is stopped
	HEX4 <= "01111111" and temp_hex4; -- HEX4 is used

	-- PLL Instantiation
	pll_inst : PLL_UART
	PORT MAP (
		inclk0 => MAX10_CLK1_50,
		c0     => clk_rx_8x,
		c1     => clk_tx_1x
	);

	fast_pll_inst : entity work.faster_PLL
	PORT MAP (
		inclk0 => MAX10_CLK1_50,
		c0     => fast_clk
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
		wrclk		=> fast_clk,
		wrreq		=> char_wr,
		q		=> tx_data_byte,
		rdempty		=> fifo_empty
	);

    char_translator_inst :  entity work.char_translator
    port map (
        clk => fast_clk,
        fifo_wr => fifo_wr,
        fifo_data => fifo_data,
        fifo_instr => fifo_instr,

        char => char,
		char_wr => char_wr,
        fifo_full => fifo_full
    );

    ---------------------------------------------------------------------------
    -- RX UART CHAIN: ARDUINO_IO(0) -> RX_UART -> dcfifo -> ascii_to_int
    ---------------------------------------------------------------------------

    -- RX UART: serial bits -> 8-bit bytes (runs at 153.6 kHz = 8x oversampling)
    rx_inst : entity work.RX_UART
    port map (
        clk      => clk_rx_8x,
        Rx       => Rx,
        wrreq    => rx_wrreq,
        data_out => rx_byte
    );

    -- RX FIFO: clock domain crossing 153.6 kHz -> 50 MHz (reuse existing dcfifo)
    rx_fifo_inst : FIFO
    port map (
        data    => rx_byte,
        wrclk   => clk_rx_8x,
        wrreq   => rx_wrreq,
        rdclk   => fast_clk,
        rdreq   => rx_fifo_rdreq,
        q       => rx_fifo_data,
        rdempty => rx_fifo_empty
    );

    -- ASCII-to-integer converter FSM (runs at 50 MHz)
    ascii_to_int_inst : entity work.ascii_to_int
    port map (
        clk        => fast_clk,
        rst        => not KEY(0),
        rx_char    => rx_fifo_data,
        rx_empty   => rx_fifo_empty,
        rx_rdreq   => rx_fifo_rdreq,
        scan_data  => scan_data,
        scan_ready => scan_ready,
        scan_rdreq => scan_rdreq
    );

    ---------------------------------------------------------------------------
    -- DLX PROCESSOR
    ---------------------------------------------------------------------------
    processor_inst : entity work.DLX_Processor
    generic map (
        WIDTH => 10,
        INSTR_WIDTH => 32
    )
    port map (
        clk => fast_clk,
        fifo_full => fifo_full,
        rst => not KEY(0),
        fifo_wr => fifo_wr,
		fifo_data => fifo_data,
		fifo_instr => fifo_instr,
        scan_data  => scan_data,
        scan_ready => scan_ready,
        scan_rdreq => scan_rdreq,
        timer_rst  => timer_rst,
        timer_go   => timer_go,
        timer_stop => timer_stop
    );

    ---------------------------------------------------------------------------
    -- STOPWATCH TIMER
    ---------------------------------------------------------------------------
    timer_inst : entity work.Timer_counter
    port map (
        clk   => MAX10_CLK1_50,
        start => timer_go,
        stop  => timer_stop,
        rst   => timer_rst,
        HEX0  => HEX0,
        HEX1  => HEX1,
        HEX2  => temp_hex2,
        HEX3  => HEX3,
        HEX4  => temp_hex4,
        HEX5  => HEX5
    );

end component_list;