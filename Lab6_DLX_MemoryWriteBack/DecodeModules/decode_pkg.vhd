library ieee;
use ieee.std_logic_1164.all;

package decode_pkg is
    component decode is
        generic (
            FUNC_WIDTH : integer := 6;
            ADDR_WIDTH : integer := 5;
            DATA_WIDTH : integer := 32
        );
        port (
            clk             : in  std_logic;
            rst             : in  std_logic;
            
            -- From Fetch
            instruction     : in  std_logic_vector(31 downto 0);
            pc_inc          : in  std_logic_vector(31 downto 0);
            
            -- From Writeback
            wb_data         : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            wb_addr         : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
            wb_en           : in  std_logic;
            
            -- To Execute
            rs1_data        : out std_logic_vector(DATA_WIDTH-1 downto 0);
            rs2_data        : out std_logic_vector(DATA_WIDTH-1 downto 0);
            sign_ext_imm    : out std_logic_vector(31 downto 0);
            rd_addr_out     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
            pc_inc_out      : out std_logic_vector(31 downto 0)
        );
    end component;
end package decode_pkg;
