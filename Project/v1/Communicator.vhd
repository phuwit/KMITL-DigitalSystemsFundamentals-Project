library IEEE;
use IEEE.std_logic_1164.all;
use work.Globals.all;

entity Communicator is
    generic(
        clk_freq     : integer := 20_000_000;
        baud         : integer := 115_200;
        message_size : integer := 240);
    port(
        clk              : in  std_logic;
        reset            : in  std_logic;
        bt_rx            : in  std_logic;
        current_state    : in  states;
        edit_buffer      : in  std_logic_vector(message_size - 1 downto 0);
        recieve_buffer   : out std_logic_vector(message_size - 1 downto 0);
        bt_tx            : out std_logic;
        send_finished    : out std_logic;
        recieve_complete : out std_logic);
end Communicator;

architecture Behavioral of Communicator is
    constant recieve_clear_delay_time : integer := 5;

    signal uart_send_start    : std_logic := '0';
    -- signal uart_recieve_start : std_logic                    := '0';
    signal uart_recieve_start : std_logic;
    signal uart_send_ack      : std_logic := '0';
    signal uart_send_data     : std_logic_vector(7 downto 0) := (others => '0');
    -- signal uart_recieve_data  : std_logic_vector(7 downto 0) := (others => '0');
    -- signal uart_send_data     : std_logic_vector(7 downto 0);
    signal uart_recieve_data  : std_logic_vector(7 downto 0);

    -- signal recieve_complete_internal : std_logic := '0';
    -- signal recieve_dff_i             : std_logic_vector(message_size - 1 downto 0) := (others => '0');
    -- signal recieve_clear             : std_logic := '0';
    -- signal recieve_clear_dff_mem     : std_logic_vector(recieve_clear_delay_time - 1 downto 0) := (others => '0');
    signal recieve_complete_internal : std_logic;
    signal recieve_dff_i             : std_logic_vector(message_size - 1 downto 0);
    signal recieve_clear             : std_logic;
    signal recieve_clear_dff_mem     : std_logic_vector(recieve_clear_delay_time - 1 downto 0);
begin
    sender_inst : entity work.Sender
        generic map(
            message_size => message_size)
        port map(
            clk                => clk,
            reset              => reset,
            current_state      => current_state,
            edit_buffer        => edit_buffer,
            send_finished      => send_finished,
            data_stream_in_ack => uart_send_ack,
            tx_start           => uart_send_start,
            data_out           => uart_send_data
        );

    recieve_latch : entity work.fdc_wide
        generic map(
            data_width => message_size
        )
        port map(
            d_o => recieve_buffer,
            clk => recieve_complete_internal,
            clr => reset,
            d_i => recieve_dff_i
        );

    recieve_clear_dff_mem(0) <= recieve_complete_internal;
    g_recieve_dffs : for i in 0 to recieve_clear_delay_time - 2 generate
        recieve_dff : entity work.fdc
            port map(
                d_o => recieve_clear_dff_mem(i + 1),
                clk => clk,
                clr => reset,
                d_i => recieve_clear_dff_mem(i)
            );
    end generate;

    recieve_clear <= recieve_clear_dff_mem(recieve_clear_delay_time - 1) or reset;
    receiver_inst : entity work.Receiver
        generic map(
            message_size => message_size)
        port map(
            clk               => clk,
            reset             => recieve_clear,
            data_in           => uart_recieve_data,
            new_data_stb      => uart_recieve_start,
            data_out          => recieve_dff_i,
            data_complete_stb => recieve_complete_internal
        );

    uart_inst : entity work.Uart
        generic map(
            baud            => baud,
            clock_frequency => clk_freq
        )
        port map(
            clock               => clk,
            reset               => reset,
            data_stream_in      => uart_send_data,
            data_stream_in_stb  => uart_send_start,
            data_stream_in_ack  => uart_send_ack,
            data_stream_out     => uart_recieve_data,
            data_stream_out_stb => uart_recieve_start,
            tx                  => bt_tx,
            rx                  => bt_rx
        );
    recieve_complete <= recieve_complete_internal;
end Behavioral;
