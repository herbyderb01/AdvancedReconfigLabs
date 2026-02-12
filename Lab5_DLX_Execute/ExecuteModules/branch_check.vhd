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