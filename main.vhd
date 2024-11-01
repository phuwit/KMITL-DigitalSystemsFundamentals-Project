LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY MAIN IS
  PORT (
    PB : IN STD_LOGIC_VECTOR(6 DOWNTO 1);
    SW0 : IN STD_LOGIC;
    LED : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)

  );
END MAIN;

ARCHITECTURE Behavioral OF MAIN IS

  COMPONENT INPUT_DECODER IS
    PORT (
      pb : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
      sw0 : IN STD_LOGIC;
      command : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
  END COMPONENT;

BEGIN
  U_INPUT_DECODER : INPUT_DECODER
  PORT MAP(
    pb => PB(6 DOWNTO 1),
    sw0 => SW0,
    command => LED
  );
END Behavioral;