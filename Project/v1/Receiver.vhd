library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;

entity Receiver is
    generic(
        message_size : integer := 240);
    port(
        clk               : in  std_logic;
        data_in           : in  std_logic_vector(7 downto 0); -- ข้อมูลตัวอักษรที่รับมา
        new_data_stb      : in  std_logic; -- สัญญาณว่ามีตัวอักษรใหม่มา
        data_out          : out std_logic_vector(message_size - 1 downto 0); -- ผลรวมของอักษร 30 ตัว
        data_complete_stb : out std_logic -- สัญญาณว่ารวมของอักษร 30 ตัวเสร็จแล้ว
        -- สัญญาณ data_complete_stb จะเป็น '1' ชั่วขณะเมื่อมีการรับข้อมูลครบ 30 ตัว
    );
end Receiver;

architecture Behavioral of Receiver is
    signal internal_buffer : std_logic_vector(message_size - 1 downto 0) := (others => '0');
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

                    -- ตรวจสอบว่ารับครบ 30 ตัวหรือไม่หลังจากใส่ข้อมูล
                    if char_count = 0 then
                        data_complete_stb <= '1'; -- แจ้งว่าข้อมูลครบ 30 ตัวแล้ว
                        char_count <= 29; -- รีเซ็ตการนับเมื่อรับครบ 30 ตัวอักษร
                    else
                        char_count <= char_count - 1; -- ลดค่า char_count ลง
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- ส่งข้อมูลจาก buffer ออกไป
    data_out <= internal_buffer;
end Behavioral;
