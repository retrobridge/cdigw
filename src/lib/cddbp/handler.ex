defmodule Cddbp.Handler do
  @moduledoc """
  Handler for CDDBP sessions  
  """

  use GenServer
  require Logger

  @app_version Cdigw.version()

  def start_link(ref, socket, transport, _opts) do
    pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, socket, transport])
    {:ok, pid}
  end

  @doc false
  def init(opts), do: {:ok, opts}

  @doc false
  def init(ref, socket, transport) do
    peername = socket_to_peername(socket)

    Logger.info("new connection from #{peername}")

    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, active: true)

    now = DateTime.utc_now() |> DateTime.to_iso8601()

    state = %{
      socket: socket,
      transport: transport,
      peername: peername,
      proto: 1,
      hello: nil,
      errors: 0,
      last_command_at: DateTime.utc_now()
    }

    send_line(
      state,
      "201 #{server_config(:hostname)} CDDBP server v#{@app_version} ready at #{now}"
    )

    :gen_server.enter_loop(__MODULE__, [], state)
  end

  def handle_info({:tcp, _, message}, state) do
    [cmd | args] = String.split(message, ~r/\s+/, trim: true)
    cmd = String.downcase(cmd)

    Logger.info("<<< #{state.peername}: cmd=#{cmd} args=#{inspect(args)}")

    state = Map.put(state, :last_command_at, DateTime.utc_now())

    handle_cmd(cmd, args, state)
  end

  def handle_info({:tcp_closed, _}, state) do
    Logger.info("#{state.peername} disconnected")

    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _, reason}, state) do
    Logger.info("TCP error with #{state.peername}: #{inspect(reason)}")

    {:stop, :normal, state}
  end

  def handle_cmd("cddb", [cmd | args], state) do
    handle_cddb_cmd(cmd, args, state)
  end

  def handle_cmd("help", [], state) do
    send_line(state, "210 OK, help information follows (until terminating `.')")

    send_line(state, ~s"""
    The following commands are supported:

    CDDB [ HELLO | LSCAT | QUERY | READ ]
    HELP [command [subcmd]]
    MOTD
    PROTO [level]
    QUIT
    SITES
    STAT
    VER
    WHOM

    This is a read-only CDDB protocol (CDDBP) CD database server, used for
    finding and retrieving CDDB-format CD metadata.

    If you have questions or comments, visit #{server_config(:hostname)}.
    .
    """)

    {:noreply, state}
  end

  def handle_cmd("help", _, state), do: cmd_syntax_error(state)

  def handle_cmd("motd", [], state) do
    send_line(state, "210 MOTD follows (until terminating `.')")
    send_line(state, "Welcome to the CDDBP server of #{server_config(:hostname)}")
    send_line(state, ".")
    {:noreply, state}
  end

  def handle_cmd("motd", _, state), do: cmd_syntax_error(state)

  def handle_cmd("proto", [], %{proto: proto} = state) do
    send_line(state, "200 CDDB protocol level: current #{proto}, supported 6")
    {:noreply, state}
  end

  def handle_cmd("proto", [new_proto], state) do
    case Integer.parse(new_proto) do
      :error ->
        cmd_syntax_error(state)

      {level, _} when level < 1 or level > 6 ->
        {:noreply, send_line(state, "500 Illegal CDDB protocol level.")}

      {level, _} ->
        send_line(state, "201 OK, CDDB protocol level now: #{level}")
        Map.put(state, :proto, level)
        {:noreply, state}
    end
  end

  def handle_cmd("proto", _, state), do: cmd_syntax_error(state)

  def handle_cmd("quit", [], state) do
    send_line(state, "230 #{server_config(:hostname)} Closing connection. Goodbye.")

    {:stop, :normal, state}
  end

  def handle_cmd("quit", _, state), do: cmd_syntax_error(state)

  def handle_cmd("sites", [], state) do
    send_line(state, "210 OK, site information follows (until terminating `.')")

    send_line(
      state,
      "#{server_config(:hostname)} #{server_config(:cddb_http_port)} N000.00 W000.00 Primary CDDB HTTP Server"
    )

    {:noreply, state}
  end

  def handle_cmd("sites", _, state), do: cmd_syntax_error(state)

  def handle_cmd("ver", [], state) do
    send_line(state, "200 cddbd v#{@app_version} #{server_config(:hostname)}")
    {:noreply, state}
  end

  def handle_cmd("ver", _, state), do: cmd_syntax_error(state)

  def handle_cmd("whom", [], state) do
    send_line(state, "401 No user information available.")
    {:noreply, state}
  end

  def handle_cmd("whom", _, state), do: cmd_syntax_error(state)

  def handle_cmd(cmd, args, state) do
    Logger.info("unknown command cmd=#{cmd} args=#{inspect(args)}")

    state = Map.update(state, :errors, 0, &(&1 + 1))
    send_line(state, "500 Unrecognized command.")

    {:noreply, state}
  end

  def handle_cddb_cmd("hello", [user, host, app, ver], %{hello: nil} = state) do
    state = Map.put(state, :hello, %{user: user, host: host, app: app, version: ver})
    send_line(state, "200 Hello and welcome #{user}@#{host} running #{app} #{ver}")
    {:noreply, state}
  end

  def handle_cddb_cmd("hello", [_user, _host, _app, _ver], state) do
    send_line(state, "402 Already shook hands.")
    {:noreply, state}
  end

  def handle_cddb_cmd("lscat", [], state) do
    send_line(state, "210 OK, category list follows (until terminating `.')")
    Enum.each(Cddb.genres(), &send_line(state, &1))
    send_line(state, ".")
    {:noreply, state}
  end

  def handle_cddb_cmd("lscat", _, state), do: cmd_syntax_error(state)

  def handle_cddb_cmd("query", _args, state) do
    # centralise the logic from the plug. it's exactly the same

    {:noreply, state}
  end

  def handle_cddb_cmd("read", [_genre, _disc_id], state) do
    # centralise the logic from the plug. it's exactly the same
    {:noreply, state}
  end

  def handle_cddb_cmd("read", _, state), do: cmd_syntax_error(state)

  def handle_cddb_cmd(_, _, state), do: cmd_syntax_error(state)

  def cmd_syntax_error(state) do
    state = Map.update(state, :errors, 0, &(&1 + 1))
    send_line(state, "500 Command syntax error.")
    {:noreply, state}
  end

  defp server_config, do: Cdigw.server_config()

  defp server_config(param, default \\ nil) do
    server_config() |> Map.get(param, default)
  end

  defp send_line(%{transport: transport, socket: socket} = state, line) do
    transport.send(socket, line <> "\n")
    state
  end

  defp socket_to_peername(socket) do
    {:ok, {addr, port}} = :inet.peername(socket)

    address = addr |> :inet_parse.ntoa() |> to_string()

    "#{address}:#{port}"
  end
end
