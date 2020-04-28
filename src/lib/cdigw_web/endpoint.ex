defmodule CdigwWeb.Endpoint do
  use Plug.Router

  plug Plug.Logger
  plug Plug.Static, at: "/", from: :cdigw, only: ~w[favicon.ico images]
  plug :match
  plug :dispatch

  match "/~cddb/cddb.cgi" do
    CdigwWeb.CddbPlug.call(conn, %{})
  end

  # Emulation of the pre-configured tunes.com service
  get "/tunes-cgi2/tunes/disc_info/203/cd=:cd" do
    CdigwWeb.MscdPlug.call(conn, %{cd: cd})
  end

  match "/" do
    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, "priv/static/index.html")
  end

  match "/robots.txt" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, ~S"""
    User-agent: *
    Disallow: /~cddb/
    """)
  end

  match _ do
    send_resp(conn, 404, "not_found")
  end
end
