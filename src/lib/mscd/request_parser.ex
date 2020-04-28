defmodule Mscd.RequestParser do
  @moduledoc """
  Parse MSCD requests.

  MSCD only has one known request type: get disc info given the TOC
  """

  @doc """
      iex> Mscd.RequestParser.parse_query("D 96 3B87 73B9 B2C3 EFEC 12856 165FA 1A976 1E332 22277 257F5 29517 2E04F 32110")
      {:ok, %{
        track_count: 13,
        track_lbas: [150, 15239, 29625, 45763, 61420, 75862, 91642, 108918, 123698, 139895, 153589, 169239, 188495],
        lead_out_lba: 205072
      }}

      iex> Mscd.RequestParser.parse_query("2 96 3B87")
      {:error, :too_few_lbas}

      iex> Mscd.RequestParser.parse_query("2 96 3B87 73B9 B2C3")
      {:error, :too_many_lbas}
  """
  def parse_query(query) when is_binary(query) do
    query
    |> String.split(~r/[\s+]/, trim: true)
    |> Enum.map(&String.to_integer(&1, 16))
    |> parse_query()
  end

  def parse_query([track_count | lbas]) when track_count >= length(lbas) do
    {:error, :too_few_lbas}
  end

  def parse_query([track_count | lbas]) when track_count < length(lbas) - 1 do
    {:error, :too_many_lbas}
  end

  def parse_query([track_count | lbas]) do
    {track_lbas, [lead_out_lba]} = Enum.split(lbas, track_count)

    {:ok,
     %{
       track_count: track_count,
       track_lbas: track_lbas,
       lead_out_lba: lead_out_lba
     }}
  end
end
