defmodule Cddbp.CommandHandler.Cddb.Read do
  @moduledoc false

  use Cddbp.CommandHandler

  def usage, do: "READ <category> <discid>"

  def help do
    ~S"""
    Retrieve the database entry for the specified CD.
    Arguments are:
        category:  CD category.
        discid:    CD disk ID number.
    """
  end

  def handle(state, [category, disc_id]) do
    case Cddb.get_cached_disc(category, disc_id) do
      {:ok, disc} ->
        state
        |> puts(Cddb.ReadResponse.render(disc, state.proto))
        |> finish_response()

      {:error, :not_found} ->
        state
        |> puts_line("401 #{category} #{disc_id} No such CD entry in database")
        |> finish_response()
    end
  end

  def handle(state, _), do: cmd_syntax_error(state)
end
