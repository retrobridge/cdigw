defmodule Cddb.QueryResponse do
  @moduledoc """
  Formats responses to `cddb query` requests.
  """

  alias Cddb.Disc

  @default_proto Cddb.default_proto()
  @line_separator Cddb.line_separator()
  @eof Cddb.eof_marker()

  @no_match_header "202 No match"
  @multi_header "210 Found exact matches, list follows (until terminating `.')"

  def render(discs, proto \\ @default_proto)

  def render([], _), do: @no_match_header

  @doc """
  Render a disc query response in the correct protocol version.
  """
  def render([disc | _], proto) when proto <= 3 do
    "200 #{disc.genre} #{disc.id} #{Disc.cddb_title(disc)}"
  end

  def render(discs, proto) when proto >= 4 do
    [@multi_header, Enum.map(discs, &render_disc/1), @eof, ""]
    |> List.flatten()
    |> Enum.join(@line_separator)
  end

  defp render_disc(disc) do
    [disc.genre, disc.id, Disc.cddb_title(disc)]
    |> Enum.join(" ")
  end
end
