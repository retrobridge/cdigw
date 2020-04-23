defmodule CddbGateway.ProxyPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn = fetch_query_params(conn)
    ["cddb" | cmd] = String.split(conn.query_params["cmd"], " ", trim: true)

    conn |> handle_command(cmd)
  end

  # Anatomy of the querystring
  # Example
  # ?cmd=cddb query 940aac0d 13 150 15239 29625 45763 61420 75862 91642 108918 123698 139895 153589 169239 188495 2734
  #
  # "cddb query"    the command itself
  # 940aac0d        the calculated FreeDB CD ID. not useful for us
  # 13              track count
  # 150 ... 188495  sector start lba for each track
  # 2734            CD play time in seconds
  def handle_command(conn, ["query" | query]) do
    [_disc_id, track_count | tracks] = query
    track_count = String.to_integer(track_count)
    {tracks, [seconds]} = Enum.split(tracks, track_count)
    seconds = String.to_integer(seconds)

    {:ok, releases} = MusicBrainz.find_by_length_and_toc(seconds, tracks)

    fields = ["DGENRE", "DISCID", "DTITLE"]

    matched_discs =
      releases
      |> Enum.map(fn rel ->
        cddb_data = MusicBrainz.release_to_cddb(rel)

        fields
        |> Enum.map(fn field -> cddb_value(cddb_data, field) end)
        |> Enum.join(" ")
      end)

    for rel <- releases do
      disc_id = String.slice(rel["id"], 0..7)
      Cache.put(disc_id, rel)
    end

    response = ~s"""
    210 Found exact matches, list follows (until terminating `.')
    #{Enum.join(matched_discs, "\n")}
    .
    """

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, response)
  end

  def handle_command(conn, ["read", genre, disc_id]) do
    rel = Cache.get(disc_id)
    cddb_data = MusicBrainz.release_to_cddb(rel)

    field_list =
      cddb_data
      |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)
      |> Enum.join("\n")

    response = ~s"""
    210 #{genre} #{disc_id} CD database entry follow (until terminating `.')
    #{field_list}
    .
    """

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, response)
  end

  def handle_command(conn, _cmd) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(400, "unsupported command")
  end

  defp cddb_value(fields, key) do
    Enum.find_value(fields, fn
      {^key, value} -> value
      _ -> nil
    end)
  end
end
