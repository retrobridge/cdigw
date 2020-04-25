defmodule CddbGateway.Application do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    port = System.get_env("HTTP_PORT", "80") |> String.to_integer()

    children = [
      {Plug.Cowboy, scheme: :http, plug: CddbGatewayWeb.Endpoint, options: [port: port]},
      {Cache, []}
    ]

    opts = [strategy: :one_for_one, name: CddbGateway.Supervisor]

    Logger.info("Starting the HTTP gateway on :#{port}...")

    Supervisor.start_link(children, opts)
  end
end
