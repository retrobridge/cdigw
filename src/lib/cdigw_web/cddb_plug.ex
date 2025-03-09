defmodule CdigwWeb.CddbPlug do
  @moduledoc """
  Handles `cddb query` and `cddb read` commands of /~cddb/cddb.cgi
  """

  import Plug.Conn
  require Logger

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
  defp handle_command(conn, :query, data, proto) do
    context = %{
      host: conn |> get_req_header("x-forwarded-for") |> Enum.at(0),
      agent: conn |> get_req_header("user-agent") |> Enum.at(0)
    }

    {:ok, discs} = Cddb.lookup_disc(data, context)
    response_text = Cddb.QueryResponse.render(discs, proto)

    send_encoded_response(conn, response_text, proto)
  end

  defp handle_command(conn, :read, data, proto) do
    Logger.info("fetching cached disc: genre=#{data.genre} disc_id=#{data.disc_id}")

    response_text =
      case Cddb.get_cached_disc(data.genre, data.disc_id) do
        {:error, :not_found} ->
          "401 #{data.genre} #{data.disc_id} No such CD entry in database"

        {:ok, disc} ->
          Cddb.ReadResponse.render(disc, proto)
      end

    send_encoded_response(conn, response_text, proto)
  end

  defp handle_command(conn, _cmd, _data, proto) do
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
