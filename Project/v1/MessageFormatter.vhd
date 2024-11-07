library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globals.all;

entity MessageFormatter is
    generic(
        message_size : integer := 240;
        display_size : integer := 256);
    port(
        clk           : in  STD_LOGIC;  -- สัญญาณนาฬิกา
        reset         : in  STD_LOGIC;  -- สัญญาณรีเซ็ต
        message_in    : in  STD_LOGIC_VECTOR(message_size - 1 downto 0); -- ข้อความที่รับเข้า
        last_char     : in  STD_LOGIC_VECTOR(7 downto 0); -- ตัวอักษรล่าสุดที่เลือก
        char_index    : in  INTEGER range 0 to 29;
        current_state : in  STATES;
        message_out   : out STD_LOGIC_VECTOR(display_size - 1 downto 0) -- ข้อความที่ส่งออก
    );
end MessageFormatter;

architecture Behavioral of MessageFormatter is
    constant blink_time                : INTEGER                      := 13_500_000;
    constant blank_message_replacement : std_logic_vector(7 downto 0) := x"ff"; -- solid rectangle
    constant blinking_character        : std_logic_vector(7 downto 0) := x"20"; -- space

    signal formatted_message  : STD_LOGIC_VECTOR(message_size -1 downto 0);
    signal display_toggle     : STD_LOGIC                     := '0'; -- สัญญาณสำหรับสลับการแสดงผล
    signal blink_counter      : INTEGER range 0 to blink_time := 0; -- ตัวนับครึ่งวินาที
    signal current_state_char : std_logic_vector(7 downto 0);
begin

    process(clk, reset)
    begin
        if reset = '1' then
            blink_counter      <= 0;
            display_toggle     <= '0';
            formatted_message  <= (others => '0');
            current_state_char <= std_logic_vector(to_unsigned(character'pos('X'), 8));
        elsif rising_edge(clk) then
            -- ตัวนับครึ่งวินาที
            if blink_counter < blink_time then
                blink_counter <= blink_counter + 1;
            else
                blink_counter  <= 0;
                display_toggle <= not display_toggle; -- สลับสถานะการแสดงผล
            end if;

            -- copy message
            formatted_message <= message_in;

            -- format 0x00 into blank replacement
            for chunk in 0 to (message_size / 8) - 1 loop
                if (message_in((chunk * 8) + 7 downto (chunk * 8)) = x"00") then
                    formatted_message(((chunk) * 8) + 7 downto ((chunk) * 8)) <= blank_message_replacement;
                else
                    formatted_message(((chunk) * 8) + 7 downto ((chunk) * 8)) <= message_in((chunk * 8) + 7 downto (chunk * 8));
                end if;
            end loop;

            -- format blinking character
            if current_state = EDITING and message_in(7 downto 0) = x"00" then
                if display_toggle = '0' then
                    if last_char = x"00" then
                        formatted_message((char_index * 8) + 7 downto (char_index * 8)) <= x"20";
                    else
                        formatted_message((char_index * 8) + 7 downto (char_index * 8)) <= last_char;
                    end if;
                else
                    formatted_message((char_index * 8) + 7 downto (char_index * 8)) <= blinking_character;
                end if;
            else
                formatted_message((char_index * 8) + 7 downto (char_index * 8)) <= blank_message_replacement;
            end if;

            -- add current state to last character
            case current_state is
                when RECEIVING =>
                    current_state_char <= std_logic_vector(to_unsigned(character'pos('R'), 8));

                when EDITING =>
                    current_state_char <= std_logic_vector(to_unsigned(character'pos('E'), 8));

                when SENDING =>
                    current_state_char <= std_logic_vector(to_unsigned(character'pos('S'), 8));
            end case;
        end if;
    end process;

    -- เลือก output ตามสถานะ display_toggle
    -- message_out <= main_buffer_formatted when display_toggle = '0' else alt_buffer_formatted;
    message_out <= formatted_message & x"20" & current_state_char; -- @suppress "Incorrect array size in assignment: expected (<display_size>) but was (<message_size + 16>)"
end Behavioral;
