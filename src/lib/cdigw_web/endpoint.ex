defmodule CdigwWeb.Endpoint do
  require EEx

  @template_dir "lib/cdigw_web/templates"

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

  get "/" do
    recent_lookups = Cdigw.Stats.list_recent_albums()

    conn
    |> assign(:recent_lookups, recent_lookups)
    |> assign(:public_ip, Cdigw.http_config()[:public_ip])
    |> render("index")
  end

  get "/robots.txt" do
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

  defp render(%{status: status} = conn, template) do
    body = apply(__MODULE__, String.to_atom("render_#{template}"), [conn.assigns])

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(status || 200, body)
  end

  EEx.function_from_file(:def, :render_index, Path.join(@template_dir, "index.html.eex"), [
    :assigns
  ])
end
