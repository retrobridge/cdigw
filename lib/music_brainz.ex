defmodule MusicBrainz do
  use Tesla

  @app_version Mix.Project.config()[:version]
  @app_url "https://github.com/mroach/cddb_gateway"
  @user_agent "CDDBGateway/#{@app_version} (#{@app_url})"

  @sectors_per_second 75
  @default_inc ["artists", "recordings", "genres"]

  plug(Tesla.Middleware.BaseUrl, "http://musicbrainz.org/ws/2")
  plug(Tesla.Middleware.JSON)
  plug(Tesla.Middleware.Headers, [{"user-agent", @user_agent}])

  @doc """
  Find a disc by its length in seconds and track LBA TOC

  When coming from a CDDB query, we know:

    * the length of the CD in seconds
    * the sector where each audio track begins (TOC)

  To query for a CD by TOC, we also need to know the sector where the lead-out
  track begins. We can guess this by multiplying the sectors per second (75)
  by the seconds of audio on the disc.

  MusicBrainz has a fuzzy search, so if our lead-out LBA is off by a bit, we'll
  probably still match on our CD, but also other discs with a similar TOC.
  Since we know what the audio track TOC is though, we can match on it exactly
  to find our disc amongst the multiple results.
  """
  def find_by_length_and_toc(length_seconds, toc) do
    toc = ensure_int_list(toc)
    guessed_leadout_lba = length_seconds * @sectors_per_second
    track_count = length(toc)
    toc_query = [1, track_count, guessed_leadout_lba] ++ toc

    case fuzzy_search_by_toc(toc_query) do
      {:ok, %{status: 200, body: body}} ->
        matches =
          Enum.filter(body["releases"], fn rel ->
            toc == dig(rel, ["media", 0, "discs", 0, "offsets"])
          end)

        {:ok, matches}

      other ->
        {:error, other}
    end
  end

  def get_release(id, inc \\ @default_inc) do
    inc_list = Enum.join(inc, "+")

    case get("/release/#{id}/?fmt=json&inc=#{inc_list}") do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      other ->
        {:error, other}
    end
  end

  @doc """
  Convert a release to a list of CDDB field/value pairs
  """
  def release_to_cddb(cddb_disc_id, release) do
    artist = dig(release, ["artist-credit", 0, "name"])
    title = release["title"]
    year = String.slice(release["date"], 0..3)
    genre = Enum.at(release["genres"], 0) || "misc"

    head = [
      {"DISCID", cddb_disc_id},
      {"DTITLE", "#{artist} / #{title}"},
      {"DYEAR", year},
      {"DGENRE", genre}
    ]

    # zero-based track titles
    tracks =
      release
      |> dig(["media", 0, "tracks"])
      |> Enum.sort_by(& &1["position"])
      |> Enum.map(fn track -> dig(track, ["recording", "title"]) end)
      |> Enum.with_index()
      |> Enum.map(fn {title, ix} -> {"TTITLE#{ix}", title} end)

    # For maximum compatibility, include the EXT tag lines for each track
    ext =
      Range.new(0, length(tracks) - 1)
      |> Enum.map(fn ix -> {"EXTT#{ix}", ""} end)

    head ++ tracks ++ [{"EXTD", ""}] ++ ext ++ [{"PLAYORDER", ""}]
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

  defp ensure_int_list(items) do
    Enum.map(items, fn
      item when is_integer(item) -> item
      item when is_binary(item) -> String.to_integer(item)
    end)
  end

  defp dig(nil, _), do: nil

  defp dig(data, [key | keys]) when is_map(data) do
    data |> Map.get(key) |> dig(keys)
  end

  defp dig(data, [key | keys]) when is_list(data) do
    data |> Enum.at(key) |> dig(keys)
  end

  defp dig(data, []), do: data
end
