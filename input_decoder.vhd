LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY INPUT_DECODER IS
  PORT (
    pb : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    sw0 : IN STD_LOGIC;
    command : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
  );
END INPUT_DECODER;

ARCHITECTURE Behavioural OF INPUT_DECODER IS
  SIGNAL decoded_button : STD_LOGIC_VECTOR(2 DOWNTO 0);
BEGIN
  decoded_button(0) <= '1' WHEN (pb2 = '1' OR pb4 = '1' OR pb6 = '1') ELSE
  '0';
  decoded_button(1) <= '1' WHEN (pb3 = '1' OR pb4 = '1') ELSE
  '0';
  decoded_button(2) <= '1' WHEN (pb5 = '1' OR pb6 = '1') ELSE
  '0';
  command <= sw0 & decoded_button;
END Behavioural;