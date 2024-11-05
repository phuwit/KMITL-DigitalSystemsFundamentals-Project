LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY Printer IS
    PORT (
        clk : IN STD_LOGIC;
        current_state : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- สัญญาณบอกสถานะปัจจุบัน
        mode_select : IN STD_LOGIC; -- สวิตช์เลือกโหมด (0 = โหมดตัวอักษร, 1 = โหมดตัวเลข)
        btn : IN std_logic_vector(5 downto 1);
        btn_reset : IN STD_LOGIC;
        last_char : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- ตัวอักษรล่าสุดที่เลือก
        message_buffer : OUT STD_LOGIC_VECTOR(239 DOWNTO 0); -- บัฟเฟอร์สำหรับเก็บข้อความ
        char_index : OUT INTEGER RANGE 0 TO 29 -- ดัชนีของตัวอักษรใน buffer (เปลี่ยนเป็นพอร์ต out)
    );
END Printer;

ARCHITECTURE Behavioral OF Printer IS
    SIGNAL char_timer : INTEGER RANGE 0 TO 30000000 := 0; -- ตัวนับเวลา 3 วินาที
    SIGNAL key_timer : INTEGER RANGE 0 TO 30000000 := 0; -- ตัวนับการกดปุ่ม
    SIGNAL internal_message_buffer : STD_LOGIC_VECTOR(239 DOWNTO 0) := (OTHERS => '0'); -- บัฟเฟอร์ภายในสำหรับเก็บข้อความ
    SIGNAL char_index_internal : INTEGER RANGE 0 TO 29 := 0; -- ตัวแปรภายในสำหรับจัดการ char_index
BEGIN
    PROCESS (clk, btn_reset)
    BEGIN
        IF btn_reset = '1' THEN
            char_timer <= 0;
            key_timer <= 0;
            char_index_internal <= 0;
            last_char <= "01000001"; -- ค่าเริ่มต้นเป็น 'A'
            internal_message_buffer <= (OTHERS => '0'); -- เคลียร์ค่าใน message_buffer
        ELSIF rising_edge(clk) THEN
            IF current_state = "01" THEN -- ตรวจสอบว่าสถานะเป็น PRINTING (สมมติใช้รหัส "01")
                IF mode_select = '0' THEN
                    -- โหมดตัวอักษร
                    IF btn(1) = '1' THEN
                        -- ตัวอักษร 'A' ถึง 'G'
                        IF last_char >= "01000001" AND last_char < "01000111" THEN
                            last_char <= STD_LOGIC_VECTOR(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        ELSE
                            last_char <= "01000001"; -- กลับไปที่ 'A'
                        END IF;
                        key_timer <= 0;
                    ELSIF btn(2) = '1' THEN
                        -- ตัวอักษร 'H' ถึง 'N'
                        IF last_char >= "01001000" AND last_char < "01001110" THEN
                            last_char <= STD_LOGIC_VECTOR(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        ELSE
                            last_char <= "01001000"; -- กลับไปที่ 'H'
                        END IF;
                        key_timer <= 0;
                    ELSIF btn(3) = '1' THEN
                        -- ตัวอักษร 'O' ถึง 'U'
                        IF last_char >= "01001111" AND last_char < "01010101" THEN
                            last_char <= STD_LOGIC_VECTOR(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        ELSE
                            last_char <= "01001111"; -- กลับไปที่ 'O'
                        END IF;
                        key_timer <= 0;
                    ELSIF btn(4) = '1' THEN
                        -- ตัวอักษร 'V' ถึง 'Z'
                        IF last_char >= "01010110" AND last_char < "01011010" THEN
                            last_char <= STD_LOGIC_VECTOR(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        ELSE
                            last_char <= "01010110"; -- กลับไปที่ 'V'
                        END IF;
                        key_timer <= 0;
                    END IF;
                ELSE
                    -- โหมดตัวเลข
                    IF btn(1) = '1' THEN
                        -- ตัวเลข '0' ถึง '3'
                        IF last_char >= "00110000" AND last_char < "00110011" THEN -- '0' ถึง '3'
                            last_char <= STD_LOGIC_VECTOR(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        ELSE
                            last_char <= "00110000"; -- กลับไปที่ '0'
                        END IF;
                        key_timer <= 0;
                    ELSIF btn(2) = '1' THEN
                        -- ตัวเลข '4' ถึง '6'
                        IF last_char >= "00110100" AND last_char < "00110110" THEN -- '4' ถึง '6'
                            last_char <= STD_LOGIC_VECTOR(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        ELSE
                            last_char <= "00110100"; -- กลับไปที่ '4'
                        END IF;
                        key_timer <= 0;
                    ELSIF btn(3) = '1' THEN
                        -- ตัวเลข '7' ถึง '9'
                        IF last_char >= "00110111" AND last_char < "00111001" THEN -- '7' ถึง '9'
                            last_char <= STD_LOGIC_VECTOR(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        ELSE
                            last_char <= "00110111"; -- กลับไปที่ '7'
                        END IF;
                        key_timer <= 0;
                    END IF;
                END IF;

                -- การกดปุ่ม btn(5) เพื่อลบข้อความตัวล่าสุด
                IF btn(5) = '1' THEN
                    IF char_index_internal > 0 THEN
                        char_index_internal <= char_index_internal - 1; -- ลดดัชนีตัวอักษร
                        internal_message_buffer((char_index_internal * 8) + 7 DOWNTO (char_index_internal * 8)) <= "00000000"; -- เคลียร์ข้อมูลที่ตำแหน่งล่าสุด
                    END IF;
                    key_timer <= 0; -- รีเซ็ตตัวนับเวลา
                END IF;

                -- การตรวจสอบเวลาสำหรับการเพิ่มตัวอักษรลงใน `internal_message_buffer`
                IF key_timer >= 30000000 THEN -- 3 วินาที
                    IF char_index_internal < 30 THEN
                        internal_message_buffer((char_index_internal * 8) + 7 DOWNTO (char_index_internal * 8)) <= last_char;
                        char_index_internal <= char_index_internal + 1;
                    END IF;
                    key_timer <= 0;
                ELSE
                    key_timer <= key_timer + 1;
                END IF;
            ELSE
                -- ไม่ทำงานเมื่อไม่ใช่สถานะ PRINTING
                last_char <= "00000000"; -- รีเซ็ตตัวอักษรเมื่อไม่ใช่สถานะที่ต้องการ
            END IF;
        END IF;
    END PROCESS;

    -- ส่งออกค่าของ internal_message_buffer ไปที่ message_buffer
    message_buffer <= internal_message_buffer;
    char_index <= char_index_internal; -- ส่งออกค่า char_index

END Behavioral;