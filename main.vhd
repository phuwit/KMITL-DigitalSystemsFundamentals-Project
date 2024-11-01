library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MAIN is
    port (
        PB: in std_logic_vector(6 downto 1);
        SW0: in std_logic;
        COMMAND: out std_logic_vector(3 downto 0)
    );
end MAIN;

architecture Behavioral of MAIN is

    component INPUT_DECODER is
        port (
            pb: in std_logic_vector(5 downto 0);
            sw0: in std_logic;
            command: out std_logic_vector(3 downto 0)
        );
    end component;

begin

    U_INPUT_DECODER: INPUT_DECODER
        port map (
            pb => PB,
            sw0 => SW0,
            command => COMMAND
        );

    -- Additional logic can be added here

end Behavioral;
