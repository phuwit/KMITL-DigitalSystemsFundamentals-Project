library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.Globals.all;

entity Controller is
    port(
        clk                 : in  STD_LOGIC; -- สัญญาณนาฬิกา
        reset               : in  STD_LOGIC; -- สัญญาณรีเซ็ต
        btn                 : in  std_logic_vector(6 downto 1);
        new_data_in         : in  STD_LOGIC; -- สัญญาณที่บอกว่ามีข้อมูลใหม่เข้ามา *Uart_Receiver
        bluetooth_connected : in  STD_LOGIC; -- สัญญาณที่บอกว่าวงจรได้เชื่อมต่อกับบลูทูธแล้ว 1=เชื่อม 0=ไม่เชื่อม
        message_buffer      : in  STD_LOGIC_VECTOR(239 downto 0); -- บัฟเฟอร์สำหรับเก็บข้อความ
        send_finished       : in  STD_LOGIC; -- สถานะการส่งข้อมูล (กำลังส่งหรือไม่) *UART_Transmitter
        current_state       : out STATES; -- สถานะปัจจุบันของระบบ
        L0                  : out STD_LOGIC; -- ไฟแสดงสถานะการทำงานของระบบ
        alert_signal        : out STD_LOGIC -- สัญญาณแจ้งเตือนผู้ใช้งาน
    );
end Controller;

architecture Behavioral of Controller is
    -- มีสถานะ 3 แบบได้แก่ RECEIVING, PRINTING, SENDING มีค่าเป็น 00 01 10
    signal state      : STATES                       := RECEIVING;
    signal idle_timer : integer range 0 to 250000000 := 0; -- ตัวนับเวลา 5 วินาที
begin
    process(clk, reset)
    begin
        if reset = '1' then
            state        <= RECEIVING;  -- รีเซ็ตกลับไปที่สถานะ RECEIVING
            L0           <= '0';        -- ปิดไฟแสดงสถานะ
            alert_signal <= '0';        -- ปิดสัญญาณแจ้งเตือน
            idle_timer   <= 0;          -- รีเซ็ตตัวนับเวลา
        elsif rising_edge(clk) then
            case state is
                when RECEIVING =>       -- สถานะ RECEIVING
                    L0 <= '0';          -- ปิดไฟแสดงสถานะ
                    if new_data_in = '1' then
                        alert_signal <= '1'; -- แจ้งเตือนผู้ใช้งาน
                        -- แสดงผลข้อมูลบนหน้าจอ lcd ทันที (เพิ่มการเชื่อมต่อกับโมดูล lcd ที่นี่)
                    end if;

                    -- ตรวจสอบว่ามีการกดปุ่มเพื่อเข้าสู่สถานะ PRINTING
                    if (btn(1) = '1' or btn(2) = '1' or btn(3) = '1' or btn(4) = '1' or btn(5) = '1') then
                        state <= PRINTING;
                        L0    <= '1';   -- เปิดไฟแสดงสถานะเพื่อแสดงว่าระบบกำลังทำงาน
                    end if;

                when PRINTING =>        -- สถานะ PRINTING
                    alert_signal <= '0'; -- ปิดสัญญาณแจ้งเตือนเมื่อพิมพ์ข้อความ
                    idle_timer   <= 0;  -- รีเซ็ตตัวนับเวลา

                    -- ตรวจสอบว่า `message_buffer` ไม่มีข้อความ
                    if idle_timer >= 250000000 then -- 5 วินาที
                        if message_buffer = (239 downto 0 => '0') then
                            state        <= RECEIVING; -- กลับไปสถานะ RECEIVING
                            alert_signal <= '0'; -- ปิดการแจ้งเตือน
                            idle_timer   <= 0; -- รีเซ็ตตัวนับเวลา
                        end if;
                    else
                        if btn(1) = '0' and btn(2) = '0' and btn(3) = '0' and btn(4) = '0' and btn(5) = '0' then
                            idle_timer <= idle_timer + 1; -- เพิ่มตัวนับเวลา เมื่อไม่มีการกดปุ่ม
                        else
                            idle_timer <= 0;
                        end if;
                    end if;

                    -- ตรวจสอบว่า btn(6) ถูกกดและมีข้อความใน `message_buffer`
                    if btn(6) = '1' then
                        if message_buffer /= (239 downto 0 => '0') and bluetooth_connected = '1' then
                            state <= SENDING; -- เปลี่ยนไปสถานะ SENDING ถ้ามีข้อความ
                        end if;
                    elsif new_data_in = '1' then
                        alert_signal <= '1'; -- แจ้งเตือนผู้ใช้งาน
                    end if;

                when SENDING =>         -- สถานะ SENDING
                    if send_finished = '1' then
                        state <= RECEIVING; -- เปลี่ยนกลับไปสถานะ RECEIVING หลังจากส่งข้อความเสร็จสิ้น
                        L0    <= '0';   -- ปิดไฟแสดงสถานะ
                    end if;
            end case;
        end if;
    end process;

    current_state <= state;             -- กำหนดสถานะปัจจุบัน
end Behavioral;
