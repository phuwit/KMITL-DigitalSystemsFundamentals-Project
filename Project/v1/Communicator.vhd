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
    constant reciever_reset_delay : integer := 3;

    signal uart_send_start    : std_logic;
    signal uart_recieve_start : std_logic;
    signal uart_send_ack      : std_logic;
    signal uart_send_data     : std_logic_vector(7 downto 0);
    signal uart_recieve_data  : std_logic_vector(7 downto 0);

    signal recieve_complete_internal : std_logic;
    signal reciever_reset            : std_logic;
    signal reciever_reset_shr        : std_logic_vector(reciever_reset_delay - 1 downto 0);
    signal recieve_buffer_dff_i      : std_logic_vector(message_size - 1 downto 0);
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

    recieve_buffer_dff : entity work.fdc_wide
        generic map(
            data_width => message_size
        )
        port map(
            d_o => recieve_buffer,
            clk => recieve_complete_internal,
            clr => reset,
            d_i => recieve_buffer_dff_i
        );

    reciever_reset_shr(0) <= recieve_complete_internal;
    g_reciever_reset_shr : for i in 1 to reciever_reset_delay - 1 generate
        debounce_inst : entity work.fdc
            port map(
                d_o => reciever_reset_shr(i),
                clk => clk,
                clr => reset,
                d_i => reciever_reset_shr(i - 1)
            );
    end generate;

    reciever_reset <= reset or reciever_reset_shr(reciever_reset_delay - 1);
    receiver_inst : entity work.Receiver
        generic map(
            message_size => message_size)
        port map(
            clk               => clk,
            reset             => reciever_reset,
            data_in           => uart_recieve_data,
            new_data_stb      => uart_recieve_start,
            data_out          => recieve_buffer_dff_i,
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
