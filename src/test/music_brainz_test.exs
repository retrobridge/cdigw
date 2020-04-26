defmodule MusicBrainzTest do
  use ExUnit.Case, async: true
  alias Cddb.Disc

  doctest MusicBrainz

  test "release_to_disc/2 converts release info to Disc" do
    release =
      "test/fixtures/music_brainz/fuzzy_response.json"
      |> File.read!()
      |> Jason.decode!()
      |> Map.get("releases")
      |> Enum.at(0)

    expectation = %Disc{
      id: "940aac0d",
      artist: "Marina & the Diamonds",
      title: "The Family Jewels",
      year: "2010",
      genre: "misc",
      tracks: [
        {"Are You Satisfied?", nil},
        {"Shampain", nil},
        {"I Am Not a Robot", nil},
        {"Girls", nil},
        {"Mowgli’s Road", nil},
        {"Obsessions", nil},
        {"Hollywood", nil},
        {"The Outsider", nil},
        {"Hermit the Frog", nil},
        {"Oh No!", nil},
        {"Rootless", nil},
        {"Numb", nil},
        {"Guilty", nil}
      ]
    }

    assert MusicBrainz.release_to_disc("940aac0d", release) == expectation
  end
end
