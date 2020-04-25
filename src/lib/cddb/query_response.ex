defmodule Cddb.QueryResponse do
  @header_no_match "202 No match"

  @default_proto 5
  @line_separator "\n"
  @eof "."

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
