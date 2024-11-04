LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY ControllerTest_TOP IS
   PORT (
      clk : IN STD_LOGIC;
      btn : IN STD_LOGIC_VECTOR(6 DOWNTO 1);
      sw : IN STD_LOGIC_VECTOR(7 DOWNTO 0);

      led : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      mn : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);

      lcd_en : OUT STD_LOGIC;
      lcd_rs : OUT STD_LOGIC;
      lcd_rw : OUT STD_LOGIC;
      lcd_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
   );
END ControllerTest_TOP;

ARCHITECTURE Behavioral OF ControllerTest_TOP IS
   SIGNAL btn_debounced : STD_LOGIC_VECTOR(6 DOWNTO 1);
   SIGNAL btn_pulse : STD_LOGIC_VECTOR(6 DOWNTO 1);

   SIGNAL current_state, next_state : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";

   SIGNAL message_buffer : STD_LOGIC_VECTOR(239 DOWNTO 0);
   SIGNAL char_index : INTEGER RANGE 0 TO 29;
   SIGNAL last_char : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL char_timer, key_timer : INTEGER RANGE 0 TO 30000000;
BEGIN

   btn_debounced(4 DOWNTO 1) <= btn(4 DOWNTO 1);
   g_btn_debounce : FOR i IN 5 TO 6 GENERATE
      DEBOUNCE_inst : ENTITY work.DEBOUNCE
         PORT MAP(
            clk => clk,
            reset_n => '1',
            button => btn(i),
            result => btn_debounced(i)
         );
   END GENERATE;

   g_btn_pulse : FOR i IN 1 TO 6 GENERATE
      EDGE_DETECTOR_inst : ENTITY work.EDGE_DETECTOR
         PORT MAP(
            i_clk => clk,
            i_rstb => '1',
            i_input => btn_debounced(i),
            o_pulse => btn_pulse(i)
         );

   END GENERATE;

   Print_Manager_inst : ENTITY work.Print_Manager
      PORT MAP(
         clk => clk,
         current_state => current_state,
         mode_select => sw(0),
         btn => btn_pulse(5 DOWNTO 1),
         btn_reset => btn_pulse(6),
         last_char => last_char,
         message_buffer => message_buffer,
         char_index => char_index
      );

   lcd_controller_inst : ENTITY work.lcd_controller
      PORT MAP(
         clk => clk,
         reset_n => '1',
         line1_buffer => message_buffer(239 DOWNTO 112),
         line2_buffer => message_buffer(111 DOWNTO 0) & x"2020",
         rw => lcd_rw,
         rs => lcd_rs,
         e => lcd_en,
         lcd_data => lcd_data
      );

   led <= (others => '0');
   led(1 downto 0) <= current_state;

   mn <= last_char;
END Behavioral;