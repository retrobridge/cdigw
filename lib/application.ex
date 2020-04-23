defmodule CddbGateway.Application do
  use Application
  require Logger

  def start(_type, _args) do
    port = System.get_env("PORT", "8333") |> String.to_integer
    children = [
      {Plug.Cowboy, scheme: :http, plug: CddbGateway.Endpoint, options: [port: port]},
      {Cache, []}
    ]
    opts = [strategy: :one_for_one, name: CddbGateway.Supervisor]

    Logger.info("Starting the proxy on :#{port}...")

    Supervisor.start_link(children, opts)
  end
end
