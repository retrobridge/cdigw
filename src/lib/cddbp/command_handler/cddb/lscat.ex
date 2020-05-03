defmodule Cddbp.CommandHandler.Cddb.Lscat do
  @moduledoc false

  use Cddbp.CommandHandler, usage: "LSCAT"

  def help, do: "List all database categories."

  def handle(state, []) do
    puts(state, "210 OK, category list follows (until terminating `.')")
    Enum.each(Cddb.genres(), &puts(state, &1))

    state
    |> puts(".")
    |> finish_response()
  end

  def handle(state, _), do: cmd_syntax_error(state)
end
