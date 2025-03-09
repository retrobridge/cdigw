defmodule Cdigw.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Cdigw.Cache, []},
      {Plug.Cowboy, scheme: :http, plug: CdigwWeb.Endpoint, options: http_config()},
      {Cddbp.Server, cddbp_config()},
      Cdigw.Repo
    ]

    opts = [strategy: :one_for_one, name: Cdigw.Supervisor]

    Supervisor.start_link(children, opts)
  end

  defp http_config do
    Cdigw.http_config() |> Keyword.take([:port])
  end

  defp cddbp_config do
    Cdigw.cddbp_config() |> Keyword.take([:port])
  end
end
