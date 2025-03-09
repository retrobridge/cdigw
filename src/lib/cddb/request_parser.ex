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
    case parse_query(query) do
      {:ok, disc} -> {:query, disc}
      other -> other
    end
  end

  def parse_cmd(["read", genre, disc_id]) do
    {:read, %{genre: genre, disc_id: disc_id}}
  end

  @doc """
  Parse a query, returning a broken-out structured map.
  """
  def parse_query(query) do
    [disc_id, track_count | tracks] = query

    with {track_count, ""} <- Integer.parse(track_count),
         {tracks, [seconds]} <- Enum.split(tracks, track_count),
         tracks = parse_track_list(tracks),
         {seconds, ""} <- Integer.parse(seconds),
         ^track_count <- length(tracks) do
      {:ok,
       %{
         query: Enum.join(query, " "),
         disc_id: disc_id,
         track_count: track_count,
         track_lbas: tracks,
         length_seconds: seconds
       }}
    else
      value -> {:error, value}
    end
  end

  defp parse_track_list(tracks) do
    tracks
    |> Enum.map(&Integer.parse/1)
    |> Enum.map(fn
      :error -> nil
      {num, ""} -> num
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end
end
