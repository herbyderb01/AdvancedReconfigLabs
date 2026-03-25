library ieee;
use ieee.std_logic_1164.all;

library work;
use work.fetch_pkg.all;
use work.decode_reg_pkg.all;

entity DLX_Processor is
    generic (
        WIDTH       : integer := 10;
        INSTR_WIDTH : integer := 32
    );
    port (
        clk             : in  std_logic;
        fifo_full       : in  std_logic;
        rst             : in  std_logic;
        
        fifo_wr 	:	out std_logic;
		fifo_data	:	out std_logic_vector(INSTR_WIDTH-1 downto 0);
		fifo_instr	:	out	std_logic_vector(INSTR_WIDTH-1 downto 0);

        -- Scan (GD/GDU) interface
        scan_data   : in  std_logic_vector(INSTR_WIDTH-1 downto 0);
        scan_ready  : in  std_logic;
        scan_rdreq  : out std_logic
    );
end entity DLX_Processor;

architecture structural of DLX_Processor is
    -- Fetch -> Decode signals
    signal internal_pc_inc  : std_logic_vector(WIDTH-1 downto 0);
    signal internal_instr   : std_logic_vector(INSTR_WIDTH-1 downto 0);
    
    -- Decode -> Execute signals
    signal dec_instruction  : std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal dec_rs1_data     : std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal dec_rs2_data     : std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal dec_imm32        : std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal dec_rd_addr      : std_logic_vector(4 downto 0);
    signal dec_pc_inc       : std_logic_vector(WIDTH-1 downto 0);
    
    -- Execute outputs / feedback
    signal exec_branch_en   : std_logic;
    signal exec_alu_result  : std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal exec_rs2_data    : std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal exec_instr       : std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal exec_rd_addr     : std_logic_vector(4 downto 0);
    signal exec_pc_out      : std_logic_vector(9 downto 0);
    -- signal fifo_wr          : std_logic;
    -- signal fifo_data        : std_logic_vector(DATA_WIDTH-1 downto 0);
    -- signal fifo_instr       : std_logic_vector(DATA_WIDTH-1 downto 0);
    
    -- Jump address derived from Execute
    signal jump_addr        : std_logic_vector(WIDTH-1 downto 0);
    
    -- Memory stage signals
    signal mem_RAM_output   : std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal mem_reg_ALU      : std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal mem_instr_out    : std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal mem_pc_out       : std_logic_vector(9 downto 0);
    
    -- Write-back signals
    signal wb_en            : std_logic;
    signal wb_data          : std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal wb_addr          : std_logic_vector(4 downto 0);

    ---------------------------------------------------------------------------
    -- HAZARD CONTROL SIGNALS
    ---------------------------------------------------------------------------
    -- Stall (load-use hazard + scan wait)
    signal stall_raw        : std_logic;
    signal stall            : std_logic;
    signal scan_stall       : std_logic;
    signal scan_stalling    : std_logic := '0';
    signal scan_releasing   : std_logic := '0'; -- 1-cycle pulse when stall releases
    signal saved_scan_instr : std_logic_vector(INSTR_WIDTH-1 downto 0) := (others => '0');
    signal decode_instr_in  : std_logic_vector(INSTR_WIDTH-1 downto 0);
    
    -- Flush (control hazard — branch/jump taken)
    signal flush_raw        : std_logic;
    signal flush_r1         : std_logic := '0'; -- 1-cycle delayed flush
    signal flush            : std_logic;
    
    ---------------------------------------------------------------------------
    -- FORWARDING SIGNALS
    ---------------------------------------------------------------------------
    signal fwd_a_sel        : std_logic_vector(1 downto 0);
    signal fwd_b_sel        : std_logic_vector(1 downto 0);
    
    -- Source register addresses of instruction in Execute (ID/EX)
    signal id_ex_opcode     : std_logic_vector(5 downto 0);
    signal id_ex_rs1_addr   : std_logic_vector(4 downto 0);
    signal id_ex_rs2_addr   : std_logic_vector(4 downto 0);
    
    -- Destination info from instruction in Memory (EX/MEM)
    signal ex_mem_opcode    : std_logic_vector(5 downto 0);
    signal ex_mem_rd_addr   : std_logic_vector(4 downto 0);
    signal ex_mem_wb_en     : std_logic;

begin

    ---------------------------------------------------------------------------
    -- FLUSH DELAY REGISTER
    -- Branch penalty is 2 cycles (due to ROM address register + pipeline).
    -- flush = branch_en OR delayed_branch_en
    ---------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                flush_r1 <= '0';
            else
                flush_r1 <= flush_raw;
            end if;
        end if;
    end process;
    
    flush_raw <= exec_branch_en;
    flush     <= flush_raw or flush_r1;
    
    -- Scan stall: save-and-replay approach.
    --
    -- When GDU appears in internal_instr (Fetch output), the PC has already
    -- advanced past it (ROM has 1-cycle latency). We save the GDU instruction
    -- and stall until scan_ready='1'. On release, we inject the saved GDU
    -- into the Decode input for one cycle, so it flows through Execute
    -- normally and picks up scan_data via alu_or_scan.
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                scan_stalling <= '0';
                scan_releasing <= '0';
                saved_scan_instr <= (others => '0');
            elsif scan_stalling = '0' and scan_releasing = '0' and
                  (internal_instr(31 downto 26) = OP_GD or
                   internal_instr(31 downto 26) = OP_GDU) then
                -- GDU just appeared — save it and start stalling
                scan_stalling <= '1';
                saved_scan_instr <= internal_instr;
            elsif scan_stalling = '1' and scan_ready = '1' then
                -- User input arrived — release stall, replay GDU next cycle
                scan_stalling <= '0';
                scan_releasing <= '1';
            elsif scan_releasing = '1' then
                -- GDU was replayed into Decode this cycle, done
                scan_releasing <= '0';
            end if;
        end if;
    end process;

    -- Stall only during scan_stalling (waiting for input).
    -- During scan_releasing, stall is OFF so Decode processes the replayed GDU.
    -- Fetch will advance, but that's fine — it was frozen at GDU+1 (NOP).
    scan_stall <= scan_stalling;

    -- MUX Decode input: replay saved GDU during release, else normal Fetch output
    decode_instr_in <= saved_scan_instr when scan_releasing = '1'
                  else internal_instr;

    -- Consume: pulse scan_rdreq when GDU reaches Execute (ID/EX) with data ready.
    -- This happens 1 cycle after scan_releasing (GDU flows Decode → Execute).
    scan_rdreq <= '1' when (id_ex_opcode = OP_GD or id_ex_opcode = OP_GDU)
                           and scan_ready = '1'
                           and flush = '0'
                  else '0';

    -- Stall gated by flush (no stall during flush)
    stall <= (stall_raw and not flush) or fifo_full or scan_stall;
    ---------------------------------------------------------------------------
    -- EXTRACT SOURCE REGISTER ADDRESSES FROM ID/EX INSTRUCTION
    -- (matches decode.vhd extraction logic)
    ---------------------------------------------------------------------------
    id_ex_opcode <= dec_instruction(31 downto 26);
    
    -- rs1: [25:21] for BEQZ/BNEZ (register to test), else [20:16]
    id_ex_rs1_addr <= dec_instruction(25 downto 21)
                        when (id_ex_opcode = OP_BEQZ or id_ex_opcode = OP_BNEZ or
                              id_ex_opcode = OP_PCH or id_ex_opcode = OP_PD or id_ex_opcode = OP_PDU)
                      else dec_instruction(20 downto 16);
    
    -- rs2: [25:21] for SW/JR/JALR, else [15:11]
    id_ex_rs2_addr <= dec_instruction(25 downto 21)
                        when (id_ex_opcode = OP_SW or
                              id_ex_opcode = OP_JR or
                              id_ex_opcode = OP_JALR)
                      else dec_instruction(15 downto 11);

    ---------------------------------------------------------------------------
    -- EXTRACT DESTINATION INFO FROM EX/MEM INSTRUCTION
    -- (matches write_back.vhd logic)
    ---------------------------------------------------------------------------
    ex_mem_opcode <= exec_instr(31 downto 26);
    
    -- Destination register: R31 for JAL/JALR, else [25:21]
    ex_mem_rd_addr <= "11111"
                        when (ex_mem_opcode = OP_JAL or ex_mem_opcode = OP_JALR)
                      else exec_instr(25 downto 21);
    
    -- Write-enable: '0' for NOP, SW, BEQZ, BNEZ, J, JR
    ex_mem_wb_en <= '0' when (ex_mem_opcode = OP_NOP  or
                              ex_mem_opcode = OP_SW   or
                              ex_mem_opcode = OP_BEQZ or
                              ex_mem_opcode = OP_BNEZ or
                              ex_mem_opcode = OP_J    or
                              ex_mem_opcode = OP_JR   or
                              ex_mem_opcode = OP_PCH  or
                              ex_mem_opcode = OP_PD   or
                              ex_mem_opcode = OP_PDU)
                   else '1';

    ---------------------------------------------------------------------------
    -- FORWARDING UNIT
    ---------------------------------------------------------------------------
    fwd_unit: entity work.forwarding_unit
        port map (
            id_ex_rs1_addr  => id_ex_rs1_addr,
            id_ex_rs2_addr  => id_ex_rs2_addr,
            ex_mem_rd_addr  => ex_mem_rd_addr,
            ex_mem_wb_en    => ex_mem_wb_en,
            mem_wb_rd_addr  => wb_addr,
            mem_wb_wb_en    => wb_en,
            fwd_a_sel       => fwd_a_sel,
            fwd_b_sel       => fwd_b_sel
        );

    ---------------------------------------------------------------------------
    -- HAZARD DETECTION UNIT
    ---------------------------------------------------------------------------
    hazard_unit: entity work.hazard_detection
        port map (
            id_ex_instruction => dec_instruction,
            if_id_instruction => internal_instr,
            branch_en         => exec_branch_en,
            stall             => stall_raw,
            flush             => open  -- we compute flush separately with delay
        );

    ---------------------------------------------------------------------------
    -- FETCH STAGE
    ---------------------------------------------------------------------------
    fetch_inst: fetch
        generic map (
            N => WIDTH,
            M => INSTR_WIDTH
        )
        port map (
            jump_addr   => jump_addr,
            pc_select   => exec_branch_en,
            stall       => stall,
            rst         => rst,
            clk         => clk,
            decode_addr => internal_pc_inc,
            instruction => internal_instr
        );

    ---------------------------------------------------------------------------
    -- DECODE STAGE
    ---------------------------------------------------------------------------
    decode_inst: entity work.decode
        generic map (
            FUNC_WIDTH => 6, 
            ADDR_WIDTH => 5, 
            DATA_WIDTH => 32
        )
        port map (
            clk             => clk,
            rst             => rst,
            stall           => stall,
            flush           => flush,
            instruction_in  => decode_instr_in,
            pc_inc          => internal_pc_inc,
            wb_data         => wb_data,
            wb_addr         => wb_addr,
            wb_en           => wb_en,
            rs1_data        => dec_rs1_data,
            rs2_data        => dec_rs2_data,
            sign_ext_imm    => dec_imm32,
            rd_addr_out     => dec_rd_addr,
            pc_inc_out      => dec_pc_inc,
            instruction_out => dec_instruction
        );

    ---------------------------------------------------------------------------
    -- EXECUTE STAGE
    ---------------------------------------------------------------------------
    execute_inst: entity work.execute
        generic map (
            DATA_WIDTH => INSTR_WIDTH,
            PC_WIDTH   => WIDTH
        )
        port map (
            clk             => clk,
            rst             => rst,
            instruction     => dec_instruction,
            pc_inc          => dec_pc_inc,
            rs1_data        => dec_rs1_data,
            rs2_data        => dec_rs2_data,
            sign_ext_imm    => dec_imm32,
            rd_addr_in      => dec_rd_addr,
            -- Hazard control
            flush           => flush,
            -- Scan data
            scan_data       => scan_data,
            -- Forwarding
            fwd_a_sel       => fwd_a_sel,
            fwd_b_sel       => fwd_b_sel,
            ex_mem_alu_data => exec_alu_result,
            mem_wb_data     => wb_data,
            -- Outputs
            fifo_wr         => fifo_wr,
            fifo_data       => fifo_data,
            fifo_instr      => fifo_instr,
            Branch_en       => exec_branch_en,
            ALU_result      => exec_alu_result,
            rs2_data_out    => exec_rs2_data,
            instr_out       => exec_instr,
            rd_addr_out     => exec_rd_addr,
            pc_out          => exec_pc_out,
            jump_addr       => jump_addr
        );
    
        
    ---------------------------------------------------------------------------
    -- MEMORY STAGE
    ---------------------------------------------------------------------------
    memory_inst: entity work.memory
        generic map(
            DATA_WIDTH => INSTR_WIDTH
        )
        port map(
            clk         => clk,
            rst         => rst,
            pc_inc      => exec_pc_out,
            instruction => exec_instr,
            ALU_result  => exec_alu_result,
            rs2_data    => exec_rs2_data,
            RAM_output  => mem_RAM_output,
            reg_ALU     => mem_reg_ALU,
            instr_out   => mem_instr_out,
            pc_out      => mem_pc_out
        );
    
    ---------------------------------------------------------------------------
    -- WRITE-BACK STAGE
    ---------------------------------------------------------------------------
    write_back_inst: entity work.write_back
        generic map(
            DATA_WIDTH => INSTR_WIDTH
        )
        port map(
            RAM_output  => mem_RAM_output,
            reg_ALU     => mem_reg_ALU,
            pc_inc      => mem_pc_out,
            instruction => mem_instr_out,
            wb_en       => wb_en,
            wb_data     => wb_data,
            wb_addr     => wb_addr 
        );

end architecture structural;
