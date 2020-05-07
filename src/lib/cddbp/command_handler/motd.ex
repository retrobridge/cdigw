defmodule Cddbp.CommandHandler.Motd do
  @moduledoc false

  use Cddbp.CommandHandler, usage: "MOTD"

  def help, do: "Displays the message of the day."

  def handle(state, []) do
    state
    |> puts("210 MOTD follows (until terminating `.')")
    |> puts("Welcome to this CDDB server.")
    |> puts(".")
    |> finish_response()
  end

  def handle(state, _), do: cmd_syntax_error(state)
end
