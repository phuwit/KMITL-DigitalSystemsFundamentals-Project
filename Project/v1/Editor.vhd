library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globals.all;

entity Editor is
    port(
        clk            : in    std_logic;
        reset          : in    std_logic;
        current_state  : in    states;  -- สัญญาณบอกสถานะปัจจุบัน
        mode_select    : in    std_logic; -- สวิตช์เลือกโหมด (0 = โหมดตัวอักษร, 1 = โหมดตัวเลข)
        btn            : in    std_logic_vector(5 downto 1);
        last_char      : inout std_logic_vector(7 downto 0); -- ตัวอักษรล่าสุดที่เลือก
        message_buffer : out   std_logic_vector(239 downto 0); -- บัฟเฟอร์สำหรับเก็บข้อความ
        char_index     : out   integer range 0 to 29 -- ดัชนีของตัวอักษรใน buffer (เปลี่ยนเป็นพอร์ต out)
    );
end Editor;

architecture Behavioral of Editor is
    constant key_hold_time         : integer                          := 60_000_000;
    signal key_timer               : integer range 0 to key_hold_time := 0; -- ตัวนับการกดปุ่ม
    signal internal_message_buffer : std_logic_vector(239 downto 0)   := (others => '0'); -- บัฟเฟอร์ภายในสำหรับเก็บข้อความ
    signal char_index_internal     : integer range 0 to 29            := 29; -- ตัวแปรภายในสำหรับจัดการ char_index
    signal added_to_buffer         : std_logic                        := '1'; -- ใช้เก็บสถานะ ('0' หรือ '1') เพื่อบอกว่ามีการเพิ่มตัวอักษรลงใน internal_message_buffer แล้วหรือยัง

begin
    process(clk, reset)
    begin
        if reset = '1' then
            key_timer               <= 0;
            char_index_internal     <= 29;
            added_to_buffer         <= '1';
            last_char               <= "00000000"; -- ค่าเริ่มต้นเป็น 'A'
            internal_message_buffer <= (others => '0'); -- เคลียร์ค่าใน message_buffer
        elsif rising_edge(clk) then
            if current_state = EDITING then -- ตรวจสอบว่าสถานะเป็น PRINTING (รหัส "01")
                if mode_select = '0' then
                    -- โหมดตัวอักษร
                    if btn(1) = '1' then
                        -- ตัวอักษร 'A' ถึง 'G'
                        if last_char >= "01000001" and last_char < "01000111" then
                            last_char <= std_logic_vector(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        else
                            last_char <= "01000001"; -- กลับไปที่ 'A'
                        end if;
                        key_timer <= 0;
                    elsif btn(2) = '1' then
                        -- ตัวอักษร 'H' ถึง 'N'
                        if last_char >= "01001000" and last_char < "01001110" then
                            last_char <= std_logic_vector(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        else
                            last_char <= "01001000"; -- กลับไปที่ 'H'
                        end if;
                        key_timer <= 0;
                    elsif btn(3) = '1' then
                        -- ตัวอักษร 'O' ถึง 'U'
                        if last_char >= "01001111" and last_char < "01010101" then
                            last_char <= std_logic_vector(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        else
                            last_char <= "01001111"; -- กลับไปที่ 'O'
                        end if;
                        key_timer <= 0;
                    elsif btn(4) = '1' then
                        -- ตัวอักษร 'V' ถึง 'Z'
                        if last_char >= "01010110" and last_char < "01011010" then
                            last_char <= std_logic_vector(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        else
                            last_char <= "01010110"; -- กลับไปที่ 'V'
                        end if;
                        key_timer <= 0;
                    end if;
                else
                    -- โหมดตัวเลข
                    if btn(1) = '1' then
                        -- ตัวเลข '0' ถึง '3'
                        if last_char >= "00110000" and last_char < "00110011" then -- '0' ถึง '3'
                            last_char <= std_logic_vector(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        else
                            last_char <= "00110000"; -- กลับไปที่ '0'
                        end if;
                        key_timer <= 0;
                    elsif btn(2) = '1' then
                        -- ตัวเลข '4' ถึง '6'
                        if last_char >= "00110100" and last_char < "00110110" then -- '4' ถึง '6'
                            last_char <= std_logic_vector(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        else
                            last_char <= "00110100"; -- กลับไปที่ '4'
                        end if;
                        key_timer <= 0;
                    elsif btn(3) = '1' then
                        -- ตัวเลข '7' ถึง '9'
                        if last_char >= "00110111" and last_char < "00111001" then -- '7' ถึง '9'
                            last_char <= std_logic_vector(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        else
                            last_char <= "00110111"; -- กลับไปที่ '7'
                        end if;
                        key_timer <= 0;
                    elsif btn(4) = '1' then
                        -- เว้นวรรค (บรรทัดว่างเปล่า)
                        last_char <= x"20";
                        key_timer <= 0;
                    end if;
                end if;

                -- การกดปุ่ม btn(5) เพื่อลบข้อความตัวล่าสุด
                if btn(5) = '1' then
                    if char_index_internal > 0 and char_index_internal < 29 then
                        internal_message_buffer(((char_index_internal + 1) * 8) + 7 downto ((char_index_internal + 1) * 8)) <= "00000000";
                        char_index_internal                                                                                 <= char_index_internal + 1;
                    end if;

                    last_char       <= x"00";
                    key_timer       <= key_hold_time; -- รีเซ็ตตัวนับเวลา
                    added_to_buffer <= '1'; -- รีเซ็ตตัวนับเวลา
                end if;

                -- ตรวจสอบการกดปุ่มเพื่อเริ่มนับเวลา
                if btn(1) = '1' or btn(2) = '1' or btn(3) = '1' or btn(4) = '1' then
                    key_timer       <= 0; -- รีเซ็ตตัวนับเวลาเพื่อเริ่มนับใหม่เมื่อมีการกดปุ่ม
                    added_to_buffer <= '0'; -- รีเซ็ต trigger เมื่อมีการกดปุ่ม
                else
                    -- นับเวลาเมื่อไม่มีการกดปุ่ม
                    if key_timer < key_hold_time then
                        key_timer <= key_timer + 1;
                    end if;
                end if;

                -- การตรวจสอบเวลาสำหรับการเพิ่มตัวอักษรลงใน `internal_message_buffer`
                if key_timer >= key_hold_time and added_to_buffer = '0' then -- 3 วินาทีและยังไม่ได้ทริกเกอร์
                    if char_index_internal > 0 then
                        internal_message_buffer((char_index_internal * 8) + 7 downto (char_index_internal * 8)) <= last_char;
                        char_index_internal                                                                     <= char_index_internal - 1;
                        key_timer                                                                               <= key_hold_time; -- หยุดการนับเวลา (ค้างไว้ที่ค่าเดิม)
                        added_to_buffer                                                                         <= '1'; -- ตั้ง trigger เพื่อบอกว่ามีการเพิ่มตัวอักษรแล้ว
                        last_char                                                                               <= "00000000"; -- reset กลับไปที่ 'A'
                    end if;
                end if;

            else
                -- ไม่ทำงานเมื่อไม่ใช่สถานะ PRINTING
                last_char <= "00000000"; -- รีเซ็ตตัวอักษรเมื่อไม่ใช่สถานะที่ต้องการ
            end if;
        end if;
    end process;

    -- ส่งออกค่าของ internal_message_buffer ไปที่ message_buffer
    message_buffer <= internal_message_buffer;
    char_index     <= char_index_internal;

end Behavioral;
