defmodule MusicBrainzTest do
  use ExUnit.Case, async: true

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

  @tag capture_log: true
  test "find_releases/2 when there are multiple disc layouts for the album" do
    length = 4223
    toc = ~w[182 3250 30272 61607 93215 118357 141452 175105 211805 251415 282740]

    {:ok, results} = MusicBrainz.find_releases(%{length_seconds: length, track_lbas: toc})
    assert length(results) == 1
  end
end
