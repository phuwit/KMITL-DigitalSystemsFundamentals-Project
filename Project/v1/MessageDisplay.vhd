LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY MessageDisplay IS
  PORT(
    clk           : IN  STD_LOGIC; -- สัญญาณนาฬิกา
    reset         : IN  STD_LOGIC; -- สัญญาณรีเซ็ต
    message_buffer_in : IN  STD_LOGIC_VECTOR(239 downto 0); -- ข้อความที่รับเข้า
    last_char     : IN  STD_LOGIC_VECTOR(7 downto 0); -- ตัวอักษรล่าสุดที่เลือก
    message_out   : OUT STD_LOGIC_VECTOR(239 downto 0) -- ข้อความที่ส่งออก
  );
END MessageDisplay;

ARCHITECTURE Behavioral OF MessageDisplay IS
  SIGNAL alt_buffer : STD_LOGIC_VECTOR(239 downto 0); -- บัฟเฟอร์ที่เติม last_char
  SIGNAL display_toggle : STD_LOGIC := '0'; -- สัญญาณสำหรับสลับการแสดงผล
  SIGNAL half_second_counter : INTEGER := 0; -- ตัวนับครึ่งวินาที
  CONSTANT clk_freq : INTEGER := 50000000; -- ความถี่ของนาฬิกา (50 MHz)
  CONSTANT half_second_count : INTEGER := clk_freq / 2; -- จำนวนรอบนาฬิกาสำหรับครึ่งวินาที
BEGIN

  PROCESS(clk, reset)
  BEGIN
    IF reset = '1' THEN
      half_second_counter <= 0;
      display_toggle <= '0';
      alt_buffer <= (others => '0');
    ELSIF rising_edge(clk) THEN
      -- ตัวนับครึ่งวินาที
      IF half_second_counter < half_second_count THEN
        half_second_counter <= half_second_counter + 1;
      ELSE
        half_second_counter <= 0;
        display_toggle <= NOT display_toggle; -- สลับสถานะการแสดงผล
      END IF;

      -- ตรวจสอบว่า message_buffer_in เต็มหรือไม่
      IF message_buffer_in(239 downto 8) /= (others => '0') THEN
        alt_buffer <= message_buffer_in; -- กรณีที่เต็มอยู่แล้ว ใช้ค่าเดิม
      ELSE
        -- เพิ่ม last_char ต่อท้ายในช่องว่างแรกที่เจอ
        alt_buffer <= message_buffer_in(239 downto 8) & last_char;
      END IF;
    END IF;
  END PROCESS;

  -- เลือก output ตามสถานะ display_toggle
  message_out <= message_buffer_in WHEN display_toggle = '0' ELSE alt_buffer;

END Behavioral;
