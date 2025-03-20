defmodule Cddbp.Helpers do
  @moduledoc """
  Helpers for dealing with commands and responses.

  There's some module boundary-crossing going on here to fetch configuration
  and server information and better to have it all in one place than spread
  across all the modules in Cddbp.
  """

  require Logger

  alias Cddbp.{CommandHandler, State}

  @newline Cddb.line_separator()

  @doc """
  Get server configuration.

  Needed by some commands that tell the client about the server
  """
  def server_config, do: Cdigw.cddbp_config()

  @doc "Get a specific server configuration attribute."
  def server_config(param, default \\ nil) do
    server_config() |> Keyword.get(param, default)
  end

  @doc "Get server software version"
  def server_version, do: Cdigw.version()

  @doc "Get server software name"
  def server_software, do: "cdigw"

  def sites, do: Cdigw.sites()

  @doc "Return a syntax error response and increment state error counter"
  def cmd_syntax_error(state), do: error(state, "500 Command syntax error.")
  def unrecognized_command(state), do: error(state, "500 Unrecognized command.")

  defp error(state, message) do
    state = state |> State.increment_errors() |> puts(message)

    if state.errors >= server_config(:max_errors) do
      state
      |> CommandHandler.Quit.handle([])
    else
      finish_response(state)
    end
  end

  @doc "Finish event handling and return the new state"
  def finish_response(state), do: {:noreply, state, state.timeout}

  @doc "Terminate the user's session using a normal GenServer `stop`"
  def end_session(state), do: {:stop, :normal, state}

  @doc "Send text to the client, no newline."
  def write(%{transport: transport, socket: socket} = state, text) do
    Logger.debug(fn -> "> #{String.trim_trailing(text)}" end)

    transport.send(socket, text)
    state
  end

  @doc "Send a response string followed by a newline"
  def puts(state, text) when is_binary(text) do
    write(state, text <> @newline)
  end

  def puts(state, lines) when is_list(lines) do
    Enum.each(lines, &puts(state, &1))
    state
  end
end
