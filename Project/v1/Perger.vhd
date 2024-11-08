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
    signal btn_pulse       : std_logic_vector(btn'length downto 1)    := (others => '0');
    signal sw_debounced    : std_logic_vector(sw'length - 1 downto 0) := (others => '0');
    signal dipsw_debounced : std_logic_vector(dipsw'length downto 1)  := (others => '0');

    signal state : states := RECEIVING;

    signal edit_buffer    : std_logic_vector(message_size - 1 downto 0) := (others => '0');
    signal recieve_buffer : std_logic_vector(message_size - 1 downto 0) := (others => '0');
    signal char_index     : integer range 0 to 29                       := 29;
    signal last_char      : std_logic_vector(7 downto 0)                := (others => '0');

    signal message_recieve_complete : std_logic := '0';
    signal message_send_complete    : std_logic := '0';
    signal bluetooth_send_failed    : std_logic := '0';
    signal bluetooth_send_success   : std_logic := '0';

    signal editor_reset          : std_logic := '0';
    signal global_reset_internal : std_logic := '0';
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
            clk                    => clk,
            reset                  => global_reset_internal,
            btn                    => btn_pulse,
            edit_buffer            => edit_buffer,
            state                  => state,
            led0                   => led(0),
            message_send_complete  => message_send_complete,
            bluetooth_connected    => bt_state,
            bluetooth_send_failed  => bluetooth_send_failed,
            bluetooth_send_success => bluetooth_send_success
        );

    editor_reset <= global_reset_internal or message_send_complete;
    editor_inst : entity work.Editor
        port map(
            clk            => clk,
            reset          => editor_reset,
            current_state  => state,
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
            reset            => global_reset_internal,
            bt_rx            => bt_rx,
            current_state    => state,
            edit_buffer      => edit_buffer,
            recieve_buffer   => recieve_buffer,
            bt_tx            => bt_tx,
            send_finished    => message_send_complete,
            recieve_complete => message_recieve_complete
        );

    displayer_inst : entity work.Displayer
        generic map(
            clk_freq     => clk_freq,
            message_size => message_size,
            display_size => display_size
        )
        port map(
            clk            => clk,
            reset          => global_reset_internal,
            current_state  => state,
            recieve_buffer => recieve_buffer,
            edit_buffer    => edit_buffer,
            last_char      => last_char,
            char_index     => char_index,
            lcd_en         => lcd_en,
            lcd_rs         => lcd_rs,
            lcd_rw         => lcd_rw,
            lcd_data       => lcd_data
        );

    buzz_controller_inst : entity work.BuzzController
        generic map(
            clk_freq => clk_freq
        )
        port map(
            clk                     => clk,
            reset                   => global_reset_internal,
            enable_message_recieved => message_recieve_complete,
            enable_send_failed      => bluetooth_send_failed,
            enable_send_success     => bluetooth_send_success,
            buzzer                  => buzzer
        );

    global_reset_internal <= dipsw_debounced(1);
    led(7 downto 1)       <= (others => '0');
end Behavioral;
