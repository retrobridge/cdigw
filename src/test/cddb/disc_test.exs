defmodule Cddb.DiscTest do
  use ExUnit.Case, async: true
  alias Cddb.Disc

  doctest Disc

  test "to_cddb_keyword/1 renders in the correct order" do
    disc = %Disc{
      id: "940aac0d",
      artist: "Marina & The Diamonds",
      title: "The Family Jewels",
      year: 2010,
      genre: "Pop",
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

    expected = [
      DISCID: "940aac0d",
      DTITLE: "Marina & The Diamonds / The Family Jewels",
      DYEAR: 2010,
      DGENRE: "Pop",
      TTITLE0: "Are You Satisfied?",
      TTITLE1: "Shampain",
      TTITLE2: "I Am Not a Robot",
      TTITLE3: "Girls",
      TTITLE4: "Mowgli's Road",
      TTITLE5: "Obsessions",
      TTITLE6: "Hollywood",
      TTITLE7: "The Outsider",
      TTITLE8: "Hermit the Frog",
      TTITLE9: "Oh No!",
      TTITLE10: "Rootless",
      TTITLE11: "Numb",
      TTITLE12: "Guilty",
      EXTD: nil,
      EXTT0: nil,
      EXTT1: nil,
      EXTT2: nil,
      EXTT3: nil,
      EXTT4: nil,
      EXTT5: nil,
      EXTT6: nil,
      EXTT7: nil,
      EXTT8: nil,
      EXTT9: nil,
      EXTT10: nil,
      EXTT11: nil,
      EXTT12: nil,
      PLAYORDER: nil
    ]

    assert Disc.to_cddb_keyword(disc) == expected
  end
end
