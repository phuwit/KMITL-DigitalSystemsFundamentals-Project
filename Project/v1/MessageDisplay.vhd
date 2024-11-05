library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity MessageDisplay is
    port(
        clk         : in  STD_LOGIC;    -- สัญญาณนาฬิกา
        reset       : in  STD_LOGIC;    -- สัญญาณรีเซ็ต
        message_in  : in  STD_LOGIC_VECTOR(239 downto 0); -- ข้อความที่รับเข้า
        last_char   : in  STD_LOGIC_VECTOR(7 downto 0); -- ตัวอักษรล่าสุดที่เลือก
        message_out : out STD_LOGIC_VECTOR(239 downto 0) -- ข้อความที่ส่งออก
    );
end MessageDisplay;

architecture Behavioral of MessageDisplay is
    constant message_size      : integer := 239;
    constant clk_freq          : INTEGER := 20_000_000;
    constant half_second_count : INTEGER := clk_freq / 2; -- จำนวนรอบนาฬิกาสำหรับครึ่งวินาที

    signal alt_buffer            : STD_LOGIC_VECTOR(message_size downto 0); -- บัฟเฟอร์ที่เติม last_char
    signal main_buffer_formatted : STD_LOGIC_VECTOR(message_size downto 0);
    signal alt_buffer_formatted  : STD_LOGIC_VECTOR(message_size downto 0);
    signal display_toggle        : STD_LOGIC            := '0'; -- สัญญาณสำหรับสลับการแสดงผล
    signal half_second_counter   : INTEGER range 0 to 1 := 0; -- ตัวนับครึ่งวินาที
begin

    process(clk, reset)
    begin
        if reset = '1' then
            half_second_counter   <= 0;
            display_toggle        <= '0';
            alt_buffer            <= (others => '0');
            main_buffer_formatted <= (others => '0');
            alt_buffer_formatted  <= (others => '0');
        elsif rising_edge(clk) then
            -- ตัวนับครึ่งวินาที
            if half_second_counter < half_second_count then
                half_second_counter <= half_second_counter + 1;
            else
                half_second_counter <= 0;
                display_toggle      <= not display_toggle; -- สลับสถานะการแสดงผล
            end if;

            -- ตรวจสอบว่า message_buffer_in เต็มหรือไม่
            if message_in(239 downto 8) /= (232 downto 0 => '0') then
                alt_buffer <= message_in; -- กรณีที่เต็มอยู่แล้ว ใช้ค่าเดิม
            else
                -- เพิ่ม last_char ต่อท้ายในช่องว่างแรกที่เจอ
                alt_buffer <= message_in(message_size downto 8) & last_char;
            end if;

            -- format 0x00 into ascii space 0x20
            for chunk in 0 to (message_size / 8) - 1 loop
                if (message_in((chunk * 8) + 7 downto (chunk * 8)) = x"00") then
                    main_buffer_formatted((chunk * 8) + 7 downto (chunk * 8)) <= x"20";
                else
                    main_buffer_formatted((chunk * 8) + 7 downto (chunk * 8)) <= message_in((chunk * 8) + 7 downto (chunk * 8));
                end if;

                if (alt_buffer((chunk * 8) + 7 downto (chunk * 8)) = x"00") then
                    alt_buffer_formatted((chunk * 8) + 7 downto (chunk * 8)) <= x"20";
                else
                    alt_buffer_formatted((chunk * 8) + 7 downto (chunk * 8)) <= alt_buffer((chunk * 8) + 7 downto (chunk * 8));
                end if;
            end loop;
        end if;
    end process;

    -- เลือก output ตามสถานะ display_toggle
    message_out <= main_buffer_formatted when display_toggle = '0' else alt_buffer_formatted;

end Behavioral;
