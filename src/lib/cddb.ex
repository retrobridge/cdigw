defmodule Cddb do
  import Bitwise

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

    case MusicBrainz.find_discs(disc_info) do
      {:ok, discs} ->
        # cddb effectively uses genre and disc ID as a composite key, so it
        # makes no sense to return disc with duplicated values.
        discs =
          discs
          |> Enum.map(fn disc -> Map.put(disc, :id, disc_info.disc_id) end)
          |> Enum.uniq_by(fn disc -> {disc.genre, disc.id} end)
          |> maybe_cache_discs()

        log_disc_result(context, discs)

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

  @doc """
  Calculate the CDDB Disc ID given the disc structure

  https://courses.cs.duke.edu/cps006g/fall04/class/isis/freedb.pdf

      iex> Cddb.calculate_disc_id(%{length_seconds: 4519, track_lbas: [150, 18064, 34719, 48510, 64506, 82409, 99569, 117860, 137646, 147539, 166275, 184290, 205587, 223455, 241522, 258378, 275550, 294931, 320173]})
      "1f11a513"

      iex> Cddb.calculate_disc_id(%{lead_out_lba: 338952, track_lbas: [150, 18064, 34719, 48510, 64506, 82409, 99569, 117860, 137646, 147539, 166275, 184290, 205587, 223455, 241522, 258378, 275550, 294931, 320173]})
      "1f11a513"
  """
  def calculate_disc_id(%{track_lbas: toc, lead_out_lba: lead_out_lba}) do
    calculate_disc_id(%{track_lbas: toc, length_seconds: floor(lead_out_lba / 75)})
  end

  def calculate_disc_id(%{track_lbas: track_lbas, length_seconds: length_seconds}) do
    # On a music CD, each second is stored across 75 frames or sectors of the disc.
    # Each LBA offset indicates how many frames/sectors into the disc the track starts.
    frames_per_second = 75

    # Tracks are not necessarily stored in evenly divisible numbers of frames.
    # CDDB doesn't include partial frame numbers for this calculation.
    second_offsets = Enum.map(track_lbas, fn lba -> floor(lba / frames_per_second) end)

    # Each second offset's digits are tallied e.g. "152" => 1 + 5 + 2 = 8
    n =
      Enum.reduce(second_offsets, 0, fn sec, acc ->
        sec
        |> Integer.digits()
        |> Enum.sum()
        |> Kernel.+(acc)
      end)
      |> Kernel.rem(0xFF)

    # CDDB queries don't explicitly send where the leadout starts but we
    # can take an educated guess based on the total length and the first track offset.
    leadout_sec = length_seconds - Enum.at(second_offsets, 0)
    track_count = Enum.count(track_lbas)

    tot = n <<< 24 ||| leadout_sec <<< 8 ||| track_count

    tot
    |> Integer.to_string(16)
    |> String.pad_leading(8, "0")
    |> String.downcase()
  end

  defp maybe_cache_discs([]), do: []

  defp maybe_cache_discs(discs) do
    for disc <- discs, do: Cdigw.Cache.put(cache_key(disc.id, disc.genre), disc)
    discs
  end

  defp cache_key(disc_id, genre) do
    String.downcase("#{disc_id}-#{genre}")
  end

  defp log_disc_result(context, []) do
    Cdigw.Stats.log_unsuccessful_query(context)
  end

  defp log_disc_result(context, [disc | _]) do
    context
    |> Map.put(:title, disc.title)
    |> Map.put(:artist, disc.artist)
    |> Cdigw.Stats.log_successful_query()
  end
end
