library IEEE;
use IEEE.std_logic_1164.all;

entity InputCleaner is
    generic(
        clk_freq           : integer := 20_000_000;
        btn_stable_time    : integer := 20;
        btn_count          : integer := 6;
        btn_debounce_start : integer := 4;
        sw_stable_time     : integer := 50
    );
    port(
        clk     : in  std_logic;
        btn_i   : in  std_logic_vector(btn_count - 1 downto 0);
        sw_i    : in  std_logic;
        dipsw_i : in  std_logic;
        btn_o   : out std_logic_vector(btn_count - 1 downto 0);
        sw_o    : out std_logic;
        dipsw_o : out std_logic);
end InputCleaner;

architecture Behavioral of InputCleaner is
    signal btn_debounced   : std_logic_vector(btn_count - 1 downto 0);
    signal btn_pulse       : std_logic_vector(btn_count - 1 downto 0);
    signal sw_debounced    : std_logic;
    signal dipsw_debounced : std_logic;
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

    sw_debounce_inst : entity work.Debounce
        generic map(
            clk_freq    => clk_freq,
            stable_time => sw_stable_time
        )
        port map(
            clk     => clk,
            reset_n => '1',
            button  => sw_i,
            result  => sw_debounced
        );

    debounce_inst : entity work.Debounce
        generic map(
            clk_freq    => clk_freq,
            stable_time => sw_stable_time
        )
        port map(
            clk     => clk,
            reset_n => '1',
            button  => dipsw_i,
            result  => dipsw_debounced
        );

    g_btn_pulse : for i in 0 to btn_count - 1 generate
        edge_detector_inst : entity work.EdgeDetector
            port map(
                i_clk   => clk,
                i_rstb  => '1',
                i_input => btn_debounced(i),
                o_pulse => btn_pulse(i)
            );
    end generate;

    btn_o   <= btn_pulse;
    sw_o    <= sw_debounced;
    dipsw_o <= dipsw_debounced;
end Behavioral;
