defmodule Ext.Enum do
  @moduledoc """
  Extensions for `Enum` and other modules implementing
  `Enum` behaviour
  """

  @doc """
  Dig into a `Map` and/or `Enum` by key or index

      iex> Ext.Enum.dig(%{users: ["Bob", "Alice"]}, [:users, 1])
      "Alice"

      iex> Ext.Enum.dig(%{users: []}, [:users, 1])
      nil

      iex> Ext.Enum.dig(%{users: []}, [:users, 1], :nobody)
      :nobody
  """
  def dig(enum, keys, default \\ nil)

  def dig(nil, _, default), do: default

  def dig(data, [key | keys], default) when is_map(data) do
    data |> Map.get(key) |> dig(keys, default)
  end

  def dig(data, [key | keys], default) when is_list(data) do
    data |> Enum.at(key) |> dig(keys, default)
  end

  def dig(data, [], _default), do: data
end
