LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY PRINT_MANAGER IS
  PORT (
    CLK : IN STD_LOGIC;
    RESET : IN STD_LOGIC;
    SW0 : IN STD_LOGIC; -- สวิตช์เลือกโหมด (0 = โหมดตัวอักษร, 1 = โหมดตัวเลข)
    PB1, PB2, PB3, PB4, PB5 : IN STD_LOGIC; -- ปุ่มสำหรับการเลือกตัวอักษร/ตัวเลข และลบตัวอักษร
    char_index : INOUT INTEGER RANGE 0 TO 29; -- ดัชนีของตัวอักษรใน buffer
    last_char : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- ตัวอักษรล่าสุดที่เลือก
    message_buffer : INOUT STD_LOGIC_VECTOR(239 DOWNTO 0); -- บัฟเฟอร์สำหรับเก็บข้อความ
    char_timer : INOUT INTEGER RANGE 0 TO 30000000; -- ตัวนับเวลา 3 วินาที
    key_timer : INOUT INTEGER RANGE 0 TO 30000000; -- ตัวนับการกดปุ่ม
    LCD_DISPLAY : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) -- แสดงผลบนหน้าจอ LCD
  );
END PRINT_MANAGER;

ARCHITECTURE Behavioral OF PRINT_MANAGER IS
BEGIN
  PROCESS (CLK, RESET)
  BEGIN
    IF RESET = '1' THEN
      char_timer <= 0;
      key_timer <= 0;
      char_index <= 0;
      last_char <= "01000001"; -- ค่าเริ่มต้นเป็น 'A'
    ELSIF rising_edge(CLK) THEN
      IF SW0 = '0' THEN
        -- โหมดตัวอักษร
        IF PB1 = '1' THEN
          -- ตัวอักษร 'A' ถึง 'G'
          IF last_char >= "01000001" AND last_char < "01000111" THEN
            last_char <= last_char + 1;
          ELSE
            last_char <= "01000001"; -- กลับไปที่ 'A'
          END IF;
          key_timer <= 0;
        ELSIF PB2 = '1' THEN
          -- ตัวอักษร 'H' ถึง 'N'
          IF last_char >= "01001000" AND last_char < "01001110" THEN
            last_char <= last_char + 1;
          ELSE
            last_char <= "01001000"; -- กลับไปที่ 'H'
          END IF;
          key_timer <= 0;
        ELSIF PB3 = '1' THEN
          -- ตัวอักษร 'O' ถึง 'U'
          IF last_char >= "01001111" AND last_char < "01010101" THEN
            last_char <= last_char + 1;
          ELSE
            last_char <= "01001111"; -- กลับไปที่ 'O'
          END IF;
          key_timer <= 0;
        ELSIF PB4 = '1' THEN
          -- ตัวอักษร 'V' ถึง 'Z'
          IF last_char >= "01010110" AND last_char < "01011010" THEN
            last_char <= last_char + 1;
          ELSE
            last_char <= "01010110"; -- กลับไปที่ 'V'
          END IF;
          key_timer <= 0;
        END IF;
      ELSE
        -- โหมดตัวเลข
        IF PB1 = '1' THEN
          -- ตัวเลข '0' ถึง '3'
          IF last_char >= "00110000" AND last_char < "00110011" THEN -- '0' ถึง '3'
            last_char <= last_char + 1;
          ELSE
            last_char <= "00110000"; -- กลับไปที่ '0'
          END IF;
          key_timer <= 0;
        ELSIF PB2 = '1' THEN
          -- ตัวเลข '4' ถึง '6'
          IF last_char >= "00110100" AND last_char < "00110110" THEN -- '4' ถึง '6'
            last_char <= last_char + 1;
          ELSE
            last_char <= "00110100"; -- กลับไปที่ '4'
          END IF;
          key_timer <= 0;
        ELSIF PB3 = '1' THEN
          -- ตัวเลข '7' ถึง '9'
          IF last_char >= "00110111" AND last_char < "00111001" THEN -- '7' ถึง '9'
            last_char <= last_char + 1;
          ELSE
            last_char <= "00110111"; -- กลับไปที่ '7'
          END IF;
          key_timer <= 0;
        END IF;
      END IF;

      -- การกดปุ่ม PB5 เพื่อลบข้อความตัวล่าสุด
      IF PB5 = '1' THEN
        IF char_index > 0 THEN
          char_index <= char_index - 1; -- ลดดัชนีตัวอักษร
          message_buffer((char_index * 8) + 7 DOWNTO (char_index * 8)) <= "00000000"; -- เคลียร์ข้อมูลที่ตำแหน่งล่าสุด
        END IF;
        key_timer <= 0; -- รีเซ็ตตัวนับเวลา
      END IF;

      -- การแสดงผลบน LCD
      LCD_DISPLAY <= last_char;

      -- การตรวจสอบเวลาสำหรับการเพิ่มตัวอักษรลงใน `message_buffer`
      IF key_timer >= 30000000 THEN -- 3 วินาที
        IF char_index < 30 THEN
          message_buffer((char_index * 8) + 7 DOWNTO (char_index * 8)) <= last_char;
          char_index <= char_index + 1;
        END IF;
        key_timer <= 0;
      ELSE
        key_timer <= key_timer + 1;
      END IF;
    END IF;
  END PROCESS;
END Behavioral;