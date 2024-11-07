library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity BuzzController is
    generic(
        clk_freq     : integer := 20_000_000;
        pattern_bits : integer := 10;
        pattern_sec  : integer := 1);
    port(
        clk     : in  std_logic;
        enable  : in  std_logic;
        reset   : in  std_logic;
        pattern : in  std_logic_vector(pattern_bits - 1 downto 0);
        buzzer  : out std_logic);
end BuzzController;

architecture Behavioral of BuzzController is
    constant time_per_pattern : integer := clk_freq * pattern_sec;
    constant time_per_bit     : integer := time_per_pattern / pattern_bits;

    signal bit_timer              : integer range 0 to time_per_bit     := 0;
    signal current_bit            : integer range 0 to pattern_bits - 1 := pattern_bits - 1;
    signal internal_buzzer_status : std_logic                           := '0';
    signal latched_enable         : std_logic                           := '0';
begin
    process(clk, reset) is
    begin
        if reset = '1' then
            bit_timer              <= 0;
            current_bit            <= pattern_bits - 1;
            internal_buzzer_status <= '0';
            latched_enable         <= '0';
        elsif rising_edge(clk) then
            if enable = '1' then
                latched_enable <= '1';
            end if;
            if latched_enable = '1' then
                internal_buzzer_status <= pattern(current_bit);
                if bit_timer >= time_per_bit then
                    bit_timer <= 0;
                    if current_bit = 0 then
                        bit_timer              <= 0;
                        current_bit            <= pattern_bits - 1;
                        internal_buzzer_status <= '0';
                        latched_enable         <= '0';
                    else
                        current_bit <= current_bit - 1;
                    end if;
                else
                    bit_timer <= bit_timer + 1;
                end if;
            end if;
        end if;
    end process;
    buzzer <= internal_buzzer_status;
end Behavioral;
