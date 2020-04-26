defmodule CdigwWeb.Endpoint do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)


  match "/~cddb/cddb.cgi" do
    CdigwWeb.CddbPlug.call(conn, %{})
  end

  match _ do
    send_resp(conn, 404, "not_found")
  end
end
