defmodule Cddbp.Handler do
  @moduledoc """
  Handler for CDDBP sessions
  """

  use GenServer
  import Cddbp.Helpers
  require Logger

  @root_handler Cddbp.CommandHandler.Root

  def start_link(ref, transport, opts) do
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, transport, opts])
    {:ok, pid}
  end

  @doc false
  def init(opts), do: {:ok, opts}

  @doc false
  def init(ref, transport, _opts) do
    {:ok, socket} = :ranch.handshake(ref)

    peername = socket_to_peername(socket)

    Logger.info("new connection from #{peername}")

    :ok = transport.setopts(socket, active: true, packet: :line)

    now = DateTime.utc_now() |> Calendar.strftime("%c %Z")

    state = Cddbp.State.new(socket, transport, peername)

    puts(
      state,
      "201 #{server_config(:hostname)} CDDBP server v#{server_version()} ready at #{now}"
    )

    :gen_server.enter_loop(__MODULE__, [], state, state.timeout)
  end

  def handle_info({:tcp, _, message}, state) do
    args = String.split(message, ~r/\s+/, trim: true)

    Logger.info("<<< [#{state.peername}] args=#{inspect(args)}")

    state
    |> Map.put(:last_command_at, DateTime.utc_now())
    |> @root_handler.handle(args)
  end

  def handle_info({:tcp_closed, _}, state) do
    Logger.info("[#{state.peername}] disconnected")
    end_session(state)
  end

  def handle_info({:tcp_error, _, reason}, state) do
    Logger.info("[#{state.peername}] TCP error: #{inspect(reason)}")
    end_session(state)
  end

  def handle_info(:timeout, state) do
    timeout_sec = trunc(state.timeout / 1000)
    Logger.info("[#{state.peername}] timed-out after #{timeout_sec} seconds")

    state
    |> puts("530 Inactivity timeout after #{timeout_sec} seconds, closing connection.")
    |> end_session()
  end

  defp socket_to_peername(socket) do
    {:ok, {addr, port}} = :inet.peername(socket)

    address = addr |> :inet_parse.ntoa() |> to_string()

    "#{address}:#{port}"
  end
end
