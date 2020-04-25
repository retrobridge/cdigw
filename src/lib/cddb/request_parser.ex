defmodule Cddb.RequestParser do
  @moduledoc """
  Parse CDDB requests into structures easier to deal with
  """

  @doc """
  Parse a given command into a two-element tuple with data structure

      iex> Cddb.RequestParser.parse_cmd("cddb  read data 940aac0d")
      {:read, %{genre: "data", disc_id: "940aac0d"}}
  """
  def parse_cmd(cmd) when is_binary(cmd) do
    cmd |> String.split(" ", trim: true) |> parse_cmd
  end

  def parse_cmd(["cddb" | cmd]), do: parse_cmd(cmd)

  def parse_cmd(["query" | query]) do
    [disc_id, track_count | tracks] = query

    track_count = String.to_integer(track_count)
    {tracks, [seconds]} = Enum.split(tracks, track_count)
    seconds = String.to_integer(seconds)

    {:query,
     %{
       disc_id: disc_id,
       track_count: track_count,
       disc_length: seconds,
       track_lbas: Enum.map(tracks, &String.to_integer/1)
     }}
  end

  def parse_cmd(["read", genre, disc_id]) do
    {:read, %{genre: genre, disc_id: disc_id}}
  end
end
