library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UartReciever is
    Port (
        clk         : in  STD_LOGIC;       -- สัญญาณนาฬิกา
        reset       : in  STD_LOGIC;       -- สัญญาณรีเซ็ต
        rx          : in  STD_LOGIC;       -- สัญญาณรับข้อมูล (Rx)
        data_out    : out STD_LOGIC_VECTOR(239 downto 0); -- ข้อมูลทั้งหมดที่รับได้ (30 ไบต์)
        data_ready  : out STD_LOGIC        -- สัญญาณที่ใช้แจ้งเตือนเมื่ออ่านข้อมูลครบทั้ง 30 ตัวอักษรแล้ว
    );
end UartReciever;

architecture Behavioral of UartReciever is
    constant BAUD_RATE : integer := 9600;       -- อัตราบอด
    constant CLOCK_FREQ : integer := 50000000;  -- ความถี่ของสัญญาณนาฬิกา (50 MHz)
    constant BAUD_TICK_COUNT : integer := CLOCK_FREQ / BAUD_RATE; -- จำนวนรอบนาฬิกาต่อบอด
    constant SAMPLE_POINT : integer := BAUD_TICK_COUNT / 2; -- จุดสุ่มตัวอย่างกลางบิต

    type state_type is (IDLE, START, DATA, STOP); -- ประเภทสถานะใน state machine
    signal state : state_type := IDLE; -- สถานะเริ่มต้นคือ IDLE
    signal baud_counter : integer := 0; -- ตัวนับรอบนาฬิกาสำหรับจับเวลาอัตราบอด
    signal bit_index : integer := 0; -- ตัวนับบิตที่กำลังรับ
    signal char_index : integer range 0 to 29 := 0; -- ตัวนับตำแหน่งของตัวอักษรในบัฟเฟอร์
    signal shift_reg : STD_LOGIC_VECTOR(7 downto 0) := (others => '0'); -- เรจิสเตอร์เก็บข้อมูลที่รับมา
    signal message_buffer : STD_LOGIC_VECTOR(239 downto 0) := (others => '0'); -- บัฟเฟอร์สำหรับเก็บข้อความที่รับมา

begin
    -- สัญญาณแสดงว่าข้อมูลพร้อมอ่านเมื่อครบ 30 ไบต์
    data_ready <= '1' when (char_index = 30 and state = STOP) else '0';
    data_out <= message_buffer; -- ส่งข้อมูลทั้งหมดที่รับได้ออกไป

    -- กระบวนการของ UART Receiver
    process (clk, reset)
    begin
        if reset = '1' then
            -- รีเซ็ตสถานะทั้งหมด
            state <= IDLE;
            baud_counter <= 0;
            bit_index <= 0;
            char_index <= 0;
            shift_reg <= (others => '0');
            message_buffer <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if rx = '0' then -- ตรวจจับบิตเริ่มต้น
                        state <= START;
                        baud_counter <= 0;
                    end if;

                when START =>
                    if baud_counter = SAMPLE_POINT then
                        -- ตรวจสอบกลางบิตเริ่มต้นเพื่อให้แน่ใจว่าถูกต้อง
                        if rx = '0' then
                            state <= DATA;
                            baud_counter <= 0;
                            bit_index <= 0;
                        else
                            state <= IDLE; -- ถ้าไม่ถูกต้อง กลับไปสถานะ IDLE
                        end if;
                    else
                        baud_counter <= baud_counter + 1;
                    end if;

                when DATA =>
                    if baud_counter = BAUD_TICK_COUNT - 1 then
                        baud_counter <= 0;
                        shift_reg(bit_index) <= rx; -- เก็บบิตข้อมูล
                        if bit_index = 7 then
                            -- ถ้ารับครบ 8 บิต ให้เก็บข้อมูลลงในบัฟเฟอร์
                            message_buffer((char_index * 8) + 7 downto (char_index * 8)) <= shift_reg;
                            if char_index < 29 then
                                char_index <= char_index + 1;
                                state <= IDLE; -- รอรับบิตเริ่มต้นของไบต์ถัดไป
                            else
                                state <= STOP; -- ถ้ารับครบ 30 ไบต์ เปลี่ยนไปสถานะ STOP
                            end if;
                        else
                            bit_index <= bit_index + 1;
                        end if;
                    else
                        baud_counter <= baud_counter + 1;
                    end if;

                when STOP =>
                    if baud_counter = BAUD_TICK_COUNT - 1 then
                        state <= IDLE; -- กลับไปสถานะเริ่มต้นหลังจากรับบิตหยุด
                        baud_counter <= 0;
                    else
                        baud_counter <= baud_counter + 1;
                    end if;

                when others =>
                    state <= IDLE; -- กำหนดสถานะกลับเป็น IDLE ในกรณีที่ไม่รู้จัก
            end case;
        end if;
    end process;
end Behavioral;
