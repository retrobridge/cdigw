defmodule CddbGateway.ProxyPlug do
  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    conn = fetch_query_params(conn)
    cmd = conn.query_params["cmd"]

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
  def handle_command(conn, "cddb query " <> query) do
    [_disc_id, track_count | tracks] = String.split(query)
    track_count = String.to_integer(track_count)
    {tracks, [seconds]} = Enum.split(tracks, track_count)

    toc = [1, track_count, guessed_leadout_lba] ++ tracks

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "query was #{query}")
  end

  def handle_command(conn, _cmd) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(400, "unsupported command")
  end
end
