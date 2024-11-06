library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.globals.all;

entity Sender is
    port(
        current_state  : in  STATES;    -- สัญญาณบอกสถานะปัจจุบัน
        message_buffer : in  STD_LOGIC_VECTOR(239 downto 0);
        tx_start       : out STD_LOGIC; -- สัญญาณเริ่มต้นการส่งข้อมูล
        data_out       : out STD_LOGIC_VECTOR(239 downto 0) -- ข้อมูลที่จะส่งไปยัง uart_tx
    );
end Sender;

architecture Behavioral of Sender is
begin
    process(current_state, message_buffer)
    begin
        if current_state = SENDING and message_buffer /= (239 downto 0 => '0') then -- ตรวจสอบว่าสถานะปัจจุบันเป็น SENDING
            data_out <= message_buffer; -- ส่งข้อมูลจาก message_buffer
            tx_start <= '1';            -- ส่งสัญญาณเริ่มต้นการส่งข้อมูล
        else
            tx_start <= '0';            -- หยุดสัญญาณเมื่อไม่ใช่สถานะ SENDING
        end if;
    end process;
end Behavioral;
