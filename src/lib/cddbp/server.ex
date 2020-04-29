defmodule Cddbp.Server do
  @moduledoc """
  CDDBP Server

  This is a direct TCP server for CDDB queries and responses.
  Applications like cdrdao use this as the default rather than HTTP.
  """

  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_opts) do
    port = Cdigw.server_config() |> Map.get(:cddbp_port)
    opts = [port: port]

    {:ok, pid} = :ranch.start_listener(:cddbp, :ranch_tcp, opts, Cddbp.Handler, [])

    Logger.info("Starting the CDDBP server on :#{opts[:port]}")

    {:ok, pid}
  end
end
