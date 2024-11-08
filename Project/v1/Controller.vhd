library IEEE;
use IEEE.std_logic_1164.all;
use work.Globals.all;

entity Controller is
    generic(
        clk_freq     : integer := 20_000_000;
        message_size : integer := 240);
    port(
        clk                    : in  std_logic; -- สัญญาณนาฬิกา
        reset                  : in  std_logic; -- สัญญาณรีเซ็ต
        btn                    : in  std_logic_vector(6 downto 1);
        bluetooth_connected    : in  std_logic; -- สัญญาณที่บอกว่าวงจรได้เชื่อมต่อกับบลูทูธแล้ว 1=เชื่อม 0=ไม่เชื่อม
        edit_buffer            : in  std_logic_vector(message_size - 1 downto 0); -- บัฟเฟอร์สำหรับเก็บข้อความ
        message_send_complete  : in  std_logic; -- สถานะการส่งข้อมูล (กำลังส่งหรือไม่) *UART_Transmitter
        state                  : out states; -- สถานะปัจจุบันของระบบ
        led0                   : out std_logic;
        bluetooth_send_failed  : out std_logic;
        bluetooth_send_success : out std_logic
    );
end Controller;

architecture Behavioral of Controller is
    constant idle_sec     : integer := 5;
    constant idle_countto : integer := idle_sec * clk_freq;

    signal state_internal : states                          := RECEIVING;
    signal idle_timer     : integer range 0 to idle_countto := 0;
begin
    process(clk, reset)
    begin
        if reset = '1' then
            state_internal         <= RECEIVING; -- รีเซ็ตกลับไปที่สถานะ RECEIVING
            led0                   <= '0'; -- ปิดไฟแสดงสถานะ
            idle_timer             <= 0; -- รีเซ็ตตัวนับเวลา
            bluetooth_send_failed  <= '0';
            bluetooth_send_success <= '0';
        elsif rising_edge(clk) then
            bluetooth_send_failed  <= '0';
            bluetooth_send_success <= '0';
            case state_internal is
                when RECEIVING =>       -- สถานะ RECEIVING
                    led0 <= '0';        -- ปิดไฟแสดงสถานะ

                    -- ตรวจสอบว่ามีการกดปุ่มเพื่อเข้าสู่สถานะ PRINTING
                    if (btn(1) = '1' or btn(2) = '1' or btn(3) = '1' or btn(4) = '1' or btn(5) = '1') then
                        state_internal <= EDITING;
                        led0           <= '1'; -- เปิดไฟแสดงสถานะเพื่อแสดงว่าระบบกำลังทำงาน
                    end if;

                when EDITING =>
                    idle_timer <= 0;    -- รีเซ็ตตัวนับเวลา

                    -- ตรวจสอบว่า `message_buffer` ไม่มีข้อความ
                    if idle_timer >= idle_countto then -- 5 วินาที
                        if edit_buffer = (message_size - 1 downto 0 => '0') then
                            state_internal <= RECEIVING; -- กลับไปสถานะ RECEIVING
                        end if;
                        idle_timer <= 0; -- รีเซ็ตตัวนับเวลา
                    else
                        if btn(1) = '0' and btn(2) = '0' and btn(3) = '0' and btn(4) = '0' and btn(5) = '0' then
                            idle_timer <= idle_timer + 1; -- เพิ่มตัวนับเวลา เมื่อไม่มีการกดปุ่ม
                        else
                            idle_timer <= 0;
                        end if;
                    end if;

                    -- ตรวจสอบว่า btn(6) ถูกกดและมีข้อความใน `message_buffer`
                    if btn(6) = '1' then
                        if edit_buffer /= (message_size - 1 downto 0 => '0') and bluetooth_connected = '1' then
                            bluetooth_send_success <= '1';
                            state_internal <= SENDING; -- เปลี่ยนไปสถานะ SENDING ถ้ามีข้อความ
                        else
                            bluetooth_send_failed <= '0';
                        end if;
                    end if;

                when SENDING =>         -- สถานะ SENDING
                    if message_send_complete = '1' then
                        state_internal <= RECEIVING; -- เปลี่ยนกลับไปสถานะ RECEIVING หลังจากส่งข้อความเสร็จสิ้น
                        led0           <= '0'; -- ปิดไฟแสดงสถานะ
                    end if;
            end case;
        end if;
    end process;

    state <= state_internal;            -- กำหนดสถานะปัจจุบัน
end Behavioral;
