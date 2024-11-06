library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.globals.all;

entity Sender is
    port(
        clk            : in  std_logic;
        current_state  : in  STATES;    -- สัญญาณบอกสถานะปัจจุบัน
        message_buffer : in  STD_LOGIC_VECTOR(239 downto 0);
        tx_start       : out STD_LOGIC  -- สัญญาณเริ่มต้นการส่งข้อมูล
    );
end Sender;

architecture Behavioral of Sender is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if current_state = SENDING and message_buffer /= (239 downto 0 => '0') then
                tx_start <= '1';
            else
                tx_start <= '0';
            end if;
        end if;
    end process;
end Behavioral;
