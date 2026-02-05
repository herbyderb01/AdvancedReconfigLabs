library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fetch_decode is
end tb_fetch_decode;

architecture behavioral of tb_fetch_decode is
    
    component DLX_Processor 
    generic (
        WIDTH       : integer := 10;
        INSTR_WIDTH : integer := 32
    );
    port (
        clk             : in  std_logic;
        rst             : in  std_logic;
        
        -- Branch/Jump Control
        jump_addr_in    : in  std_logic_vector(WIDTH-1 downto 0);
        pc_mux_sel      : in  std_logic;
        
        -- Writeback Interface
        write_addr_in   : in  std_logic_vector(4 downto 0);
        write_data_in   : in  std_logic_vector(31 downto 0);
        write_en_in     : in  std_logic;
		  
		  pc_inc				: out	std_logic_vector(WIDTH-1 downto 0);
		  rs1_data			: out	std_logic_vector(INSTR_WIDTH-1 downto 0);
		  rs2_data			: out	std_logic_vector(INSTR_WIDTH-1 downto 0);
		  imm32 				: out std_logic_vector(INSTR_WIDTH-1 downto 0);
		  instruction		: out std_logic_vector(INSTR_WIDTH-1 downto 0)
    );
    end component DLX_Processor;
    
    -- Clock
    signal clk : std_logic;
    constant CLK_PERIOD : time := 10 ns;

    -- Testbench signals
    signal tb_jump_addr : std_logic_vector(9 downto 0) := (others => '0');
    signal tb_pc_select : std_logic := '0';
    signal tb_rst : std_logic := '1';
    
    -- Writeback signals
    signal tb_wb_addr   : std_logic_vector(4 downto 0) := (others => '0');
    signal tb_wb_data   : std_logic_vector(31 downto 0) := (others => '0');
    signal tb_wb_en     : std_logic := '0';
    
    -- Outputs
    signal tb_pc_inc      : std_logic_vector(9 downto 0);
    signal tb_rs1_data    : std_logic_vector(31 downto 0);
    signal tb_rs2_data    : std_logic_vector(31 downto 0);
    signal tb_imm32       : std_logic_vector(31 downto 0);
    signal tb_instruction : std_logic_vector(31 downto 0);

begin
    
    -- Instantiate the DLX Processor
    uut : DLX_Processor
        generic map (
            WIDTH => 10,
            INSTR_WIDTH => 32
        )
        port map(
            clk             => clk,
            rst             => tb_rst,
            jump_addr_in    => tb_jump_addr,
            pc_mux_sel      => tb_pc_select,
            write_addr_in   => tb_wb_addr,
            write_data_in   => tb_wb_data,
            write_en_in     => tb_wb_en,
            pc_inc          => tb_pc_inc,
            rs1_data        => tb_rs1_data,
            rs2_data        => tb_rs2_data,
            imm32           => tb_imm32,
            instruction     => tb_instruction
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
        -- 0. Initialize Signals
        tb_wb_en <= '0';
        tb_wb_addr <= (others => '0');
        tb_wb_data <= (others => '0');

        -- 1. Reset the system to start at address 0
        tb_rst <= '1';
        wait for CLK_PERIOD * 2;
        tb_rst <= '0';
        wait for CLK_PERIOD;

        -- 2. Fetch instructions 0x000 through 0x004.
        -- 000: LW R5, n(R0)
        tb_pc_select <= '0';
        wait for CLK_PERIOD; 
        
        -- SIMULATE WB: Instr 0 (LW R5) -> Load n=3 into R5
        tb_wb_en <= '1'; tb_wb_addr <= "00101"; tb_wb_data <= x"00000003";
        wait for CLK_PERIOD; -- 001: ADDI R4, R0, 1
        
        -- SIMULATE WB: Instr 1 (ADDI R4) -> R4 = 1
        tb_wb_addr <= "00100"; tb_wb_data <= x"00000001";
        wait for CLK_PERIOD; -- 002: SW R4, f(R0)
        tb_wb_en <= '0'; -- Turn off WB for SW (no WB)
        
        wait for CLK_PERIOD; -- 003: ADDI R7, R5, -1
        
        -- SIMULATE WB: Instr 3 (ADDI R7) -> R7 = 3 - 1 = 2
        tb_wb_en <= '1'; tb_wb_addr <= "00111"; tb_wb_data <= x"00000002"; 
        wait for CLK_PERIOD; -- 004: BEQZ R7, done
        tb_wb_en <= '0';

        wait for CLK_PERIOD;

        -- 3. At PC=0x005, instruction is JAL factorial (0x008). Jump there.
        -- The JAL instruction works by jumping AND writing PC+1 to R31.
        -- We must simulate the Writeback of R31 here so JR R31 works later.
        -- PC is 5, so Return Addr is 6.
        tb_pc_select <= '1';
        tb_jump_addr <= "0000001000"; -- Jump to address 0x008
        
        -- SIMULATE WB: Instr 5 (JAL) -> R31 = 6
        tb_wb_en <= '1'; tb_wb_addr <= "11111"; tb_wb_data <= x"00000006";
        wait for CLK_PERIOD;
        tb_pc_select <= '0';
        tb_wb_en <= '0';
        wait for CLK_PERIOD;

        -- 4. Fetch 0x008, 0x009, 0x00A, 0x00B.
        -- 008: LW R6, f(R0) --> Load recursive result. Say 2.
        wait for CLK_PERIOD;
        
        -- SIMULATE WB: Instr 8 (LW R6) -> R6 = 2
        tb_wb_en <= '1'; tb_wb_addr <= "00110"; tb_wb_data <= x"00000002";
        wait for CLK_PERIOD; -- 009: ADD R8, R0, R5 (R5 is 3).
        
        -- SIMULATE WB: Instr 9 (ADD R8) -> R8 = 3
        tb_wb_addr <= "01000"; tb_wb_data <= x"00000003";
        wait for CLK_PERIOD; -- 00A: ADDI R3, R0, 0
        
        -- SIMULATE WB: Instr 10 (ADDI R3) -> R3 = 0
        tb_wb_addr <= "00011"; tb_wb_data <= x"00000000";
        wait for CLK_PERIOD; -- 00B: ADD R3, R3, R6 (R3=0, R6=2)
        tb_wb_en <= '0';

        -- 5. At PC=0x00C, instruction is SUBI R8, R8, 1.
        -- SIMULATE WB: Instr 11 (ADD R3) -> R3 = 2
        tb_wb_en <= '1';
        tb_wb_addr <= "00011"; -- Write to R3
        tb_wb_data <= x"00000002"; 
        
        wait for CLK_PERIOD;
        tb_wb_en <= '0';

        -- 6. At PC=0x00D, instruction is BNEZ R8. 
        -- R8 is currently 3 (set at step 4). It is NOT zero, so branch taken.
        tb_pc_select <= '1';
        tb_jump_addr <= "0000001011"; -- Jump to address 0x00B
        wait for CLK_PERIOD;
        tb_pc_select <= '0';
        wait for CLK_PERIOD;

        -- 7. We are back at 0x00B. Fetch 0x00B, 0x00C.
        -- SIMULATE WB: Instr 12 (SUBI R8) -> R8 = 3 - 1 = 2
        tb_wb_en <= '1'; tb_wb_addr <= "01000"; tb_wb_data <= x"00000002";
        
        wait for CLK_PERIOD * 2;
        tb_wb_en <= '0';

        -- 8. At PC=0x00D, BNEZ R8. R8 is 2. Branch Taken again usually, but for test we say NOT taken.
        wait for CLK_PERIOD;

        -- 9. At PC=0x00E, instruction is SW. Fetch it.
        wait for CLK_PERIOD;

        -- 10. At PC=0x00F, instruction is JR R31. 
        -- R31 should have 6 from our JAL shim earlier.
        tb_pc_select <= '1';
        tb_jump_addr <= "0000000110"; -- Jump to address 0x006
        wait for CLK_PERIOD;
        tb_pc_select <= '0';
        wait for CLK_PERIOD;

        -- 11. At PC=0x006, instruction is SUBI R5, R5, 1.
        -- R5 was 3.
        wait for CLK_PERIOD;

        -- 12. At PC=0x007, instruction is J loop (0x004). Jump there.
        tb_pc_select <= '1';
        tb_jump_addr <= "0000000100"; -- Jump to address 0x004
        wait for CLK_PERIOD;
        tb_pc_select <= '0';
        wait for CLK_PERIOD;

        -- 13. At PC=0x004, BEQZ R7. R7 is 2. Not taken usually.
        -- But we force jump to done (0x010).
        tb_pc_select <= '1';
        tb_jump_addr <= "0000010000"; -- Jump to address 0x010
        wait for CLK_PERIOD;
        tb_pc_select <= '0';
        wait for CLK_PERIOD;
        
        -- 14. At PC=0x010, instruction is J done (itself). Fetch it.
        wait for CLK_PERIOD * 2;

        wait;
    end process;
    
end architecture behavioral;