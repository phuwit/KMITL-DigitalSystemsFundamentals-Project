LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY STATE_MANAGER IS
  PORT (
    CLK : IN STD_LOGIC; -- สัญญาณนาฬิกา
    RESET : IN STD_LOGIC; -- สัญญาณรีเซ็ต
    PB1, PB2, PB3, PB4, PB5, PB6 : IN STD_LOGIC; -- ปุ่มกดสำหรับควบคุมการเปลี่ยนสถานะ
    new_data_in : IN STD_LOGIC; -- สัญญาณที่บอกว่ามีข้อมูลใหม่เข้ามา
    message_buffer : IN STD_LOGIC_VECTOR(239 DOWNTO 0); -- บัฟเฟอร์สำหรับเก็บข้อความ
    current_state : OUT STD_LOGIC_VECTOR(1 DOWNTO 0); -- สถานะปัจจุบันของระบบ
    next_state : OUT STD_LOGIC_VECTOR(1 DOWNTO 0); -- สถานะถัดไปของระบบ
    L0 : OUT STD_LOGIC; -- ไฟแสดงสถานะการทำงานของระบบ
    alert_signal : OUT STD_LOGIC -- สัญญาณแจ้งเตือนผู้ใช้งาน
  );
END STATE_MANAGER;

ARCHITECTURE Behavioral OF STATE_MANAGER IS
  TYPE STATE_TYPE IS (RECEIVING, PRINTING, SENDING); -- ประเภทของสถานะ
  SIGNAL state : STATE_TYPE := RECEIVING; -- กำหนดสถานะเริ่มต้นเป็น RECEIVING
  SIGNAL idle_timer : INTEGER RANGE 0 TO 250000000 := 0; -- ตัวนับเวลา 5 วินาที
  SIGNAL data_waiting : STD_LOGIC := '0'; -- บอกว่ามีข้อมูลใหม่รออยู่หรือไม่
BEGIN
  PROCESS (CLK, RESET)
  BEGIN
    IF RESET = '1' THEN
      state <= RECEIVING; -- รีเซ็ตกลับไปที่สถานะ RECEIVING
      L0 <= '0'; -- ปิดไฟแสดงสถานะ
      alert_signal <= '0'; -- ปิดสัญญาณแจ้งเตือน
      idle_timer <= 0; -- รีเซ็ตตัวนับเวลา
      data_waiting <= '0'; -- ไม่มีข้อมูลใหม่ที่รออยู่
    ELSIF rising_edge(CLK) THEN
      CASE state IS
        WHEN RECEIVING =>
          L0 <= '0'; -- ปิดไฟแสดงสถานะ
          IF new_data_in = '1' THEN
            data_waiting <= '1'; -- มีข้อมูลใหม่เข้ามา
            alert_signal <= '1'; -- แจ้งเตือนผู้ใช้งาน
          END IF;

          -- ตรวจสอบว่ามีการกดปุ่มเพื่อเข้าสู่สถานะ PRINTING
          IF (PB1 = '1' OR PB2 = '1' OR PB3 = '1' OR PB4 = '1' OR PB5 = '1' OR PB6 = '1') THEN
            state <= PRINTING;
            L0 <= '1'; -- เปิดไฟแสดงสถานะเพื่อแสดงว่าระบบกำลังทำงาน
            idle_timer <= 0; -- รีเซ็ตตัวนับเวลา
          ELSIF idle_timer >= 250000000 THEN -- 5 วินาที
            -- ตรวจสอบว่า `message_buffer` ไม่มีข้อความ
            IF message_buffer = (OTHERS => '0') THEN
              state <= RECEIVING; -- กลับไปสถานะรับข้อมูล
              alert_signal <= '0'; -- ปิดการแจ้งเตือน
              data_waiting <= '0'; -- ล้างสถานะข้อมูลรอ
              idle_timer <= 0; -- รีเซ็ตตัวนับเวลา
            END IF;
          ELSE
            idle_timer <= idle_timer + 1; -- เพิ่มตัวนับเวลา
          END IF;

        WHEN PRINTING =>
          alert_signal <= '0'; -- ปิดสัญญาณแจ้งเตือนเมื่อพิมพ์ข้อความ
          idle_timer <= 0; -- รีเซ็ตตัวนับเวลา

          -- ตรวจสอบว่า PB6 ถูกกดและมีข้อความใน `message_buffer`
          IF PB6 = '1' THEN
            IF message_buffer /= (OTHERS => '0') THEN
              state <= SENDING; -- เปลี่ยนไปสถานะ SENDING ถ้ามีข้อความ
            END IF;
          ELSIF new_data_in = '1' THEN
            data_waiting <= '1'; -- มีข้อมูลใหม่เข้ามาในขณะที่พิมพ์ข้อความ
            alert_signal <= '1'; -- แจ้งเตือนผู้ใช้งาน
          END IF;

        WHEN SENDING =>
          state <= RECEIVING; -- เปลี่ยนกลับไปสถานะ RECEIVING หลังจากส่งข้อความเสร็จสิ้น
          L0 <= '0'; -- ปิดไฟแสดงสถานะ

        WHEN OTHERS =>
          state <= RECEIVING; -- กรณีเกิดข้อผิดพลาด เปลี่ยนกลับไปสถานะเริ่มต้น
      END CASE;
    END IF;
  END PROCESS;

  current_state <= state; -- กำหนดสถานะปัจจุบัน
  next_state <= state; -- กำหนดสถานะถัดไป
END Behavioral;