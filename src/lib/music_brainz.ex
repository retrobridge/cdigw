defmodule MusicBrainz do
  @moduledoc """
  Client library for accessing the MusicBrainz API over HTTP
  """
  use Tesla
  import Ext.Enum, only: [dig: 2]
  alias Cddb.Disc

  # To not get rate-limited, we have to provide a `user-agent` header
  # that includes the app name, version, and contact info.
  @app_version Mix.Project.config()[:version]
  @app_url "https://github.com/retrobridge/cdigw"
  @user_agent "CDIGW/#{@app_version} (#{@app_url})"

  @sectors_per_second 75
  @default_inc ["artists", "recordings", "genres"]
  @default_genre Cddb.default_genre()

  plug Tesla.Middleware.Logger
  plug Tesla.Middleware.BaseUrl, "https://musicbrainz.org/ws/2"
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Headers, [{"user-agent", @user_agent}]

  @doc """
  Calculate the DiscID using the lead-out LBA and track LBAs.

  There are 4 components that go into the hash:

  * First track number (2-char hex)
  * Last track number (2-char hex)
  * Lead-out track LBA (8-char hex)
  * 99 track LBAs (8-char hex, each)

  When there are fewer than 99 tracks, `0` is the LBA to use.

  The hex must be upper-case. The list is then hashed with *SHA-1* and
  base64-encoded. MusicBrainz uses non-standard url-encoding. The mapping is:

  * `+` => `.`
  * `/` => `_`
  * `=` => `-`

  ### Example

      iex> MusicBrainz.calculate_disc_id(205072, [150, 15239, 29625, 45763, 61420, 75862, 91642, 108918, 123698, 139895, 153589, 169239, 188495])
      "J9dlQIdlpgKkwDn.nHo8SlQ0ks4-"
  """
  def calculate_disc_id(lead_out_lba, track_lbas) do
    track_count = length(track_lbas)

    track_lbas_hex = Enum.map(track_lbas, fn lba -> to_padded_hex(lba, 8) end)
    padding = Enum.map(1..(99 - track_count), fn _ -> "00000000" end)

    # we're assuming the first track is track is track 1 and the last track
    # is the count of tracks
    first_tnum_hex = "01"
    last_tnum_hex = to_padded_hex(track_count, 2)
    lead_out_lba_hex = to_padded_hex(lead_out_lba, 8)

    data = [first_tnum_hex, last_tnum_hex, lead_out_lba_hex | track_lbas_hex ++ padding]

    :crypto.hash(:sha, data) |> mb_url_encode64()
  end

  @doc """
  Find a disc by its track LBA TOC and either length in seconds or lead-out LBA.

  When coming from a CDDB query, we know:

    * the length of the CD in seconds
    * the sector where each audio track begins (TOC)

  When coming from an MSCD query, we know the TOC and lead-out LBA.

  To query for a CD by TOC, we need to know the sector where the lead-out
  track begins. We can guess this by multiplying the sectors per second (75)
  by the seconds of audio on the disc.

  MusicBrainz has a fuzzy search, so if our lead-out LBA is off by a bit, we'll
  probably still match on our CD, but also other discs with a similar TOC.
  Since we know what the audio track TOC is though, we can match on it exactly
  to find our disc amongst the multiple results.
  """
  def find_releases(%{track_lbas: toc, length_seconds: secs}) do
    find_releases(%{track_lbas: toc, lead_out_lba: secs * @sectors_per_second})
  end

  def find_releases(%{track_lbas: track_lbas, lead_out_lba: lead_out_lba}) do
    toc = ensure_int_list(track_lbas)
    track_count = length(toc)
    toc_query = [1, track_count, lead_out_lba] ++ toc

    case fuzzy_search_by_toc(toc_query) do
      {:ok, %{status: 200, body: body}} ->
        matches =
          body
          |> Map.get("releases")
          |> Enum.filter(fn rel -> any_toc_matches?(rel, toc) end)

        {:ok, matches}

      other ->
        {:error, other}
    end
  end

  @doc """
  Both CDDB and MSCD think in terms of a disc and not a release/album.
  For multi-disc releases, we have to combine data from the release with the
  track listing.
  """
  def find_discs(%{track_lbas: toc} = disc_info) do
    case find_releases(disc_info) do
      {:ok, releases} ->
        # Select the disc that matches the TOC.
        # We may also be able to select by calculated MB disc ID, at least for MSCD
        discs = releases_to_discs(releases, fn m -> toc_matches?(m, toc) end)

        {:ok, discs}

      {:error, reason} ->
        {:error, reason}

      other ->
        {:error, other}
    end
  end

  defp releases_to_discs(releases, matcher) when is_function(matcher) do
    Enum.map(releases, fn release ->
      year = year_from_date(release["date"])

      disc = %Disc{
        artist: groom_text(dig(release, ["artist-credit", 0, "name"])),
        title: groom_text(release["title"]),
        year: year,
        genre: genre(release["genres"])
      }

      # Get track data from the "media" element that has a matching TOC
      wanted_disc = Enum.find(release["media"], matcher)

      Enum.reduce(wanted_disc["tracks"], disc, fn track, disc ->
        title = groom_text(dig(track, ["recording", "title"]))
        Disc.add_track(disc, title)
      end)
    end)
  end

  defp year_from_date(nil), do: nil

  defp year_from_date(str) do
    case Regex.named_captures(~r/^(?<year>\d{4})-/, str) do
      %{"year" => str} ->
        str

      _ ->
        nil
    end
  end

  # A release is an album that may have multiple discs. To see if this release
  # is a match to the given CD, see if any of the discs have a matching TOC.
  defp any_toc_matches?(release, toc) do
    Enum.any?(release["media"], fn media -> toc_matches?(media, toc) end)
  end

  # A disc has one or more media elements. Find the one with the matching TOC
  defp toc_matches?(medium, toc) do
    Enum.any?(medium["discs"], fn disc -> disc["offsets"] == toc end)
  end

  @doc """
  Fetch releases matching the disc ID derived from track data.
  """
  def get_releases_by_disc_id(id, inc \\ @default_inc) do
    inc_list = Enum.join(inc, "+")

    case get("/discid/#{id}/?fmt=json&inc=#{inc_list}") do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      other ->
        {:error, other}
    end
  end

  @doc """
  Find a disc by a full TOC.

  For example, a disc with 13 tracks would be:

  1 13 205072 150 15239 29625 45763 61420 75862 91642 108918 123698 139895 153589 169239 188495

  1: First track number
  13: Last track number
  205072: LBA of the lead-out track
  Everything else is the LBA of the audio tracks

  As this is a fuzzy search, expect multiple results.

  https://musicbrainz.org/doc/Development/XML_Web_Service/Version_2#Non-MBID_Lookups
  """
  def fuzzy_search_by_toc(toc, inc \\ @default_inc) do
    inc_list = Enum.join(inc, "+")
    get("/discid/-?fmt=json&inc=#{inc_list}&toc=" <> Enum.join(toc, "+"))
  end

  # Some chars cause display issues on older systems and can easily be substituted
  defp groom_text(txt) do
    txt
    |> String.replace("’", "'")
    |> String.replace("…", "...")
    |> String.replace("‐", "-")
    |> String.replace("“", "\"")
    |> String.replace("”", "\"")
  end

  defp genre([]), do: @default_genre
  defp genre(nil), do: @default_genre

  defp genre(genres) do
    genres
    |> Enum.map(fn %{"name" => name} -> name |> String.split() |> hd() end)
    |> Enum.find(@default_genre, fn name -> Enum.member?(Cddb.genres(), name) end)
  end

  defp ensure_int_list(items) do
    Enum.map(items, fn
      item when is_integer(item) -> item
      item when is_binary(item) -> String.to_integer(item)
    end)
  end

  # hex-encode a number and zero-pad it to the given `len`
  defp to_padded_hex(number, len) do
    number |> Integer.to_string(16) |> String.pad_leading(len, "0")
  end

  # base64-encode some data using the custom MusicBrainz url-encoding
  defp mb_url_encode64(data) do
    data
    |> Base.encode64()
    |> String.replace("+", ".")
    |> String.replace("/", "_")
    |> String.replace("=", "-")
  end
end
