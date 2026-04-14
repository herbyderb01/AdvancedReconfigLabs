library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Timer_counter is
    port (
        clk   : in  std_logic;  -- 50 MHz
        start : in  std_logic;
        rst   : in  std_logic;
        stop  : in  std_logic;

        HEX0 : out std_logic_vector(7 downto 0);
        HEX1 : out std_logic_vector(7 downto 0);
        HEX2 : out std_logic_vector(7 downto 0);
        HEX3 : out std_logic_vector(7 downto 0);
        HEX4 : out std_logic_vector(7 downto 0);
        HEX5 : out std_logic_vector(7 downto 0)
    );
end Timer_counter;

architecture behavioral of Timer_counter is

    type state_type is (go, no_go);
    signal state : state_type := no_go;

    -- BCD digit signals
    signal IN_hundreths      : std_logic_vector(3 downto 0) := (others => '0');
    signal IN_tenths         : std_logic_vector(3 downto 0) := (others => '0');
    signal IN_single_seconds : std_logic_vector(3 downto 0) := (others => '0');
    signal IN_double_seconds : std_logic_vector(3 downto 0) := (others => '0');
    signal IN_minutes        : std_logic_vector(3 downto 0) := (others => '0');
    signal IN_tens_minutes   : std_logic_vector(3 downto 0) := (others => '0');

    -- 50 MHz / 500000 = 100 Hz (0.01s ticks)
    signal clock_counter : integer range 0 to 499999 := 0;

begin

    HEX_display : entity work.HEX_seven_seg_disp_6
        port map (
            IN0 => IN_hundreths,
            IN1 => IN_tenths,
            IN2 => IN_single_seconds,
            IN3 => IN_double_seconds,
            IN4 => IN_minutes,
            IN5 => IN_tens_minutes,
            clk => clk,
            HEX0 => HEX0,
            HEX1 => HEX1,
            HEX2 => HEX2,
            HEX3 => HEX3,
            HEX4 => HEX4,
            HEX5 => HEX5
        );

    process (clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= no_go;
                clock_counter <= 0;
                IN_hundreths <= (others => '0');
                IN_tenths <= (others => '0');
                IN_single_seconds <= (others => '0');
                IN_double_seconds <= (others => '0');
                IN_minutes <= (others => '0');
                IN_tens_minutes <= (others => '0');
            else
                if start = '1' then
                    state <= go;
                end if;

                if stop = '1' then
                    state <= no_go;
                end if;

                case state is
                    when no_go =>
                        null;

                    when go =>
                        if clock_counter = 499999 then
                            clock_counter <= 0;
                            IN_hundreths <= std_logic_vector(unsigned(IN_hundreths) + 1);

                            if IN_hundreths = "1001" then
                                IN_hundreths <= (others => '0');
                                IN_tenths <= std_logic_vector(unsigned(IN_tenths) + 1);
                            end if;

                            if IN_tenths = "1001" and IN_hundreths = "1001" then
                                IN_tenths <= (others => '0');
                                IN_single_seconds <= std_logic_vector(unsigned(IN_single_seconds) + 1);
                            end if;

                            if IN_single_seconds = "1001" and IN_tenths = "1001" and IN_hundreths = "1001" then
                                IN_single_seconds <= (others => '0');
                                IN_double_seconds <= std_logic_vector(unsigned(IN_double_seconds) + 1);
                            end if;

                            if IN_double_seconds = "0101" and IN_single_seconds = "1001" and IN_tenths = "1001" and IN_hundreths = "1001" then
                                IN_double_seconds <= (others => '0');
                                IN_minutes <= std_logic_vector(unsigned(IN_minutes) + 1);
                            end if;

                            if IN_minutes = "1001" and IN_double_seconds = "0101" and IN_single_seconds = "1001" and IN_tenths = "1001" and IN_hundreths = "1001" then
                                IN_minutes <= (others => '0');
                                IN_tens_minutes <= std_logic_vector(unsigned(IN_tens_minutes) + 1);
                            end if;

                            if IN_tens_minutes = "0101" and IN_minutes = "1001" and IN_double_seconds = "0101" and IN_single_seconds = "1001" and IN_tenths = "1001" and IN_hundreths = "1001" then
                                IN_tens_minutes <= (others => '0');
                            end if;

                        else
                            clock_counter <= clock_counter + 1;
                        end if;

                end case;
            end if;
        end if;
    end process;

end behavioral;
