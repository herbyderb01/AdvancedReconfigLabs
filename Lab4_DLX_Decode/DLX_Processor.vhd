library ieee;
use ieee.std_logic_1164.all;

library work;
use work.fetch_pkg.all;
use work.decode_pkg.all;

entity DLX_Processor is
    generic (
        WIDTH       : integer := 10;
        INSTR_WIDTH : integer := 32
    );
    port (
        clk             : in  std_logic;
        rst             : in  std_logic;
        
        -- Branch/Jump Control (Driven by TB for now/Execute stage later)
        jump_addr_in    : in  std_logic_vector(WIDTH-1 downto 0);
        pc_mux_sel      : in  std_logic;
        
        -- Writeback Interface (Driven by TB for now/Writeback stage later)
        write_addr_in   : in  std_logic_vector(4 downto 0);
        write_data_in   : in  std_logic_vector(31 downto 0);
        write_en_in     : in  std_logic
    );
end entity DLX_Processor;

architecture structural of DLX_Processor is
    signal instruction : std_logic_vector(INSTR_WIDTH-1 downto 0);
    signal pc_inc      : std_logic_vector(WIDTH-1 downto 0);
    signal pc_inc_32   : std_logic_vector(31 downto 0);
    
    -- Decode outputs
    signal rs1_data    : std_logic_vector(31 downto 0);
    signal rs2_data    : std_logic_vector(31 downto 0);
    signal imm32       : std_logic_vector(31 downto 0);
    signal rd_addr     : std_logic_vector(4 downto 0);
    signal pc_out_dec  : std_logic_vector(31 downto 0);

begin

    -- Fetch Stage
    fetch_inst: fetch
        generic map (
            N => WIDTH,
            M => INSTR_WIDTH
        )
        port map (
            jump_addr   => jump_addr_in,
            pc_select   => pc_mux_sel,
            rst         => rst,
            clk         => clk,
            decode_addr => pc_inc,
            instruction => instruction
        );
        
    -- PC Adaptation (Fetch uses N bits, Decode expects 32)
    pc_inc_32(WIDTH-1 downto 0) <= pc_inc;
    
    gen_pc_padding: if WIDTH < 32 generate
        pc_inc_32(31 downto WIDTH) <= (others => '0');
    end generate;

    -- Decode Stage
    decode_inst: decode
        generic map (
            FUNC_WIDTH => 6, 
            ADDR_WIDTH => 5, 
            DATA_WIDTH => 32
        )
        port map (
            clk             => clk,
            rst             => rst,
            instruction     => instruction,
            pc_inc          => pc_inc_32,
            wb_data         => write_data_in,
            wb_addr         => write_addr_in,
            wb_en           => write_en_in,
            rs1_data        => rs1_data,
            rs2_data        => rs2_data,
            sign_ext_imm    => imm32,
            rd_addr_out     => rd_addr,
            pc_inc_out      => pc_out_dec
        );

end architecture structural;
