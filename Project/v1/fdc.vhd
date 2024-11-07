library ieee;
use ieee.std_logic_1164.all;

entity fdc is
    port(
        d_o : out std_logic;
        clk : in  std_logic;
        clr : in  std_logic;
        d_i : in  std_logic);
end fdc;

architecture Behavioral of fdc is
begin
    process(clk, clr)
    begin
        if clr = '1' then
            d_o <= '0';
        elsif (rising_edge(clk)) then
            d_o <= d_i;
        end if;
    end process;
end Behavioral;
