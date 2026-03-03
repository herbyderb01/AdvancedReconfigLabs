library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.register_pkg.all;
use work.MUX_pkg.all;
use work.ripple_adder_pkg.all;
use work.NOP_factorial_ROM_pkg.all;

entity fetch is
	generic	(
		N	:	integer	:= 10;
		M	:	integer	:=	32
	);
	port	(
		jump_addr	:	in		std_logic_vector(N-1 downto 0);
		pc_select	:	in		std_logic;
		stall			:	in		std_logic;
		rst			:	in		std_logic;
		clk			:	in		std_logic;
		decode_addr	:	out	std_logic_vector(N-1 downto 0);
		instruction	:	out	std_logic_vector(M-1 downto 0)
	);
end entity;

architecture component_list of fetch is

	signal	new_addr	:	std_logic_vector(N-1 downto 0) := (others => '0');
	signal	addr		:	std_logic_vector(N-1 downto 0) := (others => '0');
	signal 	sum		:	std_logic_vector(N-1 downto 0) := (others => '0');
	signal 	C_DUMMY	:	std_logic;
	
	-- Stall support: MUXed register inputs
	signal	pc_in				:	std_logic_vector(N-1 downto 0);
	signal	dec_addr_in		:	std_logic_vector(N-1 downto 0);
	signal	decode_addr_int	:	std_logic_vector(N-1 downto 0);
	
	constant LSB_ONE 	: 	std_logic_vector(N-1 downto 0) := 
      (N-2 downto 0 => '0') & '1';
	constant ZERO		: 	std_logic := '0';

begin

	-- Stall MUXes: when stall='1', feed back current values to freeze registers
	pc_in        <= addr             when stall = '1' else new_addr;
	--pc_in <= new_addr; --when stall = '0' else addr; 	 	
	dec_addr_in  <= decode_addr_int  when stall = '1' else new_addr;
	decode_addr  <= decode_addr_int;

	PC_counter	:	entity work.reggi
		generic map(
			N => 10
		)
		port map(
			data_in 	=> pc_in,
			rst 		=>	rst,
			clk		=>	clk,
			data_out	=>	addr
		);
		
	ADDER		:	entity work.ripple_adder
		generic map(
			N => 10
		)
		port map(
			A		=> addr,
			B		=> LSB_ONE,	
			C_in 	=> ZERO,
			SUM	=> sum,
			C_out => C_DUMMY
		);
		
	MUXXY		:	entity work.MUX
		generic map(
			N => 10
		)
		port map(
			A		=>	jump_addr,
			B		=> sum,
			S		=> pc_select,
			OUTPUT=>	new_addr
		);
		
	MUX_REGISTER	:	entity work.reggi
		generic map(
			N => 10
		)
		port map(
			data_in	=> dec_addr_in,
			rst		=>	rst,
			clk		=>	clk,
			data_out	=>	decode_addr_int
		);
		
	--insert IP ROM device with .mif file
	IMEM		:	NOP_factorial_ROM
		port map(
			address	=>	addr,
			clock	=>	clk,
			q		=>	instruction
		);

end architecture component_list;

-- single dummy instruction to fix bug
-- DEPTH = 1024; 
-- WIDTH = 32;
-- ADDRESS_RADIX = HEX;
-- DATA_RADIX = HEX;
-- CONTENT
-- BEGIN

-- 000 : 04200001; --LW    R1, n(R0)
-- 001 : 0CA10000; --ADD   R5, R1, R0

-- 002 : ACA00013; --BEQZ  R5, 03A
-- 003 : 20A50001; --SUBI  R5, R5, 1
-- 004 : ACA00013; --BEQZ  R5, 03A
-- 005 : 0C610000; --ADD   R3, R1, R0

-- 006 : 0C850000; --ADD   R4, R5, R0
-- 007 : 200D0050; --NOP
-- 008 : 20A50001; --SUBI  R5, R5, 1
-- 009 : ACA00015; --BEQZ  R5, 03F
-- 00A : 0C430000; --ADD   R2, R3, R0

-- 00B : BC00000D; --JAL   028
-- 00C : B4000006; --J     016

-- 00D : 0C631000; --ADD   R3, R3, R2
-- 00E : 20840002; --SUBI  R4, R4, 2
-- 00F : B0800011; --BNEZ  R4, 035
-- 010 : BBE00000; --JR    R31

-- 011 : 10840001; --ADDI  R4, R4, 1
-- 012 : B400000D; --J     028

-- 013 : 10600001; --ADDI  R3, R0, 1
-- 014 : B4000015; --J     03F

-- 015 : 08600000; --SW    f(R0), R3

-- 016 : 04200000; --LW    R1, f(R0)

-- END;


--trying not to use a dummy instruction

-- DEPTH = 1024; 
-- WIDTH = 32;
-- ADDRESS_RADIX = HEX;
-- DATA_RADIX = HEX;
-- CONTENT
-- BEGIN

-- 000 : 04200001; --LW    R1, n(R0)
-- 001 : 0CA10000; --ADD   R5, R1, R0

-- 002 : ACA00012; --BEQZ  R5, 039   (old target 02A)
-- 003 : 20A50001; --SUBI  R5, R5, 1
-- 004 : ACA00012; --BEQZ  R5, 039   (old target 02A)
-- 005 : 0C610000; --ADD   R3, R1, R0

-- 006 : 0C850000; --ADD   R4, R5, R0 ; 000011 00100 0
-- 007 : 20A50001; --SUBI  R5, R5, 1
-- 008 : ACA00014; --BEQZ  R5, 03E   (old target 02F)
-- 009 : 0C430000; --ADD   R2, R3, R0

-- 00A : BC00000C; --JAL   027       (old target 01B)
-- 00B : B4000006; --J     015       (old target 00C)

-- 00C : 0C631000; --ADD   R3, R3, R2
-- 00D : 20840002; --SUBI  R4, R4, 2
-- 00E : B0800010; --BNEZ  R4, 034   (old target 025)
-- 00F : BBE00000; --JR    R31

-- 010 : 10840001; --ADDI  R4, R4, 1
-- 011 : B400000C; --J     027       (old target 01B)

-- 012 : 10600001; --ADDI  R3, R0, 1
-- 013 : B4000014; --J     03E       (old target 02F)

-- 014 : 08600000; --SW    f(R0), R3

-- 015 : 04200000; --LW    R1, f(R0)

-- END;


