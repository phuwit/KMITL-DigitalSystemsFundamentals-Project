library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity Printer is
    port(
        clk            : in    STD_LOGIC;
        current_state  : in    STD_LOGIC_VECTOR(1 downto 0);    -- สัญญาณบอกสถานะปัจจุบัน
        mode_select    : in    STD_LOGIC;                       -- สวิตช์เลือกโหมด (0 = โหมดตัวอักษร, 1 = โหมดตัวเลข)
        btn            : in    std_logic_vector(5 downto 1);
        btn_reset      : in    STD_LOGIC;
        last_char      : inout STD_LOGIC_VECTOR(7 downto 0);    -- ตัวอักษรล่าสุดที่เลือก
        message_buffer : out   STD_LOGIC_VECTOR(239 downto 0);  -- บัฟเฟอร์สำหรับเก็บข้อความ
        char_index     : out   INTEGER range 0 to 29            -- ดัชนีของตัวอักษรใน buffer (เปลี่ยนเป็นพอร์ต out)
    );
end Printer;

architecture Behavioral of Printer is
    constant key_hold_time : integer := 60_000_000;
    signal key_timer               : INTEGER range 0 to key_hold_time    := 0;                   -- ตัวนับการกดปุ่ม
    signal internal_message_buffer : STD_LOGIC_VECTOR(239 downto 0) := (others => '0');     -- บัฟเฟอร์ภายในสำหรับเก็บข้อความ
    signal char_index_internal     : INTEGER range 0 to 29          := 29;                   -- ตัวแปรภายในสำหรับจัดการ char_index
    signal trigger                 : STD_LOGIC                      := '0';                 -- ใช้เก็บสถานะ ('0' หรือ '1') เพื่อบอกว่ามีการเพิ่มตัวอักษรลงใน internal_message_buffer แล้วหรือยัง

begin
    process(clk, btn_reset)
    begin
        if btn_reset = '1' then
            key_timer               <= 0;
            char_index_internal     <= 29;
            trigger                 <= '0';
            last_char               <= "01000001";          -- ค่าเริ่มต้นเป็น 'A'
            internal_message_buffer <= (others => '0');     -- เคลียร์ค่าใน message_buffer
        elsif rising_edge(clk) then
            if current_state = "01" then -- ตรวจสอบว่าสถานะเป็น PRINTING (รหัส "01")
                if mode_select = '0' then
                    -- โหมดตัวอักษร
                    if btn(1) = '1' then
                        -- ตัวอักษร 'A' ถึง 'G'
                        if last_char >= "01000001" and last_char < "01000111" then
                            last_char <= STD_LOGIC_VECTOR(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        else
                            last_char <= "01000001"; -- กลับไปที่ 'A'
                        end if;
                        key_timer <= 0;
                    elsif btn(2) = '1' then
                        -- ตัวอักษร 'H' ถึง 'N'
                        if last_char >= "01001000" and last_char < "01001110" then
                            last_char <= STD_LOGIC_VECTOR(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        else
                            last_char <= "01001000"; -- กลับไปที่ 'H'
                        end if;
                        key_timer <= 0;
                    elsif btn(3) = '1' then
                        -- ตัวอักษร 'O' ถึง 'U'
                        if last_char >= "01001111" and last_char < "01010101" then
                            last_char <= STD_LOGIC_VECTOR(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        else
                            last_char <= "01001111"; -- กลับไปที่ 'O'
                        end if;
                        key_timer <= 0;
                    elsif btn(4) = '1' then
                        -- ตัวอักษร 'V' ถึง 'Z'
                        if last_char >= "01010110" and last_char < "01011010" then
                            last_char <= STD_LOGIC_VECTOR(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
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
                            last_char <= STD_LOGIC_VECTOR(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        else
                            last_char <= "00110000"; -- กลับไปที่ '0'
                        end if;
                        key_timer <= 0;
                    elsif btn(2) = '1' then
                        -- ตัวเลข '4' ถึง '6'
                        if last_char >= "00110100" and last_char < "00110110" then -- '4' ถึง '6'
                            last_char <= STD_LOGIC_VECTOR(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
                        else
                            last_char <= "00110100"; -- กลับไปที่ '4'
                        end if;
                        key_timer <= 0;
                    elsif btn(3) = '1' then
                        -- ตัวเลข '7' ถึง '9'
                        if last_char >= "00110111" and last_char < "00111001" then -- '7' ถึง '9'
                            last_char <= STD_LOGIC_VECTOR(to_unsigned(to_integer(unsigned(last_char)) + 1, 8));
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
                    if char_index_internal > 0 then
                        char_index_internal <= char_index_internal + 1;
                        internal_message_buffer((char_index_internal * 8) + 7 downto (char_index_internal * 8)) <= "00000000";          -- เคลียร์ข้อมูลที่ตำแหน่งล่าสุด
                    end if;
                    last_char <= x"00";
                    key_timer <= 0;     -- รีเซ็ตตัวนับเวลา
                end if;

                -- ตรวจสอบการกดปุ่มเพื่อเริ่มนับเวลา
                if btn(1) = '1' or btn(2) = '1' or btn(3) = '1' or btn(4) = '1' or btn(5) = '1' then
                    key_timer <= 0; -- รีเซ็ตตัวนับเวลาเพื่อเริ่มนับใหม่เมื่อมีการกดปุ่ม
                    trigger <= '0'; -- รีเซ็ต trigger เมื่อมีการกดปุ่ม
                else
                    -- นับเวลาเมื่อไม่มีการกดปุ่ม
                    if key_timer < key_hold_time then
                        key_timer <= key_timer + 1;
                    end if;
                end if;

                -- การตรวจสอบเวลาสำหรับการเพิ่มตัวอักษรลงใน `internal_message_buffer`
                if key_timer >= key_hold_time and trigger = '0' then -- 3 วินาทีและยังไม่ได้ทริกเกอร์
                    if char_index_internal > 0 then
                        internal_message_buffer((char_index_internal * 8) + 7 downto (char_index_internal * 8)) <= last_char;
                        char_index_internal <= char_index_internal - 1;
                        key_timer <= key_hold_time;      -- หยุดการนับเวลา (ค้างไว้ที่ค่าเดิม)
                        trigger <= '1';             -- ตั้ง trigger เพื่อบอกว่ามีการเพิ่มตัวอักษรแล้ว
                        last_char <= "01000001";    -- reset กลับไปที่ 'A'
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