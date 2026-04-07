library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_stc.all;

library work;

entity Timer_counter is
    port ( 
        clk :   in  std_logic;
        
        start   :   in  std_logic;
        rst     :   in  std_logic;
        stop    :   in  std_logic;

        HEX0 : out std_logic_vector(7 downto 0);
    	HEX1 : out std_logic_vector(7 downto 0);
    	HEX2 : out std_logic_vector(7 downto 0);
    	HEX3 : out std_logic_vector(7 downto 0);
    	HEX4 : out std_logic_vector(7 downto 0);
	    HEX5 : out std_logic_vector(7 downto 0);
    );
end Timer_counter;

architecture behavorhial of Timer_counter is

    type state_type is (go, no_go);
    signal state :  state_type := no_go;
    
    signal counter_clock    :   std_logic;
    signal IN_hundreths             :   std_logic_vector(3 downto 0);
    signal IN_tenths              :   std_logic_vector(3 downto 0);
    signal IN_single_seconds             :   std_logic_vector(3 downto 0);
    signal IN_double_seconds              :   std_logic_vector(3 downto 0);
    signal IN_minutes             :   std_logic_vector(3 downto 0);
    signal IN_tens_minutes              :   std_logic_vector(3 downto 0);

    signal counter                  :   std_logic_vector(23 downto 0) := (others => '0');

    signal clock_counter        :   integer := 0;

begin

    Timer_PLL   :   time_pll_1
        port map (
            inclk0 => clk,
            c0 => counter_clock
        );

    HEX_display :   HEX_seven_seg_disp_6
        port map (
            IN0 => IN_hundreths,
            IN1 => IN_tenths,
            IN2 => IN_single_seconds,
            IN3 => IN_double_seconds,
            IN4 => IN_minutes,
            IN5 => IN_tens_minutes,
            clk => counter_clock,
            HEX0 => HEX0,
            HEX1 => HEX1,
            HEX2 => HEX2,
            HEX3 => HEX3,
            HEX4 => HEX4,
            HEX5 => HEX5
        );
    
    process (clk) begin
        if rising_edge(clk) then
            if start = '1' then
                state <= go;
            end if;

            if stop = '1' then
                state <= no_go
            end if;
            
        end if;
    end process

    process (counter_clock) begin
        if rising_edge(counter_clock) then
            if rst = '1' then
                counter <= (others => '0');
            else
                case state is

                    when no_go => 
                        state <= no_go

                    when go => 
                        if clock_counter = 50 then
                            clock_counter <= 0;
                            IN_hundreths <= std_logic_vector(unsigned(IN_hundreths) + 1);
                            
                            if IN_hundreths = "1010" then
                                IN_hundreths <= (others => '0');
                                IN_tenths <= std_logic_vector(unsigned(IN_tenths) + 1);
                            end if;

                            if IN_tenths = "1010" then
                                IN_tenths <= (others => '0');
                                IN_single_seconds <= std_logic_vector(unsigned(IN_single_seconds) + 1);
                            end if;

                            if IN_single_seconds = "1010" then
                                IN_single_seconds <= (others => '0');
                                IN_double_seconds <= std_logic_vector(unsigned(IN_double_seconds) + 1);
                            end if;

                            if IN_double_seconds = "0110" then
                                IN_double_seconds <= (others => '0');
                                IN_minutes <= std_logic_vector(unsigned(IN_minutes) + 1);
                            end if;

                            if IN_minutes = "1010" then
                                IN_minutes <= (others => '0');
                                IN_tens_minutes <= std_logic_vector(unsigned(IN_tens_minutes) + 1);
                            end if;

                            if IN_tens_minutes = "0110" then
                                IN_tens_minutes <= (others => '0');
                            end if;

                end case;
            end if;
        end if;
    end process

end architecture