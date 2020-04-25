defmodule Cdigw.Application do
  @moduledoc false

  use Application
  require Logger

  @env Mix.env()

  def start(_type, _args) do
    children =
      apps(@env) ++
        [
          {Cache, []}
        ]

    opts = [strategy: :one_for_one, name: Cdigw.Supervisor]

    Supervisor.start_link(children, opts)
  end

  def apps(:test), do: []

  def apps(_) do
    port = System.get_env("HTTP_PORT", "80") |> String.to_integer()
    Logger.info("Starting the HTTP gateway on :#{port}...")

    [
      {Plug.Cowboy, scheme: :http, plug: CdigwWeb.Endpoint, options: [port: port]}
    ]
  end
end
