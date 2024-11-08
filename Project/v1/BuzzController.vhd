library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity BuzzController is
    generic(
        clk_freq : integer := 20_000_000);
    port(
        clk                     : in  std_logic;
        reset                   : in  std_logic;
        enable_message_recieved : in  std_logic;
        enable_send_failed      : in  std_logic;
        enable_send_success     : in  std_logic;
        buzzer                  : out std_logic);
end BuzzController;
architecture Behavioral of BuzzController is
    signal buzzer_message_recieved : std_logic;
    signal buzzer_send_failed      : std_logic;
    signal buzzer_send_success     : std_logic;
begin
    message_recieved_pattern_inst : entity work.BuzzPatternParser
        generic map(
            clk_freq     => clk_freq,
            pattern_bits => 10,
            pattern_sec  => 1
        )
        port map(
            clk     => clk,
            reset   => reset,
            enable  => enable_message_recieved,
            pattern => "1100110000",
            buzzer  => buzzer_message_recieved
        );

    send_failed_pattern_inst : entity work.BuzzPatternParser
        generic map(
            clk_freq     => clk_freq,
            pattern_bits => 10,
            pattern_sec  => 1
        )
        port map(
            clk     => clk,
            reset   => reset,
            enable  => enable_send_failed,
            pattern => "1100111100",
            buzzer  => buzzer_send_failed
        );

    send_success_pattern_inst : entity work.BuzzPatternParser
        generic map(
            clk_freq     => clk_freq,
            pattern_bits => 10,
            pattern_sec  => 1
        )
        port map(
            clk     => clk,
            reset   => reset,
            enable  => enable_send_success,
            pattern => "1010100000",
            buzzer  => buzzer_send_success
        );

    buzzer <= buzzer_message_recieved or buzzer_send_failed or buzzer_send_success;
end Behavioral;
