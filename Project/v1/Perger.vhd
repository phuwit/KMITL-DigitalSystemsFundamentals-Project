library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globals.all;

entity Perger is
    port(
        clk      : in  std_logic;
        btn      : in  std_logic_vector(6 downto 1);
        sw       : in  std_logic_vector(6 downto 0);
        dipsw    : in  std_logic_vector(8 downto 1);
        bt_rx    : in  std_logic;       -- fpga's rx <-> bluetooth's tx
        bt_state : in  std_logic;
        led      : out std_logic_vector(7 downto 0);
        mn       : out std_logic_vector(7 downto 0);
        lcd_en   : out std_logic;
        lcd_rs   : out std_logic;
        lcd_rw   : out std_logic;
        lcd_data : out std_logic_vector(7 downto 0);
        bt_tx    : out std_logic;       -- fpga's tx <-> bluetooth's rx
        buzzer   : out std_logic
    );
end Perger;

architecture Behavioral of Perger is
    constant clk_freq       : integer := 20_000_000;
    constant bluetooth_baud : integer := 115_200;
    constant message_size   : integer := 240;
    constant display_size   : integer := 256;

    -- สัญญาณภายในสำหรับการสื่อสารระหว่างโมดูล
    signal btn_pulse       : std_logic_vector(btn'length downto 1);
    signal sw_debounced    : std_logic_vector(sw'length - 1 downto 0);
    signal dipsw_debounced : std_logic_vector(dipsw'length downto 1);

    signal current_state    : states;
    signal edit_buffer      : std_logic_vector(message_size - 1 downto 0);
    signal recieve_buffer   : std_logic_vector(message_size - 1 downto 0);
    signal recieve_complete : std_logic;
    signal char_index       : integer range 0 to 29;
    signal last_char        : std_logic_vector(7 downto 0);
    signal send_finished    : std_logic;

begin
    input_cleaner_inst : entity work.InputCleaner
        generic map(
            clk_freq           => clk_freq,
            btn_stable_time    => 20,
            sw_stable_time     => 50,
            btn_count          => btn'length,
            btn_debounce_start => 4,
            sw_count           => sw'length,
            dipsw_count        => dipsw'length
        )
        port map(
            clk     => clk,
            btn_i   => btn,
            sw_i    => sw,
            dipsw_i => dipsw,
            btn_o   => btn_pulse,
            sw_o    => sw_debounced,
            dipsw_o => dipsw_debounced
        );

    controller_inst : entity work.Controller
        generic map(
            clk_freq     => clk_freq,
            message_size => message_size
        )
        port map(
            clk                 => clk,
            reset               => dipsw_debounced(1),
            btn                 => btn_pulse,
            new_data_in         => '0',
            edit_buffer         => edit_buffer,
            current_state       => current_state,
            L0                  => led(0),
            alert_signal        => open, -- ไม่ได้ใช้ใน top-level
            send_finished       => send_finished,
            bluetooth_connected => bt_state
        );

    editor_inst : entity work.Editor
        port map(
            clk            => clk,
            reset          => dipsw_debounced(1) or send_finished,
            current_state  => current_state,
            mode_select    => sw_debounced(0),
            btn            => btn_pulse(5 downto 1),
            last_char      => last_char,
            message_buffer => edit_buffer,
            char_index     => char_index
        );

    communicator_inst : entity work.Communicator
        generic map(
            clk_freq     => clk_freq,
            baud         => bluetooth_baud,
            message_size => message_size
        )
        port map(
            clk              => clk,
            reset            => dipsw_debounced(1),
            bt_rx            => bt_rx,
            current_state    => current_state,
            edit_buffer      => edit_buffer,
            recieve_buffer   => recieve_buffer,
            bt_tx            => bt_tx,
            send_finished    => send_finished,
            recieve_complete => recieve_complete
        );

    displayer_inst : entity work.Displayer
        generic map(
            clk_freq     => clk_freq,
            message_size => message_size,
            display_size => display_size
        )
        port map(
            clk            => clk,
            reset          => dipsw_debounced(1),
            current_state  => current_state,
            recieve_buffer => recieve_buffer,
            edit_buffer    => edit_buffer,
            last_char      => last_char,
            char_index     => char_index,
            lcd_en         => lcd_en,
            lcd_rs         => lcd_rs,
            lcd_rw         => lcd_rw,
            lcd_data       => lcd_data
        );

    recieve_buzzer_controller : entity work.BuzzController
        generic map(
            clk_freq     => clk_freq,
            pattern_bits => 10,
            pattern_sec  => 1
        )
        port map(
            clk     => clk,
            reset   => dipsw_debounced(1),
            enable  => recieve_complete,
            pattern => "1100110000",
            buzzer  => buzzer
        );

    led(7 downto 1) <= (others => '0');
    mn              <= std_logic_vector(to_unsigned(char_index, mn'length));
end Behavioral;
