-- =============================================================================
-- forwarding_unit.vhd  --  Operand forwarding selector (data-hazard control)
-- =============================================================================
-- Header below is the original design comment from Lab 7 -- preserved
-- verbatim as it accurately describes the final-project behavior.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

-- Forwarding Unit
-- Detects RAW (read-after-write) data hazards and selects the correct
-- forwarding source for the Execute stage ALU inputs.
--
-- Forwarding MUX encoding:
--   "00" = no forwarding, use register file output
--   "01" = forward from EX/MEM  (ALU result from Memory stage)
--   "10" = forward from MEM/WB  (write-back data from WriteBack stage)
--
-- Priority: EX/MEM > MEM/WB (more recent result wins)
-- Never forwards to/from R0 (hardwired zero)

entity forwarding_unit is
    port (
        -- Source register addresses of instruction in Execute (ID/EX)
        id_ex_rs1_addr    : in  std_logic_vector(4 downto 0);
        id_ex_rs2_addr    : in  std_logic_vector(4 downto 0);

        -- Destination info from instruction in Memory (EX/MEM)
        ex_mem_rd_addr    : in  std_logic_vector(4 downto 0);
        ex_mem_wb_en      : in  std_logic;

        -- Destination info from instruction in WriteBack (MEM/WB)
        mem_wb_rd_addr    : in  std_logic_vector(4 downto 0);
        mem_wb_wb_en      : in  std_logic;

        -- Forwarding MUX selects
        fwd_a_sel         : out std_logic_vector(1 downto 0);  -- rs1 path
        fwd_b_sel         : out std_logic_vector(1 downto 0)   -- rs2 path
    );
end entity forwarding_unit;

architecture behavioral of forwarding_unit is
begin

    fwd_proc : process(id_ex_rs1_addr, id_ex_rs2_addr,
                       ex_mem_rd_addr, ex_mem_wb_en,
                       mem_wb_rd_addr, mem_wb_wb_en)
    begin
        -- Default: no forwarding
        fwd_a_sel <= "00";
        fwd_b_sel <= "00";

        ---------------------------------------------------------------
        -- MEM/WB forwarding (lower priority — checked first so that
        -- the EX/MEM check below can override it)
        ---------------------------------------------------------------
        if mem_wb_wb_en = '1' and mem_wb_rd_addr /= "00000" then
            if mem_wb_rd_addr = id_ex_rs1_addr then
                fwd_a_sel <= "10";
            end if;
            if mem_wb_rd_addr = id_ex_rs2_addr then
                fwd_b_sel <= "10";
            end if;
        end if;

        ---------------------------------------------------------------
        -- EX/MEM forwarding (higher priority — overrides MEM/WB
        -- when both stages write to the same destination register)
        ---------------------------------------------------------------
        if ex_mem_wb_en = '1' and ex_mem_rd_addr /= "00000" then
            if ex_mem_rd_addr = id_ex_rs1_addr then
                fwd_a_sel <= "01";
            end if;
            if ex_mem_rd_addr = id_ex_rs2_addr then
                fwd_b_sel <= "01";
            end if;
        end if;

    end process fwd_proc;

end architecture behavioral;
