library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.globals.all;

entity Perger is
    port(
        clk      : in  STD_LOGIC;
        btn      : in  STD_LOGIC_VECTOR(6 downto 1);
        sw       : in  STD_LOGIC_VECTOR(6 downto 0);
        bt_rx    : in  std_logic;
        bt_state : in  std_logic;
        led      : out STD_LOGIC_VECTOR(7 downto 0);
        mn       : out STD_LOGIC_VECTOR(7 downto 0);
        lcd_en   : out STD_LOGIC;
        lcd_rs   : out STD_LOGIC;
        lcd_rw   : out STD_LOGIC;
        lcd_data : out STD_LOGIC_VECTOR(7 downto 0);
        bt_tx    : out std_logic
    );
end Perger;

architecture Behavioral of Perger is
    constant system_frequency : integer := 20_000_000;
    constant bluetooth_baud   : integer := 115_200;

    signal btn_debounced : STD_LOGIC_VECTOR(6 downto 1);
    signal sw_debounced  : STD_LOGIC_VECTOR(7 downto 0);
    signal btn_pulse     : STD_LOGIC_VECTOR(6 downto 1);

    -- สัญญาณภายในสำหรับการสื่อสารระหว่างโมดูล
    signal current_state, next_state : STATES;
    signal message_buffer            : STD_LOGIC_VECTOR(239 downto 0);
    signal message_formatted         : STD_LOGIC_VECTOR(255 downto 0);
    signal char_index                : INTEGER range 0 to 29;
    signal last_char                 : STD_LOGIC_VECTOR(7 downto 0);
    signal sender_reset              : std_logic;
    signal uart_tx_start             : STD_LOGIC;
    signal send_finished             : STD_LOGIC;
    signal uart_data_stream_in_ack   : std_logic;
    signal uart_byte                 : std_logic_vector(7 downto 0);
begin
    -- Debouncer
    btn_debounced(4 downto 1) <= btn(4 downto 1);
    g_btn_debounce : for i in 5 to 6 generate
        debounce_inst : entity work.Debounce
            generic map(
                clk_freq    => system_frequency,
                stable_time => 20
            )
            port map(
                clk     => clk,
                reset_n => '1',
                button  => btn(i),
                result  => btn_debounced(i)
            );
    end generate;

    g_sw_debounce : for i in 0 to 6 generate
        debounce_inst : entity work.Debounce
            generic map(
                clk_freq    => system_frequency,
                stable_time => 50
            )
            port map(
                clk     => clk,
                reset_n => '1',
                button  => sw(i),
                result  => sw_debounced(i)
            );

    end generate;

    g_btn_pulse : for i in 1 to 6 generate
        edge_detector_inst : entity work.EdgeDetector
            port map(
                i_clk   => clk,
                i_rstb  => '1',
                i_input => btn_debounced(i),
                o_pulse => btn_pulse(i)
            );

    end generate;

    -- การเชื่อมต่อโมดูล State_Manager
    state_control_inst : entity work.StateControl
        port map(
            clk                 => clk,
            reset               => '0',
            btn                 => btn_pulse,
            new_data_in         => '0', -- สามารถแก้ไขตามความต้องการได้
            message_buffer      => message_buffer,
            current_state       => current_state,
            next_state          => next_state,
            L0                  => led(0),
            alert_signal        => open, -- ไม่ได้ใช้ใน top-level
            send_finished       => send_finished,
            bluetooth_connected => bt_state,
            sender_reset        => sender_reset
        );

    -- การเชื่อมต่อโมดูล Print_Manager
    printer_inst : entity work.Printer
        port map(
            clk            => clk,
            current_state  => current_state,
            mode_select    => sw_debounced(0),
            btn            => btn_pulse(5 downto 1),
            reset          => '0',
            last_char      => last_char,
            message_buffer => message_buffer,
            char_index     => char_index
        );

    -- การเชื่อมต่อโมดูล Send_Module
    sender_inst : entity work.Sender
        port map(
            clk                => clk,
            reset              => '0',
            current_state      => current_state,
            message_buffer     => message_buffer,
            send_finished      => send_finished,
            data_stream_in_ack => uart_data_stream_in_ack,
            tx_start           => uart_tx_start,
            data_out           => uart_byte
        );

    Uart_inst : entity work.Uart
        generic map(
            baud            => bluetooth_baud,
            clock_frequency => system_frequency
        )
        port map(
            clock               => clk,
            reset               => '0',
            data_stream_in      => uart_byte,
            data_stream_in_stb  => uart_tx_start,
            data_stream_in_ack  => uart_data_stream_in_ack,
            data_stream_out     => open,
            data_stream_out_stb => open,
            tx                  => bt_tx,
            rx                  => bt_rx
        );

    -- การเชื่อมต่อโมดูลแสดงผล message_display
    display_inst : entity work.MessageFormatter
        port map(
            clk           => clk,
            reset         => '0',
            message_in    => message_buffer,
            last_char     => last_char,
            char_index    => char_index,
            current_state => current_state,
            message_out   => message_formatted
        );

    -- การเชื่อมต่อโมดูล LCD Controller
    lcd_controller_inst : entity work.LcdController
        generic map(
            clk_freq => system_frequency
        )
        port map(
            clk          => clk,
            reset_n      => '1',
            line1_buffer => message_formatted(255 downto 128),
            line2_buffer => message_formatted(127 downto 0),
            rw           => lcd_rw,
            rs           => lcd_rs,
            e            => lcd_en,
            lcd_data     => lcd_data
        );

    led(7)          <= bt_state;
    led(6)          <= send_finished;
    led(5)          <= uart_tx_start;
    led(4 downto 1) <= (others => '0');
    mn              <= std_logic_vector(to_unsigned(char_index, mn'length));
end Behavioral;
