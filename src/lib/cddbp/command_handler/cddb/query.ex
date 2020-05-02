defmodule Cddbp.CommandHandler.Cddb.Query do
  @moduledoc false

  use Cddbp.CommandHandler

  def usage, do: "QUERY <discid> <ntrks> <off_1> <off_2> <...> <off_n> <nsecs>"

  def help do
    ~S"""
    Perform a search for database entries that match parameters.
    Arguments are:
      discid:  CD disc ID number.
      ntrks:   total number of tracks on CD.
      off_X:   frame offset of track X.
      nsecs:   total playing length of the CD in seconds.
    """
  end

  def handle(state, query) when is_list(query) do
    case Cddb.lookup_disc(query) do
      {:ok, discs} ->
        state
        |> puts_line(Cddb.QueryResponse.render(discs, state.proto))
        |> finish_response()

      {:error, _reason} ->
        state
        |> puts_line("403 Server error.")
        |> finish_response()
    end
  end

  def handle(state, _), do: cmd_syntax_error(state)
end
