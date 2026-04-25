-- =============================================================================
-- decode_reg.vhd  --  32 x 32 register file
-- =============================================================================
-- The DLX general-purpose register bank. Lives in the Decode stage. Two
-- synchronous read ports and one synchronous write port.
--
-- R0 is hardwired to zero on read (write to R0 is also blocked at the write
-- step by `unsigned(reg_write_addr) /= 0`).
--
-- Same-cycle write-then-read bypass:
--     If a write and a read happen on the same clock edge AND the addresses
--     match AND reg_write_en = '1', the read returns the new write data.
--     The `reg_write_en` check is essential -- without it, a non-writing
--     instruction (SW, BEQZ, J, PCH, ...) sitting in WB whose [25:21] field
--     happens to alias a source register being read will leak its ALU result
--     onto rs1/rs2. This was the root cause of the "needs 4 NOPs after every
--     instruction" symptom early in the project.
-- =============================================================================

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
				-- Bypass: forward write data when writing and addresses match
            elsif reg_write_en = '1' and reg_read_addr1 = reg_write_addr then
					 reg_read_data1 <= reg_write_data;
				else
                reg_read_data1 <= registers(to_integer(unsigned(reg_read_addr1)));
            end if;

            if unsigned(reg_read_addr2) = 0 then
                reg_read_data2 <= (others => '0');
				-- Bypass: forward write data when writing and addresses match
            elsif reg_write_en = '1' and reg_read_addr2 = reg_write_addr then
					 reg_read_data2 <= reg_write_data;
				else
                reg_read_data2 <= registers(to_integer(unsigned(reg_read_addr2)));
            end if;
        end if;
    end process;

end architecture behavior;
