LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY Perger IS
    PORT (
        clk : IN STD_LOGIC;
        btn : IN STD_LOGIC_VECTOR(6 DOWNTO 1);
        sw : IN STD_LOGIC_VECTOR(7 DOWNTO 0);

        led : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        mn : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);

        lcd_en : OUT STD_LOGIC;
        lcd_rs : OUT STD_LOGIC;
        lcd_rw : OUT STD_LOGIC;
        lcd_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END Perger;

ARCHITECTURE Behavioral OF Perger IS
    TYPE STATE_TYPE IS (RECEIVING, PRINTING, SENDING); -- ประเภทของสถานะ

    SIGNAL btn_debounced : STD_LOGIC_VECTOR(6 DOWNTO 1);
    SIGNAL sw_debounced : STD_LOGIC_VECTOR(6 DOWNTO 1);
    SIGNAL btn_pulse : STD_LOGIC_VECTOR(6 DOWNTO 1);

    -- สัญญาณภายในสำหรับการสื่อสารระหว่างโมดูล
    -- signal state : STATE_TYPE := RECEIVING;
    SIGNAL current_state, next_state : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL message_buffer : STD_LOGIC_VECTOR(239 DOWNTO 0);
    SIGNAL char_index : INTEGER RANGE 0 TO 29;
    SIGNAL last_char : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL tx_start : STD_LOGIC;
    SIGNAL data_out : STD_LOGIC_VECTOR(239 DOWNTO 0);
    SIGNAL transmit_in_progress : STD_LOGIC;
BEGIN
    -- Debouncer
    btn_debounced(4 DOWNTO 1) <= btn(4 DOWNTO 1);
    g_btn_debounce : FOR i IN 5 TO 6 GENERATE
        debounce_inst : ENTITY work.Debounce
            GENERIC MAP(
                clk_freq => 20_000_000,
                stable_time => 20
            )
            PORT MAP(
                clk => clk,
                reset_n => '1',
                button => btn(i),
                result => btn_debounced(i)
            );
    END GENERATE;

    g_sw_debounce : FOR i IN 1 TO 6 GENERATE
        debounce_inst : ENTITY work.Debounce
            GENERIC MAP(
                clk_freq => 20_000_000,
                stable_time => 50
            )
            PORT MAP(
                clk => clk,
                reset_n => '1',
                button => btn(i),
                result => sw_debounced(i)
            );

    END GENERATE;

    g_btn_pulse : FOR i IN 1 TO 6 GENERATE
        edge_detector_inst : ENTITY work.EdgeDetector
            PORT MAP(
                i_clk => clk,
                i_rstb => '1',
                i_input => btn_debounced(i),
                o_pulse => btn_pulse(i)
            );

    END GENERATE;

    -- การเชื่อมต่อโมดูล State_Manager
    state_control_inst : ENTITY work.StateControl
        PORT MAP(
            CLK => CLK,
            RESET => '0',
            btn => btn_pulse,
            new_data_in => '0', -- สามารถแก้ไขตามความต้องการได้
            message_buffer => message_buffer,
            current_state => current_state,
            next_state => next_state,
            L0 => led(0),
            alert_signal => OPEN, -- ไม่ได้ใช้ใน top-level
            transmit_in_progress => transmit_in_progress
        );

    -- การเชื่อมต่อโมดูล Print_Manager
    printer_inst : ENTITY work.Printer
        PORT MAP(
            clk => clk,
            current_state => current_state,
            mode_select => sw(0),
            btn => btn_pulse(5 DOWNTO 1),
            btn_reset => btn_pulse(6),
            last_char => last_char,
            message_buffer => message_buffer,
            char_index => char_index
        );

    -- การเชื่อมต่อโมดูล Send_Module
    sender_inst : ENTITY work.Sender
        PORT MAP(
            current_state => current_state,
            message_buffer => message_buffer,
            tx_start => tx_start,
            data_out => data_out,
            trigger => trigger
        );

    -- การเชื่อมต่อโมดูลแสดงผล message_display
    display_inst : ENTITY work.MessageDisplay
        PORT MAP(
            clk => CLK,
            reset => RESET,
            message_buffer_in => message_buffer,
            last_char => last_char,
            message_out => MESSAGE_OUT
        );

    -- การเชื่อมต่อโมดูล LCD Controller
    lcd_controller_inst : ENTITY work.LcdController
        PORT MAP(
            clk => clk,
            reset_n => '1',
            line1_buffer => message_buffer(239 DOWNTO 112),
            line2_buffer => message_buffer(111 DOWNTO 0) & x"2020",
            rw => lcd_rw,
            rs => lcd_rs,
            e => lcd_en,
            lcd_data => lcd_data
        );
END Behavioral;