library ieee;
use ieee.std_logic.all;

entity INPUT_DECODER is
    port(
            pb: in std_logic_vector(5 downto 0);
            sw0: in std_logic;
            command: out std_logic_vector(3 downto 0);
        );
end INPUT_DECODER;

architecture Behavioural of INPUT_DECODER is
    signal decoded_button: std_logic_vector(2 downto 0);
begin
    decoded_button(0) <= '1' when (pb2='1' or pb4='1' or pb6='1') else '0';
    decoded_button(1) <= '1' when (pb3='1' or pb4='1') else '0';
    decoded_button(2) <= '1' when (pb5='1' or pb6='1') else '0';
    command <= sw0&decoded_button;
end Behavioural;