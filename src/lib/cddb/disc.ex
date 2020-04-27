defmodule Cddb.Disc do
  @moduledoc """
  Represents enough disc information to generate CDDB replies
  """

  alias __MODULE__

  defstruct id: nil,
            artist: nil,
            title: nil,
            year: nil,
            genre: Cddb.default_genre(),
            tracks: [],
            extended_data: nil,
            play_order: []

  for field <- ~w[id artist title year genre extended_data]a do
    @doc """
    Set the `#{field}` property value

        iex> Disc.set_#{field}(%Disc{}, "value")
        %Disc{#{field}: "value"}
    """
    def unquote(:"set_#{field}")(%Disc{} = disc, value) do
      Map.put(disc, unquote(field), value)
    end
  end

  def add_track(%Disc{} = disc, title, extended_data \\ nil) do
    Map.update(disc, :tracks, [], fn t -> t ++ [{title, extended_data}] end)
  end

  @doc """
  Render the disc title line "<artist> / <title>"

      iex> Disc.cddb_title(%Disc{artist: "Boyzvoice", title: "Cerveza"})
      "Boyzvoice / Cerveza"
  """
  def cddb_title(%Disc{artist: artist, title: title}) do
    "#{artist} / #{title}"
  end

  @doc """
  Convert a `Disc` to a `Keyword` list of CDDB fields.

  As defined by the CDDB spec, the order of the fields is important,
  hence using a `Keyword` which will guarantee the order is preserved.
  """
  def to_cddb_keyword(%Disc{} = disc) do
    head = [
      DISCID: disc.id,
      DTITLE: cddb_title(disc),
      DYEAR: disc.year,
      DGENRE: disc.genre
    ]

    titles =
      disc.tracks
      |> Enum.with_index(0)
      |> Enum.map(fn {{title, _ext}, index} -> {:"TTITLE#{index}", title} end)

    extended_data = [{:EXTD, nilify(disc.extended_data)}]

    extended_track_data =
      disc.tracks
      |> Enum.with_index(0)
      |> Enum.map(fn {{_title, ext}, index} -> {:"EXTT#{index}", ext} end)

    play_order = [{:PLAYORDER, Enum.join(disc.play_order, ",") |> nilify}]

    head ++ titles ++ extended_data ++ extended_track_data ++ play_order
  end

  defp nilify(nil), do: nil
  defp nilify(""), do: nil
  defp nilify(str), do: str
end
