defmodule Cddb.QueryResponseTest do
  use ExUnit.Case, async: true

  alias Cddb.{Disc, QueryResponse}

  doctest QueryResponse

  @disc1 %Disc{
    id: "940aac0d",
    artist: "Marina & The Diamonds",
    title: "The Family Jewels",
    genre: "data"
  }

  @disc2 %Disc{
    id: "940aac0d",
    artist: "Marina & The Diamonds",
    title: "The Family Jewels",
    genre: "misc"
  }

  @disc3 %Disc{
    id: "940aac0d",
    artist: "Marina & The Diamonds",
    title: "The Family Jewels",
    genre: "rock"
  }

  @discs [@disc1, @disc2, @disc3]

  test "render/2 proto=1" do
    expected = "200 data 940aac0d Marina & The Diamonds / The Family Jewels"
    assert QueryResponse.render(@discs, 1) == expected
  end

  test "render/2 proto=4" do
    expected = ~S"""
    210 Found exact matches, list follows (until terminating `.')
    data 940aac0d Marina & The Diamonds / The Family Jewels
    misc 940aac0d Marina & The Diamonds / The Family Jewels
    rock 940aac0d Marina & The Diamonds / The Family Jewels
    .
    """

    assert QueryResponse.render(@discs, 4) == expected
  end
end
