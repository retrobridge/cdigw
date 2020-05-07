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

  def init(opts) do
    Logger.info("Starting the CDDBP server on :#{opts[:port]}")

    {:ok, _pid} = :ranch.start_listener(:cddbp, :ranch_tcp, opts, Cddbp.Handler, [])
  end
end
