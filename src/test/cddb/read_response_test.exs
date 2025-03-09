defmodule Cddb.ReadResponseTest do
  use ExUnit.Case, async: true

  alias Cddb.{Disc, ReadResponse}

  doctest ReadResponse

  @disc %Disc{
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

  for proto <- 1..4 do
    test "field_list/2 with proto=#{proto}" do
      keyword = ReadResponse.field_list(@disc, unquote(proto))

      refute Keyword.has_key?(keyword, :DYEAR)
      refute Keyword.has_key?(keyword, :DGENRE)
    end
  end

  for proto <- 5..6 do
    test "field_list/2 proto=#{proto}" do
      keyword = ReadResponse.field_list(@disc, unquote(proto))

      assert Keyword.has_key?(keyword, :DYEAR)
      assert Keyword.has_key?(keyword, :DGENRE)
    end
  end

  test "render/2 with proto=5" do
    expected = ~S"""
    210 misc 940aac0d CD database entry follows (until terminating `.')
    DISCID=940aac0d
    DTITLE=Marina & the Diamonds / The Family Jewels
    DYEAR=2010
    DGENRE=misc
    TTITLE0=Are You Satisfied?
    TTITLE1=Shampain
    TTITLE2=I Am Not a Robot
    TTITLE3=Girls
    TTITLE4=Mowgli's Road
    TTITLE5=Obsessions
    TTITLE6=Hollywood
    TTITLE7=The Outsider
    TTITLE8=Hermit the Frog
    TTITLE9=Oh No!
    TTITLE10=Rootless
    TTITLE11=Numb
    TTITLE12=Guilty
    EXTD=
    EXTT0=
    EXTT1=
    EXTT2=
    EXTT3=
    EXTT4=
    EXTT5=
    EXTT6=
    EXTT7=
    EXTT8=
    EXTT9=
    EXTT10=
    EXTT11=
    EXTT12=
    PLAYORDER=
    .
    """

    assert ReadResponse.render(@disc, 5) == expected
  end
end
