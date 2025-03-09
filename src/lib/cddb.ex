defmodule Cddb do
  @moduledoc """
  High level interface and configuration for CDDB
  """

  # Official list of genres in the CDDB protocol, but it seems that just about
  # any string is acceptable and indeed found in CDDB resources.
  @genres ~w[data folk jazz misc rock country blues newage reggae classical soundtrack]

  @doc """
  Default protocol version when not specified by the client.

  Valid levels are 1 - 6
  """
  def default_proto, do: 5

  @doc """
  Line ending to use in CDDB responses.

  The CDDB protocol specifies that `\\n`, `\\r\\n`, and `\\r` are all valid.
  """
  def line_separator, do: "\n"

  @doc """
  Terminator for message replies.
  """
  def eof_marker, do: "."

  @doc """
  Default list of known genres as specified in the CDDB protocol.
  """
  def genres, do: @genres

  @doc """
  All discs need a genre. Use this as the default.
  """
  def default_genre, do: "misc"

  @doc """
  Get the encoding name and encoded response appropriate for the `proto` level.

  When encoding for ISO-8859-1, invalid chars are replaced with `"?"`

      iex> Cddb.encode_response("Łódźstraße", 6)
      {"utf-8", "Łódźstraße"}

      iex> Cddb.encode_response("Łódźstraße", 5)
      {"iso-8859-1", "?\\xF3d?stra\\xDFe"}
  """
  def encode_response(response, proto) do
    case proto do
      6 ->
        {"utf-8", response}

      _ ->
        {"iso-8859-1", Encoding.to_latin1(response)}
    end
  end

  @doc """
  Lookup a disc by an unparsed query or disc info list.

  This is a higher level interface to the CDDB request parser, MusicBrainz,
  and the cache.

  Found discs are written to the cache.
  """
  def lookup_disc(query, context) when is_list(query) do
    with {:ok, disc_info} <- Cddb.RequestParser.parse_query(query),
         do: lookup_disc(disc_info, context)
  end

  def lookup_disc(disc_info, context) when is_map(disc_info) do
    context =
      context
      |> Map.put(:query, disc_info.query)
      |> Map.put_new(:interface, "cddb")

    case MusicBrainz.find_release(disc_info.length_seconds, disc_info.track_lbas) do
      {:ok, releases} ->
        # cddb effectively uses genre and disc ID as a composite key, so it
        # makes no sense to return disc with duplicated values.
        discs =
          releases
          |> Enum.map(&MusicBrainz.release_to_disc(disc_info.disc_id, &1))
          |> Enum.uniq_by(fn disc -> {disc.genre, disc.id} end)
          |> maybe_cache_discs()

        [disc | _] = discs

        context
        |> Map.put(:title, disc.title)
        |> Map.put(:artist, disc.artist)
        |> Cdigw.Stats.log_successful_query()

        {:ok, discs}

      {:error, reason} ->
        Cdigw.Stats.log_unsuccessful_query(context)

        {:error, reason}
    end
  end

  @doc "Read a disc from the cache by `genre` and `disc_id`"
  def get_cached_disc(genre, disc_id) do
    case Cdigw.Cache.get(cache_key(disc_id, genre)) do
      nil -> {:error, :not_found}
      disc -> {:ok, disc}
    end
  end

  defp maybe_cache_discs([]), do: []

  defp maybe_cache_discs(discs) do
    for disc <- discs, do: Cdigw.Cache.put(cache_key(disc.id, disc.genre), disc)
    discs
  end

  defp cache_key(disc_id, genre) do
    String.downcase("#{disc_id}-#{genre}")
  end
end
