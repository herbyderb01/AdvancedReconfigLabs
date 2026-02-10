library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ALU is
end tb_ALU;

architecture behavioral of tb_ALU is
	
	component ALU 
		generic (
            DATA_WIDTH      : integer := 32;
            OP_CODE_WIDTH   : integer := 6
		);
		port (
            data_in1    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            data_in2    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            op_sel      : in  std_logic_vector(OP_CODE_WIDTH-1 downto 0);
            data_out1   : out std_logic_vector(DATA_WIDTH-1 downto 0)
		);
	end component ALU;
	
	signal clk : std_logic;
	constant CLK_PERIOD : time := 10 ns;

    -- Signals for ALU inputs/outputs
    signal tb_data_in1 : std_logic_vector(31 downto 0) := (others => '0');
    signal tb_data_in2 : std_logic_vector(31 downto 0) := (others => '0');
    signal tb_op_sel   : std_logic_vector(5 downto 0)  := (others => '0');
    signal tb_data_out1: std_logic_vector(31 downto 0);
	
begin
	
	uut : ALU
		generic map (
            DATA_WIDTH    => 32,
            OP_CODE_WIDTH => 6
		)
		port map(
            data_in1   => tb_data_in1,
            data_in2   => tb_data_in2,
            op_sel     => tb_op_sel,
            data_out1  => tb_data_out1
		);
		
	-- Process to set the clock (used for sequencing tests)
	clk_process : process
	begin
		clk <= '0';
		wait for CLK_PERIOD / 2;
		clk <= '1';
		wait for CLK_PERIOD/2;
	end process;

	-- Stimulus process
	stm_process : process
	begin
        wait for CLK_PERIOD;
        
        ------------------------------------------------------------
        -- ARITHMETIC
        ------------------------------------------------------------
        
        -- 1. ADD Signed (Op 3/4): -5 + 10 = 5
        tb_data_in1 <= std_logic_vector(to_signed(-5, 32));
        tb_data_in2 <= std_logic_vector(to_signed(10, 32));
        tb_op_sel   <= std_logic_vector(to_unsigned(3, 6));
        wait for CLK_PERIOD;

        -- 2. ADDU Unsigned (Op 5/6): 10 + 20 = 30
        tb_data_in1 <= std_logic_vector(to_unsigned(10, 32));
        tb_data_in2 <= std_logic_vector(to_unsigned(20, 32));
        tb_op_sel   <= std_logic_vector(to_unsigned(5, 6));
        wait for CLK_PERIOD;

        -- 3. SUB Signed (Op 7/8): 10 - 20 = -10
        tb_data_in1 <= std_logic_vector(to_signed(10, 32));
        tb_data_in2 <= std_logic_vector(to_signed(20, 32));
        tb_op_sel   <= std_logic_vector(to_unsigned(7, 6));
        wait for CLK_PERIOD;

        -- 4. SUBU Unsigned (Op 9/10): 20 - 5 = 15
        tb_data_in1 <= std_logic_vector(to_unsigned(20, 32));
        tb_data_in2 <= std_logic_vector(to_unsigned(5, 32));
        tb_op_sel   <= std_logic_vector(to_unsigned(9, 6));
        wait for CLK_PERIOD;

        ------------------------------------------------------------
        -- LOGICAL
        ------------------------------------------------------------

        -- 5. AND (Op 11/12): 0x0...F0 & 0x0...0F = 0
        tb_data_in1 <= x"000000F0";
        tb_data_in2 <= x"0000000F";
        tb_op_sel   <= std_logic_vector(to_unsigned(11, 6));
        wait for CLK_PERIOD;

        -- 6. OR (Op 13/14): 0x0...F0 | 0x0...0F = 0xFF
        tb_op_sel   <= std_logic_vector(to_unsigned(13, 6));
        wait for CLK_PERIOD;

        -- 7. XOR (Op 15/16): 0x0...FF ^ 0x0...0F = 0xF0
        tb_data_in1 <= x"000000FF";
        tb_data_in2 <= x"0000000F";
        tb_op_sel   <= std_logic_vector(to_unsigned(15, 6));
        wait for CLK_PERIOD;

        ------------------------------------------------------------
        -- SHIFTS
        ------------------------------------------------------------

        -- 8. SLL (Op 17/18): 1 << 2 = 4
        tb_data_in1 <= x"00000001";
        tb_data_in2 <= x"00000002"; -- shift amount
        tb_op_sel   <= std_logic_vector(to_unsigned(17, 6));
        wait for CLK_PERIOD;

        -- 9. SRL (Op 19/20): 4 >> 1 = 2
        tb_data_in1 <= x"00000004";
        tb_data_in2 <= x"00000001";
        tb_op_sel   <= std_logic_vector(to_unsigned(19, 6));
        wait for CLK_PERIOD;

        -- 10. SRA (Op 21/22): -4 (111..00) >> 1 = -2 (111..10)
        tb_data_in1 <= std_logic_vector(to_signed(-4, 32));
        tb_data_in2 <= std_logic_vector(to_unsigned(1, 32));
        tb_op_sel   <= std_logic_vector(to_unsigned(21, 6));
        wait for CLK_PERIOD;

        ------------------------------------------------------------
        -- COMPARISONS
        ------------------------------------------------------------
        -- Setup: A = -10 (0xFFFFFFF6), B = 5
        -- Signed: -10 < 5 (True)
        -- Unsigned: HugeNumber > 5 (True)
        tb_data_in1 <= std_logic_vector(to_signed(-10, 32));
        tb_data_in2 <= std_logic_vector(to_signed(5, 32));

        -- 11. SLT Signed (Op 23/24): -10 < 5 -> 1 (True)
        tb_op_sel <= std_logic_vector(to_unsigned(23, 6));
        wait for CLK_PERIOD;

        -- 12. SLTU Unsigned (Op 25/26): (-10 unsigned) < 5 -> 0 (False)
        tb_op_sel <= std_logic_vector(to_unsigned(25, 6));
        wait for CLK_PERIOD;

        -- 13. SGT Signed (Op 27/28): -10 > 5 -> 0 (False)
        tb_op_sel <= std_logic_vector(to_unsigned(27, 6));
        wait for CLK_PERIOD;

        -- 14. SGTU Unsigned (Op 29/30): (-10 unsigned) > 5 -> 1 (True)
        tb_op_sel <= std_logic_vector(to_unsigned(29, 6));
        wait for CLK_PERIOD;

        -- 15. SLE Signed (Op 31/32): -10 <= 5 -> 1 (True)
        tb_op_sel <= std_logic_vector(to_unsigned(31, 6));
        wait for CLK_PERIOD;

        -- 16. SLEU Unsigned (Op 33/34): (-10 unsigned) <= 5 -> 0 (False)
        tb_op_sel <= std_logic_vector(to_unsigned(33, 6));
        wait for CLK_PERIOD;

         -- 17. SGE Signed (Op 35/36): -10 >= 5 -> 0 (False)
        tb_op_sel <= std_logic_vector(to_unsigned(35, 6));
        wait for CLK_PERIOD;

        -- 18. SGEU Unsigned (Op 37/38): -10 >= 5 -> 1 (True)
        tb_op_sel <= std_logic_vector(to_unsigned(37, 6));
        wait for CLK_PERIOD;
        
        ------------------------------------------------------------
        -- EQUALITY
        ------------------------------------------------------------
        -- Setup: A = 5, B = 5
        tb_data_in1 <= std_logic_vector(to_signed(5, 32));
        tb_data_in2 <= std_logic_vector(to_signed(5, 32));

        -- 19. SEQ (Op 39/40): 5 == 5 -> 1
        tb_op_sel <= std_logic_vector(to_unsigned(39, 6));
        wait for CLK_PERIOD;

        -- 20. SEQI Unsigned equivalent (Op 41/42): 5 == 5 -> 1
        tb_op_sel <= std_logic_vector(to_unsigned(41, 6));
        wait for CLK_PERIOD;

        -- 21. SNE (Op 43/44): 5 != 5 -> 0
        tb_op_sel <= std_logic_vector(to_unsigned(43, 6));
        wait for CLK_PERIOD;

        -- 22. SNE Check True: 5 != 6 -> 1
        tb_data_in2 <= std_logic_vector(to_signed(6, 32));
        tb_op_sel <= std_logic_vector(to_unsigned(43, 6));
        wait for CLK_PERIOD;

		wait;
	end process;
	
end architecture behavioral;
