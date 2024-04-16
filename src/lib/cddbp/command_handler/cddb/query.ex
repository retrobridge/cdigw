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
    user_agent =
      case state.hello do
        %{app: app, version: version} ->
          "#{app}/#{version}"

        _ ->
          nil
      end

    context = %{host: state.peername, user_agent: user_agent, interface: "cddbp"}

    case Cddb.lookup_disc(query, context) do
      {:ok, discs} ->
        text = Cddb.QueryResponse.render(discs, state.proto)
        {_encoding, text} = Cddb.encode_response(text, state.proto)

        state
        |> write(text)
        |> finish_response()

      {:error, _reason} ->
        state
        |> puts("403 Server error.")
        |> finish_response()
    end
  end

  def handle(state, _), do: cmd_syntax_error(state)
end
