library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Sender is
    Port (
        current_state  : in  STD_LOGIC_VECTOR(1 downto 0); -- สัญญาณบอกสถานะปัจจุบัน
        message_buffer : in STD_LOGIC_VECTOR(239 downto 0);
        tx_start       : out STD_LOGIC;        -- สัญญาณเริ่มต้นการส่งข้อมูล
        data_out       : out STD_LOGIC_VECTOR(239 downto 0); -- ข้อมูลที่จะส่งไปยัง uart_tx
        trigger        : out STD_LOGIC        -- พอร์ตเอาต์พุตสำหรับเก็บสถานะการทริกเกอร์
    );
end Sender;

architecture Behavioral of Sender is
begin
    process (current_state)
    begin
        if current_state = "10" and message_buffer /= (others => '0') then -- ตรวจสอบว่าสถานะปัจจุบันเป็น SENDING
            data_out <= message_buffer; -- ส่งข้อมูลจาก message_buffer
            tx_start <= '1';             -- ส่งสัญญาณเริ่มต้นการส่งข้อมูล
        else
            tx_start <= '0';             -- หยุดสัญญาณเมื่อไม่ใช่สถานะ SENDING
        end if;
    end process;
end Behavioral;
