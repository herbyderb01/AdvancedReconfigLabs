-- =============================================================================
-- branch_check.vhd  --  Branch / jump condition evaluator
-- =============================================================================
-- Pure combinational. Looks at the opcode and the rs1 register value (after
-- forwarding has been applied in execute.vhd) and decides whether the
-- instruction should redirect the PC.
--
-- Conditions:
--   BEQZ (0x2B): take if rs1 == 0
--   BNEZ (0x2C): take if rs1 != 0
--   J    (0x2D): always take (unconditional)
--   JR   (0x2E): always take (target comes from rs2 path in execute.vhd)
--   JAL  (0x2F): always take (also writes PC+1 to R31 in write-back)
--   JALR (0x30): always take (register target + R31 link)
--   anything else: do not branch
--
-- The result (`take_branch`) is registered into branch_out (1 cycle later)
-- and surfaces at the top level as exec_branch_en, which drives flush_raw
-- and the PC-select MUX in fetch.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity branch_check is
	generic(
		ADDR_WIDTH	:	integer := 10
	);
	port(
		addr_in		:	in		std_logic_vector(ADDR_WIDTH-1 downto 0);
		rs1			:	in		std_logic_vector(31 downto 0);
		opcode		:	in 	std_logic_vector(5 downto 0);
		
		take_branch	:	out	std_logic
	);
end entity branch_check;

architecture behavioral of branch_check is
begin
	process(addr_in, rs1, opcode) 
		variable v_opcode	:	integer;
		variable v_rs1		:	integer;
	begin
	
		v_opcode := to_integer(unsigned(opcode));
		v_rs1		:= to_integer(unsigned(rs1));
		
		if(v_opcode = 43) then
			if(v_rs1 = 0) then
				take_branch <= '1';
			else
				take_branch <= '0';
			end if;
		elsif(v_opcode = 44) then
			if(v_rs1 /= 0) then	
				take_branch <= '1';
			else
				take_branch <= '0';
			end if;
		elsif(v_opcode = 45 or v_opcode = 46 or v_opcode = 47 or v_opcode = 48) then
			-- J, JR, JAL, JALR: always take the jump
			take_branch <= '1';
		else
			take_branch <= '0';
		end if;
	end process;
	
end architecture behavioral;