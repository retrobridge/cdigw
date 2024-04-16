defmodule CdigwWeb.MscdPlug do
  @moduledoc """
  Handle request for MSCD: the Windows 2000 CD Player
  """

  import Plug.Conn
  require Logger

  # The CD player app only seems to process text as ISO-8859-1.
  # Sending UTF-8 garbles non-ASCII chars. Setting the `charset` has no effect,
  # but send it anyway to correctly indicate how we've encoded the text.
  @content_type "text/plain; charset=iso-8859-1"

  def init(options), do: options

  def call(conn, %{cd: cd} = _opts) do
    user = %{
      user_agent: conn |> get_req_header("user-agent") |> Enum.at(0),
      host: conn |> get_req_header("x-forwarded-for") |> Enum.at(0)
    }

    case Mscd.lookup_disc(cd, user) do
      {:ok, disc} ->
        response = 
          disc
          |> Mscd.Response.render()
          |> String.to_charlist
          |> :unicode.characters_to_binary(:utf8, :latin1)

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
