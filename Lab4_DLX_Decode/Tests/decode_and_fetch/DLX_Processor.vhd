library ieee;
use ieee.std_logic_1164.all;

library work;
use work.fetch_pkg.all;
--use work.decode_pkg.all;

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
        write_en_in     : in  std_logic;
		  
		  pc_inc				: out	std_logic_vector(WIDTH-1 downto 0);
		  rs1_data			: out	std_logic_vector(INSTR_WIDTH-1 downto 0);
		  rs2_data			: out	std_logic_vector(INSTR_WIDTH-1 downto 0);
		  imm32 				: out std_logic_vector(INSTR_WIDTH-1 downto 0);
		  instruction		: out std_logic_vector(INSTR_WIDTH-1 downto 0)
    );
end entity DLX_Processor;

architecture structural of DLX_Processor is
    -- Decode outputs
    signal rd_addr     : std_logic_vector(4 downto 0);
    signal internal_pc_inc:	std_logic_vector(9 downto 0);
	 signal internal_instr :	std_logic_vector(31 downto 0);

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
            decode_addr => internal_pc_inc,
            instruction => internal_instr
        );

    -- Decode Stage
    decode_inst: entity work.decode
        generic map (
            FUNC_WIDTH => 6, 
            ADDR_WIDTH => 5, 
            DATA_WIDTH => 32
        )
        port map (
            clk             => clk,
            rst             => rst,
            instruction_in  => internal_instr,
            pc_inc          => internal_pc_inc,
            wb_data         => write_data_in,
            wb_addr         => write_addr_in,
            wb_en           => write_en_in,
            rs1_data        => rs1_data,
            rs2_data        => rs2_data,
            sign_ext_imm    => imm32,
            rd_addr_out     => rd_addr,
            pc_inc_out      => pc_inc,
				instruction_out => instruction
        );

end architecture structural;
