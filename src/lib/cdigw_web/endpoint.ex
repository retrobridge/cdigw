defmodule CdigwWeb.Endpoint do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  forward("/~cddb/cddb.cgi", to: CdigwWeb.CddbPlug)

  match _ do
    send_resp(conn, 404, "not_found")
  end
end
