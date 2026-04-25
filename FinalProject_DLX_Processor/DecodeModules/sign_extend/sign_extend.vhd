-- =============================================================================
-- sign_extend.vhd  --  16-to-32 bit sign extension
-- =============================================================================
-- Combinational sign-extender for I-type immediates. The high bit of the
-- 16-bit input is replicated into bits [31:16] of the output. Used in the
-- decode stage to widen instruction[15:0] before it is registered as
-- sign_ext_imm and routed to the ALU mux in execute.
--
-- Branch / jump targets in the DLX ISA are absolute (not PC-relative), so
-- the same sign-extender is used for them too -- the assembler is responsible
-- for placing labels into the immediate field as absolute addresses.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sign_extend is
    port (
        input_data  : in  std_logic_vector(15 downto 0);
        output_data : out std_logic_vector(31 downto 0)
    );
end entity sign_extend;

architecture behavior of sign_extend is
begin
    output_data <= std_logic_vector(resize(signed(input_data), 32));
end architecture behavior;
