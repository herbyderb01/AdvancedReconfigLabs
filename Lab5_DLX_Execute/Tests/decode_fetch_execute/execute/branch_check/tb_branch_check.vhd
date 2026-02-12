library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_branch_check is
end tb_branch_check;

architecture behavioral of tb_branch_check is
    
    component branch_check 
        generic (
            ADDR_WIDTH : integer := 10
        );
        port (
            addr_in     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
            rs1         : in  std_logic_vector(31 downto 0);
            opcode      : in  std_logic_vector(5 downto 0);
            take_branch : out std_logic
        );
    end component branch_check;
    
    signal clk : std_logic;
    constant CLK_PERIOD : time := 10 ns;

    -- Signals
    signal tb_addr_in     : std_logic_vector(9 downto 0) := (others => '0');
    signal tb_rs1         : std_logic_vector(31 downto 0) := (others => '0');
    signal tb_opcode      : std_logic_vector(5 downto 0) := (others => '0');
    signal tb_take_branch : std_logic;
    
begin
    
    uut : branch_check
        generic map (
            ADDR_WIDTH => 10
        )
        port map(
            addr_in     => tb_addr_in,
            rs1         => tb_rs1,
            opcode      => tb_opcode,
            take_branch => tb_take_branch
        );
        
    -- Clock process (not strictly needed for comb logic but good for timing simulation steps)
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
        
        -- Default Initialization
        tb_addr_in <= (others => '0');
        tb_rs1     <= (others => '0');
        tb_opcode  <= (others => '0');
        wait for CLK_PERIOD;

        ------------------------------------------------------------
        -- BEQZ (Opcode 43 / 0x2B)
        ------------------------------------------------------------
        -- Case 1: rs1 == 0 -> Taken
        tb_opcode <= std_logic_vector(to_unsigned(43, 6)); 
        tb_rs1    <= (others => '0');
        wait for CLK_PERIOD;
        -- Check: take_branch should be '1'

        -- Case 2: rs1 != 0 -> Not Taken
        tb_rs1    <= std_logic_vector(to_signed(5, 32));
        wait for CLK_PERIOD;
        -- Check: take_branch should be '0'

        ------------------------------------------------------------
        -- BNEZ (Opcode 44 / 0x2C)
        ------------------------------------------------------------
        -- Case 1: rs1 != 0 -> Taken
        tb_opcode <= std_logic_vector(to_unsigned(44, 6)); 
        tb_rs1    <= std_logic_vector(to_signed(5, 32));
        wait for CLK_PERIOD;
        -- Check: take_branch should be '1'

        -- Case 2: rs1 == 0 -> Not Taken
        tb_rs1    <= (others => '0');
        wait for CLK_PERIOD;
        -- Check: take_branch should be '0'

        ------------------------------------------------------------
        -- Other Opcodes (Should not branch)
        ------------------------------------------------------------
        -- Random Opcode (e.g., ADD 0x03)
        tb_opcode <= std_logic_vector(to_unsigned(3, 6)); 
        tb_rs1    <= (others => '0');
        wait for CLK_PERIOD;
        -- Check: take_branch should be '0'

        -- Another non-branch (e.g., ADDI 0x04)
        tb_opcode <= std_logic_vector(to_unsigned(4, 6));
        tb_rs1    <= std_logic_vector(to_signed(42, 32));
        wait for CLK_PERIOD;
        -- Check: take_branch should be '0'

        ------------------------------------------------------------
        -- UNCONDITIONAL JUMPS (Should always take branch)
        -- rs1 value is irrelevant for unconditional jumps
        ------------------------------------------------------------

        -- J (Opcode 45 / 0x2D): always take
        tb_opcode <= std_logic_vector(to_unsigned(45, 6));
        tb_rs1    <= x"DEADBEEF";
        tb_addr_in <= "0000001000";
        wait for CLK_PERIOD;
        -- Check: take_branch should be '1'

        -- JR (Opcode 46 / 0x2E): always take
        tb_opcode <= std_logic_vector(to_unsigned(46, 6));
        tb_rs1    <= x"00000000";
        wait for CLK_PERIOD;
        -- Check: take_branch should be '1'

        -- JAL (Opcode 47 / 0x2F): always take
        tb_opcode <= std_logic_vector(to_unsigned(47, 6));
        tb_rs1    <= x"FFFFFFFF";
        wait for CLK_PERIOD;
        -- Check: take_branch should be '1'

        -- JALR (Opcode 48 / 0x30): always take
        tb_opcode <= std_logic_vector(to_unsigned(48, 6));
        tb_rs1    <= x"12345678";
        wait for CLK_PERIOD;
        -- Check: take_branch should be '1'

        wait;
    end process;
    
end architecture behavioral;
