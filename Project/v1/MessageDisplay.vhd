library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity MessageDisplay is
    port(
        clk               : in  STD_LOGIC; -- สัญญาณนาฬิกา
        reset             : in  STD_LOGIC; -- สัญญาณรีเซ็ต
        message_buffer_in : in  STD_LOGIC_VECTOR(239 downto 0); -- ข้อความที่รับเข้า
        last_char         : in  STD_LOGIC_VECTOR(7 downto 0); -- ตัวอักษรล่าสุดที่เลือก
        message_out       : out STD_LOGIC_VECTOR(239 downto 0) -- ข้อความที่ส่งออก
    );
end MessageDisplay;

architecture Behavioral of MessageDisplay is
    signal alt_buffer          : STD_LOGIC_VECTOR(239 downto 0); -- บัฟเฟอร์ที่เติม last_char
    signal display_toggle      : STD_LOGIC := '0'; -- สัญญาณสำหรับสลับการแสดงผล
    signal half_second_counter : INTEGER   := 0; -- ตัวนับครึ่งวินาที
    constant clk_freq          : INTEGER   := 50000000; -- ความถี่ของนาฬิกา (50 MHz)
    constant half_second_count : INTEGER   := clk_freq / 2; -- จำนวนรอบนาฬิกาสำหรับครึ่งวินาที
begin

    process(clk, reset)
    begin
        if reset = '1' then
            half_second_counter <= 0;
            display_toggle      <= '0';
            alt_buffer          <= (others => '0');
        elsif rising_edge(clk) then
            -- ตัวนับครึ่งวินาที
            if half_second_counter < half_second_count then
                half_second_counter <= half_second_counter + 1;
            else
                half_second_counter <= 0;
                display_toggle      <= not display_toggle; -- สลับสถานะการแสดงผล
            end if;

            -- ตรวจสอบว่า message_buffer_in เต็มหรือไม่
            if message_buffer_in(239 downto 8) /= (232 downto 0 => '0') then
                alt_buffer <= message_buffer_in; -- กรณีที่เต็มอยู่แล้ว ใช้ค่าเดิม
            else
                -- เพิ่ม last_char ต่อท้ายในช่องว่างแรกที่เจอ
                alt_buffer <= message_buffer_in(239 downto 8) & last_char;
            end if;
        end if;
    end process;

    -- เลือก output ตามสถานะ display_toggle
    message_out <= message_buffer_in when display_toggle = '0' else alt_buffer;

end Behavioral;
