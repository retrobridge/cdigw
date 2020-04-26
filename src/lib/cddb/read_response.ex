defmodule Cddb.ReadResponse do
  @moduledoc """
  Render a response for a `cddb read`
  """

  alias Cddb.Disc

  @default_proto Cddb.default_proto()
  @line_separator Cddb.line_separator()
  @eof Cddb.eof_marker()

  @doc """
  Render a `Disc` as a fully acceptable response body
  """
  def render(%Disc{} = disc, proto \\ @default_proto) do
    [header(disc), render_fields(disc, proto), @eof, ""]
    |> List.flatten()
    |> Enum.join(@line_separator)
  end

  @doc """
  Response header for the given disc
  """
  def header(%Disc{id: id, genre: genre}) do
    "210 #{genre} #{id} CD database entry follows (until terminating `.')"
  end

  @doc """
  Render each field as a key-value pair
  """
  def render_fields(%Disc{} = disc, proto \\ @default_proto) do
    disc
    |> field_list(proto)
    |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
  end

  @doc """
  Get the correct CDDB fields as a `Keyword` based on `proto` level

  `DYEAR` and `DGENRE` are only present from version 5.
  """
  def field_list(%Disc{} = disc, proto) when proto <= 4 do
    disc
    |> Disc.to_cddb_keyword()
    |> Keyword.drop([:DYEAR, :DGENRE])
  end

  def field_list(%Disc{} = disc, proto) when proto >= 5 do
    Disc.to_cddb_keyword(disc)
  end
end
