defmodule Cddbp.CommandHandler.Quit do
  @moduledoc """
  End the session and disconnect the TCP socket
  """

  use Cddbp.CommandHandler, usage: "QUIT"

  def help, do: "Close database server connection."

  def handle(state, []) do
    state
    |> puts_line("230 #{server_config(:hostname)} Closing connection. Goodbye.")
    |> end_session()
  end

  def handle(state, _), do: cmd_syntax_error(state)
end
