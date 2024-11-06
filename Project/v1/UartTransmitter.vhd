library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity UartTransmitter is
    generic(
        clk_freq  : INTEGER := 20_000_000; --system clock frequency in Hz
        baud_rate : INTEGER := 115_200
    );
    port(
        clk      : in  STD_LOGIC;       -- สัญญาณนาฬิกา
        reset    : in  STD_LOGIC;       -- สัญญาณรีเซ็ต
        tx_start : in  STD_LOGIC;       -- สัญญาณเริ่มต้นการส่งข้อมูล
        data_in  : in  STD_LOGIC_VECTOR(239 downto 0); -- ข้อมูล 240 บิตที่ต้องการส่ง
        tx       : out STD_LOGIC;       -- เอาต์พุตข้อมูลแบบอนุกรมที่ส่งออกทีละบิต
        tx_busy  : out STD_LOGIC        -- สถานะที่บอกว่าโมดูลกำลังทำงานส่งข้อมูล ('1') หรือว่าง ('0')
        -- ตรวจสอบการส่งข้อมูลเสร็จสิ้นได้โดยการตรวจเช็คค่า tx_busy หากเป็น '0', หมายความว่าการส่งข้อมูลเสร็จสิ้นและโมดูลอยู่ในสถานะพัก (IDLE)
    );
end UartTransmitter;

architecture Behavioral of UartTransmitter is
    constant BAUD_TICK_COUNT : integer := clk_freq / baud_rate; -- จำนวนรอบนาฬิกาต่อบอด

    type state_type is (IDLE, START, DATA, STOP, LOAD_NEXT); -- สถานะของ state machine
    signal state        : state_type                             := IDLE; -- สถานะเริ่มต้น
    signal baud_counter : integer range 0 to BAUD_TICK_COUNT - 1 := 0;
    signal bit_index    : integer range 0 to 7                   := 0;
    signal byte_index   : integer range 0 to 239                 := 0;
    signal tx_reg       : STD_LOGIC_VECTOR(239 downto 0);
    signal tx_out       : STD_LOGIC                              := '1'; -- สถานะเริ่มต้น (idle)

begin
    tx      <= tx_out;
    tx_busy <= '1' when (state /= IDLE) else '0'; -- แสดงสถานะการส่งข้อมูล

    process(clk, reset)
    begin
        if reset = '1' then
            -- รีเซ็ตการทำงาน
            state        <= IDLE;
            baud_counter <= 0;
            bit_index    <= 0;
            byte_index   <= 0;
            tx_out       <= '1';
            tx_reg       <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if tx_start = '1' then
                        -- เริ่มการส่งข้อมูลเมื่อกด tx_start
                        state      <= START;
                        tx_reg     <= data_in;
                        bit_index  <= 0;
                        byte_index <= 0;
                        tx_out     <= '0'; -- บิตเริ่มต้น
                    end if;

                when START =>
                    if baud_counter >= BAUD_TICK_COUNT - 1 then
                        baud_counter <= 0;
                        state        <= DATA;
                    else
                        baud_counter <= baud_counter + 1;
                    end if;

                when DATA =>
                    if baud_counter >= BAUD_TICK_COUNT - 1 then
                        -- ส่งบิตข้อมูลปัจจุบัน
                        baud_counter <= 0;
                        tx_out       <= tx_reg((byte_index * 8) + bit_index);
                        if bit_index >= 7 then
                            bit_index <= 0;
                            if byte_index >= 29 then -- ส่งครบ 240 บิต (30 bytes)
                                state <= STOP;
                            else
                                state <= LOAD_NEXT; -- ส่ง byte ถัดไป
                            end if;
                        else
                            bit_index <= bit_index + 1;
                        end if;
                    else
                        baud_counter <= baud_counter + 1;
                    end if;

                when LOAD_NEXT =>
                    byte_index <= byte_index + 1;
                    state      <= START; -- เริ่มส่ง byte ถัดไป

                when STOP =>
                    if baud_counter = BAUD_TICK_COUNT - 1 then
                        baud_counter <= 0;
                        tx_out       <= '1'; -- บิตหยุด
                        state        <= IDLE;
                    else
                        baud_counter <= baud_counter + 1;
                    end if;
            end case;
        end if;
    end process;
end Behavioral;
