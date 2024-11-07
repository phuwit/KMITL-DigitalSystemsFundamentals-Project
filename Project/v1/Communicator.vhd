library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.Globals.all;

entity Communicator is
    generic(
        clk_freq     : INTEGER := 20_000_000;
        baud         : INTEGER := 115_200;
        message_size : integer := 240);
    port(
        clk              : in  STD_LOGIC;
        bt_rx            : in  std_logic;
        current_state    : in  STATES;
        edit_buffer      : in  std_logic_vector(message_size - 1 downto 0);
        recieve_buffer   : out std_logic_vector(message_size - 1 downto 0);
        bt_tx            : out std_logic;
        send_finished    : out std_logic;
        recieve_complete : out std_logic);
end Communicator;

architecture Behavioral of Communicator is
    signal uart_send_start    : STD_LOGIC;
    signal uart_recieve_start : STD_LOGIC;
    signal uart_send_ack      : std_logic;
    signal uart_send_data     : std_logic_vector(7 downto 0);
    signal uart_recieve_data  : std_logic_vector(7 downto 0);
begin
    sender_inst : entity work.Sender
        generic map(
            message_size => message_size)
        port map(
            clk                => clk,
            reset              => '0',
            current_state      => current_state,
            edit_buffer        => edit_buffer,
            send_finished      => send_finished,
            data_stream_in_ack => uart_send_ack,
            tx_start           => uart_send_start,
            data_out           => uart_send_data
        );

    receiver_inst : entity work.Receiver
        generic map(
            message_size => message_size)
        port map(
            clk               => clk,
            data_in           => uart_recieve_data,
            new_data_stb      => uart_recieve_start,
            data_out          => recieve_buffer,
            data_complete_stb => recieve_complete
        );

    uart_inst : entity work.Uart
        generic map(
            baud            => baud,
            clock_frequency => clk_freq
        )
        port map(
            clock               => clk,
            reset               => '0',
            data_stream_in      => uart_send_data,
            data_stream_in_stb  => uart_send_start,
            data_stream_in_ack  => uart_send_ack,
            data_stream_out     => uart_recieve_data,
            data_stream_out_stb => uart_recieve_start,
            tx                  => bt_tx,
            rx                  => bt_rx
        );

end Behavioral;
