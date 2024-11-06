library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity Perger is
    port(
        clk      : in  STD_LOGIC;
        btn      : in  STD_LOGIC_VECTOR(6 downto 1);
        sw       : in  STD_LOGIC_VECTOR(6 downto 0);
        led      : out STD_LOGIC_VECTOR(7 downto 0);
        mn       : out STD_LOGIC_VECTOR(7 downto 0);
        lcd_en   : out STD_LOGIC;
        lcd_rs   : out STD_LOGIC;
        lcd_rw   : out STD_LOGIC;
        lcd_data : out STD_LOGIC_VECTOR(7 downto 0)
    );
end Perger;

architecture Behavioral of Perger is
    -- type STATE_TYPE is (RECEIVING, PRINTING, SENDING); -- ประเภทองสถานะ

    signal btn_debounced : STD_LOGIC_VECTOR(6 downto 1);
    signal sw_debounced  : STD_LOGIC_VECTOR(7 downto 0);
    signal btn_pulse     : STD_LOGIC_VECTOR(6 downto 1);

    -- สัญญาณภายในสำหรับการสื่อสารระหว่างโมดูล
    -- signal state : STATE_TYPE := RECEIVING;
    signal current_state, next_state : STD_LOGIC_VECTOR(1 downto 0);
    signal message_buffer            : STD_LOGIC_VECTOR(239 downto 0);
    signal message_blink             : STD_LOGIC_VECTOR(239 downto 0);
    signal char_index                : INTEGER range 0 to 29;
    signal last_char                 : STD_LOGIC_VECTOR(7 downto 0);
    signal tx_start                  : STD_LOGIC;
    signal data_out                  : STD_LOGIC_VECTOR(239 downto 0);
    signal transmit_in_progress      : STD_LOGIC;
begin
    -- Debouncer
    btn_debounced(4 downto 1) <= btn(4 downto 1);
    g_btn_debounce : for i in 5 to 6 generate
        debounce_inst : entity work.Debounce
            generic map(
                clk_freq    => 20_000_000,
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
                clk_freq    => 20_000_000,
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
            clk                  => clk,
            reset                => '0',
            btn                  => btn_pulse,
            new_data_in          => '0', -- สามารถแก้ไขตามความต้องการได้
            message_buffer       => message_buffer,
            current_state        => current_state,
            next_state           => next_state,
            L0                   => led(0),
            alert_signal         => open, -- ไม่ได้ใช้ใน top-level
            transmit_in_progress => transmit_in_progress
        );

    -- การเชื่อมต่อโมดูล Print_Manager
    printer_inst : entity work.Printer
        port map(
            clk            => clk,
            current_state  => current_state,
            mode_select    => sw_debounced(0),
            btn            => btn_pulse(5 downto 1),
            btn_reset      => btn_pulse(6),
            last_char      => last_char,
            message_buffer => message_buffer,
            char_index     => char_index
        );

    -- การเชื่อมต่อโมดูล Send_Module
    sender_inst : entity work.Sender
        port map(
            current_state  => current_state,
            message_buffer => message_buffer,
            tx_start       => tx_start,
            data_out       => data_out
        );

    -- การเชื่อมต่อโมดูลแสดงผล message_display
    display_inst : entity work.MessageDisplay
        port map(
            clk                => clk,
            reset              => '0',
            message_in         => message_buffer,
            last_char          => last_char,
            message_out        => message_blink,
            char_index         => char_index,
            display_toggle_out => led(7)
        );

    -- การเชื่อมต่อโมดูล LCD Controller
    lcd_controller_inst : entity work.LcdController
        port map(
            clk          => clk,
            reset_n      => '1',
            line1_buffer => message_blink(239 downto 112),
            line2_buffer => message_blink(111 downto 0) & x"2020",
            rw           => lcd_rw,
            rs           => lcd_rs,
            e            => lcd_en,
            lcd_data     => lcd_data
        );

    led(6 downto 1) <= (others => '0');
    mn              <= std_logic_vector(to_unsigned(char_index, mn'length));
end Behavioral;
