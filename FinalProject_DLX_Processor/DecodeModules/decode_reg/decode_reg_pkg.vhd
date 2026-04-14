library ieee;
use ieee.std_logic_1164.all;

package decode_reg_pkg is

    -- DLX Instruction Opcodes
    constant OP_NOP   : std_logic_vector(5 downto 0) := "000000"; -- 0x00
    constant OP_LW    : std_logic_vector(5 downto 0) := "000001"; -- 0x01
    constant OP_SW    : std_logic_vector(5 downto 0) := "000010"; -- 0x02
    constant OP_ADD   : std_logic_vector(5 downto 0) := "000011"; -- 0x03
    constant OP_ADDI  : std_logic_vector(5 downto 0) := "000100"; -- 0x04
    constant OP_ADDU  : std_logic_vector(5 downto 0) := "000101"; -- 0x05
    constant OP_ADDUI : std_logic_vector(5 downto 0) := "000110"; -- 0x06
    constant OP_SUB   : std_logic_vector(5 downto 0) := "000111"; -- 0x07
    constant OP_SUBI  : std_logic_vector(5 downto 0) := "001000"; -- 0x08
    constant OP_SUBU  : std_logic_vector(5 downto 0) := "001001"; -- 0x09
    constant OP_SUBUI : std_logic_vector(5 downto 0) := "001010"; -- 0x0A
    constant OP_AND   : std_logic_vector(5 downto 0) := "001011"; -- 0x0B
    constant OP_ANDI  : std_logic_vector(5 downto 0) := "001100"; -- 0x0C
    constant OP_OR    : std_logic_vector(5 downto 0) := "001101"; -- 0x0D
    constant OP_ORI   : std_logic_vector(5 downto 0) := "001110"; -- 0x0E
    constant OP_XOR   : std_logic_vector(5 downto 0) := "001111"; -- 0x0F
    constant OP_XORI  : std_logic_vector(5 downto 0) := "010000"; -- 0x10
    constant OP_SLL   : std_logic_vector(5 downto 0) := "010001"; -- 0x11
    constant OP_SLLI  : std_logic_vector(5 downto 0) := "010010"; -- 0x12
    constant OP_SRL   : std_logic_vector(5 downto 0) := "010011"; -- 0x13
    constant OP_SRLI  : std_logic_vector(5 downto 0) := "010100"; -- 0x14
    constant OP_SRA   : std_logic_vector(5 downto 0) := "010101"; -- 0x15
    constant OP_SRAI  : std_logic_vector(5 downto 0) := "010110"; -- 0x16
    constant OP_SLT   : std_logic_vector(5 downto 0) := "010111"; -- 0x17
    constant OP_SLTI  : std_logic_vector(5 downto 0) := "011000"; -- 0x18
    constant OP_SLTU  : std_logic_vector(5 downto 0) := "011001"; -- 0x19
    constant OP_SLTUI : std_logic_vector(5 downto 0) := "011010"; -- 0x1A
    constant OP_SGT   : std_logic_vector(5 downto 0) := "011011"; -- 0x1B
    constant OP_SGTI  : std_logic_vector(5 downto 0) := "011100"; -- 0x1C
    constant OP_SGTU  : std_logic_vector(5 downto 0) := "011101"; -- 0x1D
    constant OP_SGTUI : std_logic_vector(5 downto 0) := "011110"; -- 0x1E
    constant OP_SLE   : std_logic_vector(5 downto 0) := "011111"; -- 0x1F
    constant OP_SLEI  : std_logic_vector(5 downto 0) := "100000"; -- 0x20
    constant OP_SLEU  : std_logic_vector(5 downto 0) := "100001"; -- 0x21
    constant OP_SLEUI : std_logic_vector(5 downto 0) := "100010"; -- 0x22
    constant OP_SGE   : std_logic_vector(5 downto 0) := "100011"; -- 0x23
    constant OP_SGEI  : std_logic_vector(5 downto 0) := "100100"; -- 0x24
    constant OP_SGEU  : std_logic_vector(5 downto 0) := "100101"; -- 0x25
    constant OP_SGEUI : std_logic_vector(5 downto 0) := "100110"; -- 0x26
    constant OP_SEQ   : std_logic_vector(5 downto 0) := "100111"; -- 0x27
    constant OP_SEQI  : std_logic_vector(5 downto 0) := "101000"; -- 0x28
    constant OP_SNE   : std_logic_vector(5 downto 0) := "101001"; -- 0x29
    constant OP_SNEI  : std_logic_vector(5 downto 0) := "101010"; -- 0x2A
    constant OP_BEQZ  : std_logic_vector(5 downto 0) := "101011"; -- 0x2B
    constant OP_BNEZ  : std_logic_vector(5 downto 0) := "101100"; -- 0x2C
    constant OP_J     : std_logic_vector(5 downto 0) := "101101"; -- 0x2D
    constant OP_JR    : std_logic_vector(5 downto 0) := "101110"; -- 0x2E
    constant OP_JAL   : std_logic_vector(5 downto 0) := "101111"; -- 0x2F
    constant OP_JALR  : std_logic_vector(5 downto 0) := "110000"; -- 0x30
    constant OP_PCH   : std_logic_vector(5 downto 0) := "110001"; -- 0x31
    constant OP_PD   : std_logic_vector(5 downto 0) := "110010"; -- 0x32
    constant OP_PDU   : std_logic_vector(5 downto 0) := "110011"; -- 0x33
    constant OP_GD    : std_logic_vector(5 downto 0) := "110100"; -- 0x34
    constant OP_GDU   : std_logic_vector(5 downto 0) := "110101"; -- 0x35
    constant OP_TR    : std_logic_vector(5 downto 0) := "110110"; -- 0x36
    constant OP_TGO   : std_logic_vector(5 downto 0) := "110111"; -- 0x37
    constant OP_TSP   : std_logic_vector(5 downto 0) := "111000"; -- 0x38
    component decode_reg is
        generic (
            DATA_WIDTH : integer := 32;
            ADDR_WIDTH : integer := 5
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
    end component;
end package decode_reg_pkg;
