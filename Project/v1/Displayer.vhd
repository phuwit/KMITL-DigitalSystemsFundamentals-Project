library IEEE;
use IEEE.std_logic_1164.all;
use work.globals.all;

entity Displayer is
    generic(
        clk_freq     : integer := 20_000_000;
        message_size : integer := 240;
        display_size : integer := 256);
    port(
        clk           : in  std_logic;
        reset         : in  std_logic;
        current_state : in  states;
        edit_buffer   : in  std_logic_vector(message_size - 1 downto 0);
        last_char     : in  std_logic_vector(7 downto 0);
        char_index    : in  integer range 0 to 29;
        lcd_en        : out std_logic;
        lcd_rs        : out std_logic;
        lcd_rw        : out std_logic;
        lcd_data      : out std_logic_vector(7 downto 0));
end Displayer;

architecture Behavioral of Displayer is
    signal message_formatted : std_logic_vector(display_size - 1 downto 0);
begin
    display_inst : entity work.MessageFormatter
        generic map(
            message_size => message_size,
            display_size => display_size
        )
        port map(
            clk           => clk,
            reset         => reset,
            message_in    => edit_buffer,
            last_char     => last_char,
            char_index    => char_index,
            current_state => current_state,
            message_out   => message_formatted
        );

    lcd_controller_inst : entity work.LcdController
        generic map(
            clk_freq => clk_freq
        )
        port map(
            clk          => clk,
            reset_n      => not reset,
            line1_buffer => message_formatted(display_size - 1 downto display_size / 2),
            line2_buffer => message_formatted((display_size / 2) - 1 downto 0),
            rw           => lcd_rw,
            rs           => lcd_rs,
            e            => lcd_en,
            lcd_data     => lcd_data
        );
end Behavioral;
