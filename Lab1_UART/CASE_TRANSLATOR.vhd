library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This module translates lowercase ASCII letters to uppercase, or uppercase to lowercase.
-- If there are non-alphabetic characters, an "E" is passed through.

-- There is a FiFo internally instantiated in this module, so when data is the data is translated, it then stored in the FiFo. When data is available in the FIFO, empty is set low and can be read out.

entity CASE_TRANSLATOR is
	port 
	(
		--input bits--
		wrclk : in std_logic;
		rdclk : in std_logic;

		data_in: in std_logic_vector(7 downto 0); -- Data to be translated
		
		translate_req: in std_logic;  -- Signal to start translation when RX_UART's wrreq is high
		read_req: in std_logic;       -- Signal to read from FIFO coming form TX_UART
		
		--output bits--
		data_out: out std_logic_vector(7 downto 0); -- Translated data

		empty: out std_logic -- Signal to indicate if FIFO is empty
	);
end entity CASE_TRANSLATOR;

architecture component_list of CASE_TRANSLATOR is

	component FIFO
		PORT
		(
			data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
			rdclk		: IN STD_LOGIC ;
			rdreq		: IN STD_LOGIC ;
			wrclk		: IN STD_LOGIC ;
			wrreq		: IN STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
			rdempty		: OUT STD_LOGIC 
		);
	end COMPONENT;

	signal translated_data : std_logic_vector(7 downto 0);
	variable char_code : integer range 0 to 255;
	signal fifo_write_req : std_logic := '0';
	
begin

	-- Translation Logic
	fifo_write_req <= '0';
	process(translate_req)
		if rising_edge(translate_req) then
				
			char_code := to_integer(unsigned(data_in));
			
			if (char_code >= 97 and char_code <= 122) then -- Lowercase 'a' to 'z'
				-- Convert to Uppercase
				translated_data <= std_logic_vector(to_unsigned(char_code - 32, 8));
			elsif (char_code >= 65 and char_code <= 90) then -- Uppercase 'A' to 'Z'
				-- Convert to Lowercase
				translated_data <= std_logic_vector(to_unsigned(char_code + 32, 8));
			else
				translated_data <= x"45"; -- 'E'
			end if;

			fifo_write_req <= '1';
				
		end if;
	end process;
	
	-- FIFO Instantiation
	fifo_inst : FIFO
	PORT MAP
	(
		data		=> translated_data,
		rdclk		=> rdclk,
		rdreq		=> read_req,
		wrclk		=> wrclk,
		wrreq		=> fifo_write_req,
		q		=> data_out,
		rdempty		=> empty
	);
	
end architecture component_list;