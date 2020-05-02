defmodule Cdigw do
  @moduledoc """
  CD Information Gateway top level general interface
  """

  @version Mix.Project.config()[:version]

  @doc """
  Get list of sites serving CDDB information

  Only returns this server and its HTTP and CDDBP configuration.
  Config comes from `Cdigw.server_config/1`
  """
  def sites() do
    server_config = server_config()

    [
      %{
        hostname: server_config[:hostname],
        protocol: :http,
        port: server_config[:cddb_http_port],
        path: "~/cddb/cddb.cgi"
      },
      %{
        hostname: server_config[:hostname],
        protocol: :cddbp,
        port: server_config[:cddbp_port],
        path: "-"
      }
    ]
  end

  def server_config do
    Map.new(Application.get_env(:cdigw, :server))
  end

  def version, do: @version
end
