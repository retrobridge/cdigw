defmodule CdigwWeb.CddbPlug do
  import Plug.Conn
  require Logger
  alias Cdigw.Cache

  def init(options), do: options

  def call(conn, _opts) do
    conn = fetch_query_params(conn)
    {cmd, data} = Cddb.RequestParser.parse_cmd(conn.query_params["cmd"])
    proto = conn.query_params |> Map.get("proto", "1") |> String.to_integer()
    hello = conn.query_params |> Map.get("hello") |> Cddb.HelloParser.parse()

    Logger.info("proto=#{proto} cmd=#{cmd} data=#{inspect(data)} hello=#{inspect(hello)}")

    handle_command(conn, cmd, data, proto)
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
  def handle_command(conn, :query, data, proto) do
    {:ok, releases} = MusicBrainz.find_by_length_and_toc(data.disc_length, data.track_lbas)
    Cache.put(data.disc_id, hd(releases))

    response =
      releases
      |> Enum.map(fn rel -> MusicBrainz.release_to_disc(data.disc_id, rel) end)
      |> Cddb.QueryResponse.render(proto)

    send_encoded_response(conn, response, proto)
  end

  def handle_command(conn, :read, data, proto) do
    Logger.info("fetching cached disc: genre=#{data.genre} disc_id=#{data.disc_id}")

    response_text =
      case Cache.get(data.disc_id) do
        nil ->
          "401 #{data.genre} #{data.disc_id} No such CD entry in database"

        release ->
          data.disc_id
          |> MusicBrainz.release_to_disc(release)
          |> Cddb.ReadResponse.render(proto)
      end

    send_encoded_response(conn, response_text, proto)
  end

  def handle_command(conn, _cmd, _data, proto) do
    send_encoded_response(conn, "500 Unrecognized command.", proto)
  end

  defp send_encoded_response(conn, response, proto) do
    {charset, encoded} = Cddb.encode_response(response, proto)

    Logger.debug("response enc=#{charset} body=<<<EOF\n#{encoded}\nEOF")

    conn
    |> put_resp_content_type("text/plain", charset)
    |> send_resp(200, encoded)
  end
end
