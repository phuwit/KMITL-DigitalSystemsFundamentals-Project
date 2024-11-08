library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Por is
    generic(
        stop_after : integer
    );
    port(
        reset : in  std_logic;
        clk   : in  std_logic;
        por_o : out std_logic
    );
end entity Por;

architecture rtl of Por is
    signal count        : integer range 0 to stop_after + 2 := 0;
    signal por_internal : std_logic                     := '1';
begin
    process(clk, reset)
    begin
        if reset = '1' then
            por_internal <= '1';
            count        <= 0;
        elsif rising_edge(clk) then
            if count >= stop_after then
                por_internal <= '0';
            else
                count <= count + 1;
            end if;
        end if;
    end process;


    por_o <= por_internal;
end architecture rtl;
