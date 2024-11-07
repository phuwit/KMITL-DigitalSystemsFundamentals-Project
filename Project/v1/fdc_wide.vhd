library ieee;
use ieee.std_logic_1164.all;

entity fdc_wide is
    generic(
        data_width : integer);
    port(
        d_o : out std_logic_vector(data_width - 1 downto 0);
        clk : in  std_logic;
        clr : in  std_logic;
        d_i : in  std_logic_vector(data_width - 1 downto 0));
end fdc_wide;

architecture Behavioral of fdc_wide is
begin
    process(clk, clr)
    begin
        if clr = '1' then
            d_o <= (others => '0');
        elsif (rising_edge(clk)) then
            d_o <= d_i;
        end if;
    end process;
end Behavioral;