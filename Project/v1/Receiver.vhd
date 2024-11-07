library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity Receiver is
    generic(
        message_size : integer := 240);
    port(
        clk               : in  STD_LOGIC;
        data_in           : in  STD_LOGIC_VECTOR(7 downto 0); -- ข้อมูลตัวอักษรที่รับมา
        new_data_stb      : in  STD_LOGIC; -- สัญญาณว่ามีตัวอักษรใหม่มา
        data_out          : out STD_LOGIC_VECTOR(message_size - 1 downto 0); -- ผลรวมของอักษร 30 ตัว
        data_complete_stb : out STD_LOGIC -- สัญญาณว่ารวมของอักษร 30 ตัวเสร็จแล้ว
        -- สัญญาณ data_complete_stb จะเป็น '1' ชั่วขณะเมื่อมีการรับข้อมูลครบ 30 ตัว
    );
end Receiver;

architecture Behavioral of Receiver is
    signal internal_buffer : STD_LOGIC_VECTOR(message_size - 1 downto 0) := (others => '0');
    signal char_count      : integer range 0 to 29                       := 29;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- รีเซ็ตสัญญาณเมื่อเริ่มต้นการทำงานใหม่
            data_complete_stb <= '0';

            if new_data_stb = '1' then
                if char_count >= 0 then
                    -- ใส่อักขระใหม่เข้าไปในตำแหน่งที่เหมาะสมใน buffer
                    internal_buffer((char_count * 8) + 7 downto char_count * 8) <= data_in;
                    char_count                                                  <= char_count - 1;

                    -- ตรวจสอบว่ารับครบ 30 ตัวหรือไม่
                    if char_count = 0 then
                        data_complete_stb <= '1'; -- แจ้งว่าข้อมูลครบ 30 ตัวแล้ว
                    end if;
                else
                    char_count <= 29;   -- รีเซ็ตการนับเมื่อรับครบ 30 ตัวอักษร
                end if;
            end if;
        end if;
    end process;

    -- ส่งข้อมูลจาก buffer ออกไป
    data_out <= internal_buffer;
end Behavioral;
