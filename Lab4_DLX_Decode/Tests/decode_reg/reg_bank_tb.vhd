library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--insert name of file i.e. debouncer_tb
entity reg_bank_tb is
end reg_bank_tb;

architecture behavioral of reg_bank_tb is
	
	component decode_reg
		generic (
			DATA_WIDTH	:	integer	:= 32;
			ADDR_WIDTH	:	integer	:= 5
		);
		port (
		  clk            : in  std_logic;
        rst            : in  std_logic;
        reg_read_addr1 : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        reg_read_addr2 : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        reg_write_addr : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        reg_write_data : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        reg_write_en   : in  std_logic;
        reg_read_data1 : out std_logic_vector(DATA_WIDTH-1 downto 0);
        reg_read_data2 : out std_logic_vector(DATA_WIDTH-1 downto 0)
		);
	end component decode_reg;
	
	CONSTANT DATA_WIDTH	:	integer	:= 32;
	CONSTANT ADDR_WIDTH	:	integer	:= 5;
	signal clk 			: 	std_logic;
	signal tb_rst			:	std_logic;
	signal tb_reg_read_addr1 :  std_logic_vector(ADDR_WIDTH-1 downto 0);
   signal tb_reg_read_addr2 :	 std_logic_vector(ADDR_WIDTH-1 downto 0);
   signal tb_reg_write_addr :  std_logic_vector(ADDR_WIDTH-1 downto 0);
   signal tb_reg_write_data :  std_logic_vector(DATA_WIDTH-1 downto 0);
   signal tb_reg_write_en   :  std_logic;
   signal tb_reg_read_data1 :  std_logic_vector(DATA_WIDTH-1 downto 0);
   signal tb_reg_read_data2 :  Std_logic_vector(DATA_WIDTH-1 downto 0);

	--necessary to progress simulation
	constant CLK_PERIOD : time := 10 ns;
	
begin
	
	-- use ports and signals declared to map to module
	uut : decode_reg
		generic map (
			DATA_WIDTH=> DATA_WIDTH,
			ADDR_WIDTH=> ADDR_WIDTH
		)
		port map(
			clk=>clk,
			rst=>tb_rst,
			reg_read_addr1=>tb_reg_read_addr1,
			reg_read_addr2=>tb_reg_read_addr2,
			reg_write_addr=>tb_reg_write_addr,
			reg_write_data=>tb_reg_write_data,
			reg_write_en=>tb_reg_write_en,
			reg_read_data1=>tb_reg_read_data1,
			reg_read_data2=>tb_reg_read_data2
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
		tb_rst<='1';
		tb_reg_read_addr1<="00000";
		tb_reg_read_addr2<="00000";
		tb_reg_write_addr<="00000";
		tb_reg_write_data<="00000000000000000000000000000000";
		tb_reg_write_en<='0';
		wait for CLK_PERIOD*2;
		
		tb_rst<='0';
		tb_reg_read_addr1<="00001";
		tb_reg_read_addr2<="00001";
		tb_reg_write_addr<="00001";
		tb_reg_write_data<="00000011110000000000000000000000";
		tb_reg_write_en<='1';
		wait for CLK_PERIOD*2;
		
		tb_rst<='0';
		tb_reg_read_addr1<="00011";
		tb_reg_read_addr2<="01000";
		tb_reg_write_addr<="00000";
		tb_reg_write_data<="00000000000000000000000000000000";
		tb_reg_write_en<='0';
		wait for CLK_PERIOD*2;
		
		tb_rst<='0';
		tb_reg_read_addr1<="00011";
		tb_reg_read_addr2<="01000";
		tb_reg_write_addr<="01000";
		tb_reg_write_data<="11110000000000000000000000000000";
		tb_reg_write_en<='1';
		wait for CLK_PERIOD*2;
		
		tb_rst<='0';
		tb_reg_read_addr1<="01000";
		tb_reg_read_addr2<="00001";
		tb_reg_write_addr<="00000";
		tb_reg_write_data<="00000000000000000000000000000000";
		tb_reg_write_en<='0';
		wait for CLK_PERIOD*2;
		
		tb_rst<='1';
		tb_reg_read_addr1<="00000";
		tb_reg_read_addr2<="00000";
		tb_reg_write_addr<="00000";
		tb_reg_write_data<="00000000000000000000000000000000";
		tb_reg_write_en<='0';
		wait for CLK_PERIOD*2;
		
	end process;
	
end architecture behavioral;