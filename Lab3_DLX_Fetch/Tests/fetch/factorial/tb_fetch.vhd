library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fetch is
end tb_fetch;

architecture behavioral of tb_fetch is
    
    component fetch 
        generic (
            N	:	integer	:= 10;
            M	:	integer	:=	32
        );
        port (
            jump_addr	:	in		std_logic_vector(N-1 downto 0);
            pc_select	:	in		std_logic;
            rst			:	in		std_logic;
            clk			:	in		std_logic;
            decode_addr	:	out	std_logic_vector(N-1 downto 0);
            instruction	:	out	std_logic_vector(M-1 downto 0)
        );
    end component fetch;
    
    -- Clock
    signal clk : std_logic;
    constant CLK_PERIOD : time := 10 ns;

    -- Testbench signals
    signal tb_jump_addr : std_logic_vector(9 downto 0) := (others => '0');
    signal tb_pc_select : std_logic := '0';
    signal tb_rst : std_logic := '1';
    signal tb_decode_addr : std_logic_vector(9 downto 0);
    signal tb_instruction : std_logic_vector(31 downto 0);

begin
    
    -- Instantiate the fetch stage
    uut : fetch
        generic map (
            N => 10,
            M => 32
        )
        port map(
            jump_addr   => tb_jump_addr,
            pc_select   => tb_pc_select,
            rst         => tb_rst,
            clk         => clk,
            decode_addr => tb_decode_addr,
            instruction => tb_instruction
        );
        
    -- Clock process
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus process for factorial program
    stm_process : process
    begin
        -- 1. Reset the system to start at address 0
        tb_rst <= '1';
        wait for CLK_PERIOD * 2;
        tb_rst <= '0';
        wait for CLK_PERIOD;

        -- 2. Fetch instructions 0x000 through 0x004. At 0x004 (BEQZ), assume branch not taken.
        tb_pc_select <= '0';
        wait for CLK_PERIOD * 5;

        -- 3. At PC=0x005, instruction is JAL factorial (0x009). Jump there.
        tb_pc_select <= '1';
        tb_jump_addr <= "0000001001"; -- Jump to address 0x009
        wait for CLK_PERIOD;
        tb_pc_select <= '0';
        wait for CLK_PERIOD;

        -- 4. Fetch 0x009, 0x00A, 0x00B.
        wait for CLK_PERIOD * 3;

        -- 5. At PC=0x00C, instruction is SUBI. Fetch it.
        wait for CLK_PERIOD;

        -- 6. At PC=0x00D, instruction is BNEZ multiply_loop (0x00B). Simulate branch taken.
        tb_pc_select <= '1';
        tb_jump_addr <= "0000001011"; -- Jump to address 0x00B
        wait for CLK_PERIOD;
        tb_pc_select <= '0';
        wait for CLK_PERIOD;

        -- 7. We are back at 0x00B. Fetch 0x00B, 0x00C.
        wait for CLK_PERIOD * 2;

        -- 8. At PC=0x00D, BNEZ again. This time, simulate branch NOT taken.
        wait for CLK_PERIOD;

        -- 9. At PC=0x00E, instruction is SW. Fetch it.
        wait for CLK_PERIOD;

        -- 10. At PC=0x00F, instruction is JR R31. Return address was 0x005+1=0x006. Jump there.
        tb_pc_select <= '1';
        tb_jump_addr <= "0000000110"; -- Jump to address 0x006
        wait for CLK_PERIOD;
        tb_pc_select <= '0';
        wait for CLK_PERIOD;

        -- 11. At PC=0x006, instruction is SUBI. Fetch it.
        wait for CLK_PERIOD;

        -- 12. At PC=0x007, instruction is J loop (0x004). Jump there.
        tb_pc_select <= '1';
        tb_jump_addr <= "0000000100"; -- Jump to address 0x004
        wait for CLK_PERIOD;
        tb_pc_select <= '0';
        wait for CLK_PERIOD;

        -- 13. At PC=0x004, BEQZ again. This time, simulate branch TAKEN to 'done' (0x010).
        tb_pc_select <= '1';
        tb_jump_addr <= "00010000"; -- Jump to address 0x010
        wait for CLK_PERIOD;
        tb_pc_select <= '0';
        wait for CLK_PERIOD;
        
        -- 14. At PC=0x010, instruction is J done (itself). Fetch it.
        wait for CLK_PERIOD * 2;

        wait;
    end process;
    
end architecture behavioral;