defmodule Cddbp.CommandHandler.Motd do
  @moduledoc false

  use Cddbp.CommandHandler, usage: "MOTD"

  def help, do: "Displays the message of the day."

  def handle(state, []) do
    recent_lookups =
      Cdigw.Stats.list_recent_albums()
      |> Enum.map_join("\n", fn {artist, title} -> String.pad_trailing(artist, 30) <> title end)

    state
    |> puts("210 MOTD follows (until terminating `.')")
    |> puts("Welcome to this CDDB server.")
    |> puts("Here are some recent album lookups:")
    |> puts(recent_lookups)
    |> puts(".")
    |> finish_response()
  end

  def handle(state, _), do: cmd_syntax_error(state)
end
