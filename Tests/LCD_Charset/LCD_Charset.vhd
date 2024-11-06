LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY LCD_Charset IS
   PORT (
      clk : IN STD_LOGIC;
      btn : IN STD_LOGIC_VECTOR(6 DOWNTO 1);
      sw : IN STD_LOGIC_VECTOR(6 DOWNTO 0);

      led : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      mn : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);

      lcd_en : OUT STD_LOGIC;
      lcd_rs : OUT STD_LOGIC;
      lcd_rw : OUT STD_LOGIC;
      lcd_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
   );
END LCD_Charset;

ARCHITECTURE Behavioral OF LCD_Charset IS
   SIGNAL btn_debounced : STD_LOGIC_VECTOR(6 DOWNTO 1);
   SIGNAL btn_pulse : STD_LOGIC_VECTOR(6 DOWNTO 1);

   SIGNAL current_state, next_state : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";

   SIGNAL message_buffer : STD_LOGIC_VECTOR(255 DOWNTO 0); -- 32 characters * 8 bits
   SIGNAL char_index : INTEGER RANGE 0 TO 255 := 0;
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

   -- Process to cycle through characters on button press
   process(clk)
   begin
       if rising_edge(clk) then
           if btn_pulse(1) = '1' then
               if char_index < 224 then
                   char_index <= char_index + 32;
               else
                   char_index <= 0; -- Reset to first ASCII character
               end if;
               for i in 0 to 31 loop
                   message_buffer(i*8+7 downto i*8) <= std_logic_vector(to_unsigned(char_index + i, 8));
               end loop;
           end if;
       end if;
   end process;

   -- Instantiate the LCD controller
   lcd_controller_inst : entity work.lcd_controller
       port map (
           clk => clk,
           reset_n => '1',
           line1_buffer => message_buffer(255 downto 128),
           line2_buffer => message_buffer(127 downto 0),
           rw => lcd_rw,
           rs => lcd_rs,
           e => lcd_en,
           lcd_data => lcd_data
       );

   led(7 downto 2) <= (others => '0');
   led(1 downto 0) <= current_state;

   mn <= message_buffer(255 downto 248); -- Display the first character of the buffer on mn
END Behavioral;