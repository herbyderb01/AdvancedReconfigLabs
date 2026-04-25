-- =============================================================================
-- register.vhd  --  Generic synchronous N-bit register ("reggi")
-- =============================================================================
-- A simple N-bit edge-triggered flip-flop bank with a synchronous reset. Used
-- everywhere in the pipeline to latch values across stage boundaries.
--
-- Behavior:
--   On rising_edge(clk):
--     if rst = '1' : output <= 0
--     else         : output <= data_in
--
-- Reset is synchronous (sampled at the clock edge). For asynchronous reset see
-- register_async.vhd.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reggi is
	generic	(
		N	:	integer	:= 10
	);
	port	(
		data_in	:	in 	std_logic_vector(N-1 downto 0);
		rst		:	in		std_logic;
		clk		:	in		std_logic;
		data_out	:	out	std_logic_vector(N-1 downto 0)
	);
end entity reggi;

architecture behavioral of reggi is

	signal output_data	:	std_logic_vector(N-1 downto 0)	
	:= (others => '0');

begin

	-- data_out <= output_data;
	-- process(clk) begin 
	-- 	if rst = '1' then
	-- 		output_data <= (others => '0');
	-- 	elsif rising_edge(clk) then
	-- 		output_data <= data_in;
	-- 	end if;
	-- end process;
	data_out <= output_data;
	process(clk) begin
		if rising_edge(clk) then
			if rst = '1' then
				output_data <= (others => '0');
			else
				output_data <= data_in;
			end if;
		end if;
	end process;

end architecture behavioral;