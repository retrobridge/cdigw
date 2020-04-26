defmodule CdigwWeb.Endpoint do
  use Plug.Router

  plug Plug.Logger
  plug Plug.Static, at: "/public", from: :cdigw
  plug :match
  plug :dispatch

  match "/~cddb/cddb.cgi" do
    CdigwWeb.CddbPlug.call(conn, %{})
  end

  match "/" do
    send_file(conn, 200, "priv/static/index.html")
  end

  match _ do
    send_resp(conn, 404, "not_found")
  end
end
