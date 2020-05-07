defmodule Cdigw do
  @moduledoc """
  CD Information Gateway top level general interface
  """

  @version Mix.Project.config()[:version]

  @doc """
  Get list of sites serving CDDB information

  Only returns this server and its HTTP and CDDBP configuration.
  """
  def sites do
    [
      %{
        hostname: http_config()[:hostname],
        protocol: :http,
        port: http_config()[:cddb_http_port],
        path: "~/cddb/cddb.cgi"
      },
      %{
        hostname: cddbp_config()[:hostname],
        protocol: :cddbp,
        port: cddbp_config()[:port],
        path: "-"
      }
    ]
  end

  def http_config do
    Application.get_env(:cdigw, :http_server)
  end

  def cddbp_config do
    Application.get_env(:cdigw, :cddbp_server)
  end

  def version, do: @version
end
