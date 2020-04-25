defmodule CddbGateway.ProxyPlug do
  import Plug.Conn
  require Logger

  def init(options), do: options

  def call(conn, _opts) do
    conn = fetch_query_params(conn)
    ["cddb" | cmd] = String.split(conn.query_params["cmd"], " ", trim: true)

    Logger.debug("handling cmd=#{inspect(cmd)}")

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
    [cddb_disc_id, track_count | tracks] = query
    track_count = String.to_integer(track_count)
    {tracks, [seconds]} = Enum.split(tracks, track_count)
    seconds = String.to_integer(seconds)

    {:ok, releases} = MusicBrainz.find_by_length_and_toc(seconds, tracks)
    Cache.put(cddb_disc_id, hd(releases))

    fields = ["DGENRE", "DISCID", "DTITLE"]

    matched_discs =
      releases
      |> Enum.map(fn rel ->
        cddb_data = MusicBrainz.release_to_cddb(cddb_disc_id, rel)

        fields
        |> Enum.map(fn field -> cddb_value(cddb_data, field) end)
        |> Enum.join(" ")
      end)

    response = case conn.query_params["proto"] do
      "1" -> "200 #{hd(matched_discs)}"
      "2" -> "200 #{hd(matched_discs)}"
      "3" -> "200 #{hd(matched_discs)}"
      _ ->
        ~s"""
        210 Found exact matches, list follows (until terminating `.')
        #{Enum.join(matched_discs, "\n")}
        .
        """
    end

    Logger.debug(response)

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, response)
  end

  def handle_command(conn, ["read", genre, disc_id]) do
    Logger.info("fetching cached disc: genre=#{genre} disc_id=#{disc_id}")
    proto = conn.query_params["proto"]

    case Cache.get(disc_id) do
      nil ->
        send_resp(conn, 404, "404 not found")
      release ->
        Logger.debug("release=#{inspect(release)}")

        cddb_data = MusicBrainz.release_to_cddb(disc_id, release)
        cddb_data = cddb_fields_for_proto(cddb_data, proto)
        field_list = cddb_field_list(cddb_data)

        response = ~s"""
        210 #{genre} #{disc_id} CD database entry follow (until terminating `.')
        #{field_list}
        .
        """

        Logger.debug(response)

        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, response)
    end
  end

  defp no_matches_response(disc_id) do
    "202 No match for disc ID #{disc_id}"
  end

  defp cddb_fields_for_proto(fields, "5"), do: fields
  defp cddb_fields_for_proto(fields, _) do
    Enum.reject(fields, fn {k, _} -> Enum.member?(["DYEAR", "DGENRE"], k) end)
  end

  def handle_command(conn, _cmd) do
    Logger.debug("unsupported request req=#{inspect(conn)}")
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(400, "unsupported command")
  end

  defp cddb_field_list(fields) do
    fields
    |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)
    |> Enum.join("\n")
  end

  defp cddb_value(fields, key) do
    Enum.find_value(fields, fn
      {^key, value} -> value
      _ -> nil
    end)
  end
end
