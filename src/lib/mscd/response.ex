defmodule Mscd.Response do
  @moduledoc """
  Generate responses for MSCD
  """

  alias Cddb.Disc

  @certificate "41d602112509916cb8f45f81164805e29bfef1946c88dc57"
  @line_separator "\n"

  def render(%Disc{} = disc) do
    body =
      disc
      |> render_fields()
      |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)

    body = ["[CD]" | body]

    Enum.join(body, @line_separator)
  end

  def render_fields(%Disc{title: title, artist: artist, tracks: tracks}) do
    parts = [
      CERTIFICATE: @certificate,
      Mode: 0,
      Title: title,
      Artist: artist
    ]

    track_titles =
      tracks
      |> Enum.with_index(1)
      |> Enum.map(fn {{title, _other}, index} -> {:"Track#{index}", title} end)

    parts ++ track_titles
  end
end
