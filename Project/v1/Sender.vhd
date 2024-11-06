library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.globals.all;

entity Sender is
    port(
        clk                : in  STD_LOGIC; -- สัญญาณนาฬิกา
        reset              : in  STD_LOGIC; -- เมื่อมีการกดปุ่มส่งใหม่ ต้องรีเซ็ตด้วย
        current_state      : in  STATES;
        message_buffer     : in  STD_LOGIC_VECTOR(239 downto 0);
        data_stream_in_ack : in  STD_LOGIC; -- คือ 1 เมื่อยืนยันว่าโมดูลได้เริ่มส่งข้อมูลแล้ว
        tx_start           : out STD_LOGIC; -- ต่อกับ data_stream_in_stb 
        data_out           : out STD_LOGIC_VECTOR(7 downto 0) -- ต่อกับ data_stream_in
    );
end Sender;

architecture Behavioral of Sender is
    signal byte_index : integer range 0 to 29 := 0; -- ดัชนีสำหรับการส่งแต่ละไบต์
    signal sending_flag : std_logic := '0'; -- สัญญาณบอกสถานะการส่งข้อมูล
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                byte_index <= 0;
                tx_start <= '0';
                sending_flag <= '0';
                data_out <= x"00";
            elsif current_state = SENDING then
                if sending_flag = '0' then
                    -- เริ่มการส่งอักษรแรก
                    data_out <= message_buffer((byte_index * 8) + 7 downto byte_index * 8); -- ส่งข้อมูล 8 บิตต่อครั้ง
                    tx_start <= '1'; -- เริ่มส่ง
                    sending_flag <= '1'; -- ตั้งค่าสถานะการส่ง
                elsif data_stream_in_ack = '1' then
                    -- เมื่อได้รับการยืนยันว่าเริ่มส่งแล้ว
                    tx_start <= '0'; -- หยุดการส่ง
                    sending_flag <= '0'; -- รีเซ็ตสถานะการส่ง

                    -- เตรียมส่งอักษรถัดไป
                    if byte_index < 29 then
                        byte_index <= byte_index + 1;
                    else
                        byte_index <= 0; -- รีเซ็ตเมื่อส่งครบ 30 ไบต์
                    end if;
                end if;
            else
                tx_start <= '0'; -- ไม่อยู่ในสถานะ SENDING
                sending_flag <= '0';
            end if;
        end if;
    end process;
end Behavioral;
