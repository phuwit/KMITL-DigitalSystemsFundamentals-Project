library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity InputCleaner is
    generic(
        clk_freq           : INTEGER := 20_000_000;
        btn_stable_time    : INTEGER := 20;
        sw_stable_time     : INTEGER := 50;
        btn_count          : integer := 6;
        btn_debounce_start : integer := 4; -- index start at 0
        sw_count           : integer := 7;
        dipsw_count        : integer := 8
    );
    port(
        clk     : in  STD_LOGIC;
        btn_i   : in  std_logic_vector(btn_count - 1 downto 0);
        sw_i    : in  std_logic_vector(sw_count - 1 downto 0);
        dipsw_i : in  std_logic_vector(dipsw_count - 1 downto 0);
        btn_o   : out std_logic_vector(btn_count - 1 downto 0);
        sw_o    : out std_logic_vector(sw_count - 1 downto 0);
        dipsw_o : out  std_logic_vector(dipsw_count - 1 downto 0));
end InputCleaner;

architecture Behavioral of InputCleaner is
    signal btn_debounced : STD_LOGIC_VECTOR(btn_count - 1 downto 0);
    signal sw_debounced  : STD_LOGIC_VECTOR(sw_count - 1 downto 0);
    signal dipsw_debounced  : STD_LOGIC_VECTOR(dipsw_count - 1 downto 0);
    signal btn_pulse     : STD_LOGIC_VECTOR(btn_count - 1 downto 0);
begin
    btn_debounced(btn_debounce_start - 1 downto 0) <= btn_i(btn_debounce_start - 1 downto 0);
    g_btn_debounce : for i in btn_debounce_start to btn_count - 1 generate
        debounce_inst : entity work.Debounce
            generic map(
                clk_freq    => clk_freq,
                stable_time => btn_stable_time
            )
            port map(
                clk     => clk,
                reset_n => '1',
                button  => btn_i(i),
                result  => btn_debounced(i)
            );
    end generate;

    g_sw_debounce : for i in 0 to sw_count - 1 generate
        debounce_inst : entity work.Debounce
            generic map(
                clk_freq    => clk_freq,
                stable_time => sw_stable_time
            )
            port map(
                clk     => clk,
                reset_n => '1',
                button  => sw_i(i),
                result  => sw_debounced(i)
            );
    end generate;

    g_dipsw_debounce : for i in 0 to sw_count - 1 generate
        debounce_inst : entity work.Debounce
            generic map(
                clk_freq    => clk_freq,
                stable_time => sw_stable_time
            )
            port map(
                clk     => clk,
                reset_n => '1',
                button  => dipsw_i(i),
                result  => dipsw_debounced(i)
            );
    end generate;

    g_btn_pulse : for i in 0 to btn_count - 1 generate
        edge_detector_inst : entity work.EdgeDetector
            port map(
                i_clk   => clk,
                i_rstb  => '1',
                i_input => btn_debounced(i),
                o_pulse => btn_pulse(i)
            );
    end generate;

    btn_o <= btn_pulse;
    sw_o  <= sw_debounced;
    dipsw_o <= dipsw_debounced;
end Behavioral;
