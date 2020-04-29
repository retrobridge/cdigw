defmodule Cdigw do
  @moduledoc """
  CD Information Gateway top level general interface
  """

  @version Mix.Project.config()[:version]

  def server_config do
    Map.new(Application.get_env(:cdigw, :server))
  end

  def version, do: @version
end
