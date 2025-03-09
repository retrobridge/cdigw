defmodule MusicBrainzTest do
  use ExUnit.Case, async: true
  alias Cddb.Disc

  defp load_mock(name) do
    "test/fixtures/music_brainz/#{name}.json"
    |> File.read!()
    |> Jason.decode!()
  end

  setup do
    Tesla.Mock.mock(fn
      %{
        method: :get,
        url:
          "https://musicbrainz.org/ws/2/discid/-?fmt=json&inc=artists+recordings+genres&toc=1+11+316725+182+3250+30272+61607+93215+118357+141452+175105+211805+251415+282740"
      } ->
        Tesla.Mock.json(load_mock("fuzzy_response_2"))
    end)

    :ok
  end

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
        {"Mowgli's Road", nil},
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

  test "release_to_disc/2 works when genre is present" do
    release =
      "test/fixtures/music_brainz/disc_with_genre.json"
      |> File.read!()
      |> Jason.decode!()
      |> Map.get("releases")
      |> Enum.at(0)

    assert %Disc{genre: "blues"} = MusicBrainz.release_to_disc("860a9b0a", release)
  end

  @tag capture_log: true
  test "find_release/2 when there are multiple disc layouts for the album" do
    length = 4223
    toc = ~w[182 3250 30272 61607 93215 118357 141452 175105 211805 251415 282740]

    {:ok, results} = MusicBrainz.find_release(length, toc)
    assert length(results) == 1
  end
end
