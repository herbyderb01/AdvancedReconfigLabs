library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decode_reg is
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
end entity decode_reg;

architecture behavior of decode_reg is
    type reg_array_type is array (0 to 2**ADDR_WIDTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal registers : reg_array_type := (others => (others => '0'));
begin

    
    -- Write Process (Synchronous)
    process(clk, rst)
    begin
        if rst = '1' then
            registers <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if reg_write_en = '1' and unsigned(reg_write_addr) /= 0 then
                registers(to_integer(unsigned(reg_write_addr))) <= reg_write_data;
            end if;
            -- Read Process (synchronous)
            if unsigned(reg_read_addr1) = 0 then
                reg_read_data1 <= (others => '0');
				--checks if wr_en is on and outputs new data if it matches write address
            elsif reg_read_addr1 /= reg_write_addr and reg_write_en = '1' then 
                reg_read_data1 <= registers(to_integer(unsigned(reg_read_addr1)));
				else
					 reg_read_data1 <= reg_write_data;
            end if;
            
            if unsigned(reg_read_addr2) = 0 then
                reg_read_data2 <= (others => '0');
				--checks if wr_en is on and outputs new data if it matches write address
            elsif reg_read_addr2 /= reg_write_data and reg_write_en = '1' then 
                reg_read_data2 <= registers(to_integer(unsigned(reg_read_addr2)));
				else 
					 reg_read_data2 <= reg_write_data;
            end if;
        end if;
    end process;

end architecture behavior;
