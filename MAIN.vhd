LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY MAIN IS
  PORT (
    CLK : IN STD_LOGIC;
    RESET : IN STD_LOGIC;
    SW0 : IN STD_LOGIC; -- สวิตช์เลือกโหมด
    PB1, PB2, PB3, PB4, PB5, PB6 : IN STD_LOGIC; -- ปุ่มกด
    L0 : OUT STD_LOGIC; -- ไฟแสดงสถานะการทำงาน
    MESSAGE_OUT : OUT STD_LOGIC_VECTOR(239 DOWNTO 0); -- ข้อความที่ส่งออก
    LCD_DISPLAY : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) -- แสดงผลบนหน้าจอ LCD
  );
END MAIN;

ARCHITECTURE Behavioral OF MAIN IS
  -- สัญญาณภายในสำหรับการสื่อสารระหว่างโมดูล
  SIGNAL current_state, next_state : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL message_buffer : STD_LOGIC_VECTOR(239 DOWNTO 0);
  SIGNAL char_index : INTEGER RANGE 0 TO 29;
  SIGNAL last_char : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL char_timer, key_timer : INTEGER RANGE 0 TO 30000000;
BEGIN
  -- การเชื่อมต่อโมดูลย่อย
  State_Control : ENTITY STATE_MANAGER
    PORT MAP(
      CLK => CLK,
      RESET => RESET,
      PB1 => PB1,
      PB2 => PB2,
      PB3 => PB3,
      PB4 => PB4,
      PB5 => PB5,
      PB6 => PB6,
      current_state => current_state,
      next_state => next_state,
      L0 => L0
    );

  Print_Control : ENTITY PRINT_MANAGER
    PORT MAP(
      CLK => CLK,
      RESET => RESET,
      SW0 => SW0,
      PB1 => PB1,
      PB2 => PB2,
      PB3 => PB3,
      PB4 => PB4,
      char_index => char_index,
      last_char => last_char,
      message_buffer => message_buffer,
      char_timer => char_timer,
      key_timer => key_timer,
      LCD_DISPLAY => LCD_DISPLAY
    );

  -- Send_Control: entity work.Send_Manager
  --     port map (
  --         PB6 => PB6,
  --         char_index => char_index,
  --         message_buffer => message_buffer,
  --         MESSAGE_OUT => MESSAGE_OUT,
  --         next_state => next_state
  --     );
END Behavioral;