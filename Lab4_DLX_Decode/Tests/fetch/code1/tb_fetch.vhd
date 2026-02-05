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

    -- Stimulus process
    stm_process : process
    begin

        

        -- 1. Reset the system
        tb_rst <= '1';
        wait for CLK_PERIOD * 2;
        tb_rst <= '0';
        wait for CLK_PERIOD;

        -- 2. Sequentially fetch a few instructions
        -- PC should increment on each clock cycle
        tb_pc_select <= '0';
        wait for CLK_PERIOD * 5;

        -- 3. Simulate a jump
        -- Set pc_select to '1' and provide a jump address
        tb_pc_select <= '1';
        tb_jump_addr <= "0000001010"; -- Jump to address 10
        wait for CLK_PERIOD;
        
        -- 4. Continue fetching from the new address
        tb_pc_select <= '0';
        wait for CLK_PERIOD * 3;

        wait;
    end process;
    
end architecture behavioral;