defmodule Cdigw.Cache do
  @moduledoc """
  Quick and dirty in-memory key-value store.
  """
  use Agent
  require Logger

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get(key, default \\ nil) do
    Logger.debug("cache get key=#{key}")
    Agent.get(__MODULE__, fn state -> Map.get(state, key, default) end)
  end

  def put(key, value) do
    Logger.debug("cache put key=#{key}")
    Agent.update(__MODULE__, fn state -> Map.put(state, key, value) end)
  end
end
