defmodule CdigwWeb.MscdPlug do
  @moduledoc """
  Handle request for MSCD: the Windows 2000 CD Player
  """

  import Plug.Conn
  require Logger

  @content_type "text/plain; charset=utf-8"

  def init(options), do: options

  def call(conn, %{cd: cd} = _opts) do
    user = %{
      user_agent: conn |> get_req_header("user-agent") |> Enum.at(0),
      host: conn |> get_req_header("x-forwarded-for") |> Enum.at(0)
    }

    case Mscd.lookup_disc(cd, user) do
      {:ok, disc} ->
        response = Mscd.Response.render(disc)

        conn
        |> put_resp_header("content-type", @content_type)
        |> send_resp(200, response)

      {:error, :not_found} ->
        conn
        |> put_resp_header("content-type", @content_type)
        |> send_resp(404, "No matching disc found")
    end
  end
end
