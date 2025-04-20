defmodule CdigwWeb.CddbPlugTest do
  use ExUnit.Case
  use Plug.Test

  alias CdigwWeb.{CddbPlug, MscdPlug}

  defp mock_response(:no_matches) do
    %{
      "release-offset" => 0,
      "release-count" => 0,
      "releases" => []
    }
  end

  defp mock_response(name) do
    "test/fixtures/music_brainz/#{name}.json"
    |> File.read!()
    |> Jason.decode!()
  end

  setup do
    Tesla.Mock.mock(fn
      %{
        method: :get,
        url:
          "https://musicbrainz.org/ws/2/discid/-?fmt=json&inc=artists+recordings+genres&toc=1+13+205050+150+15239+29625+45763+61420+75862+91642+108918+123698+139895+153589+169239+188495"
      } ->
        Tesla.Mock.json(mock_response(:fuzzy_response))

      %{
        method: :get,
        url:
          "https://musicbrainz.org/ws/2/discid/-?fmt=json&inc=artists+recordings+genres&toc=1+19+338925+150+18064+34719+48510+64506+82409+99569+117860+137646+147539+166275+184290+205587+223455+241522+258378+275550+294931+320173"
      } ->
        Tesla.Mock.json(mock_response(:release_with_multiple_discs))

      %{
        method: :get,
        url:
          "https://musicbrainz.org/ws/2/discid/-?fmt=json&inc=artists+recordings+genres&toc=1+19+338952+150+18064+34719+48510+64506+82409+99569+117860+137646+147539+166275+184290+205587+223455+241522+258378+275550+294931+320173"
      } ->
        Tesla.Mock.json(mock_response(:release_with_multiple_discs))

      %{
        method: :get,
        url:
          "https://musicbrainz.org/ws/2/discid/-?fmt=json&inc=artists+recordings+genres&toc=1+15+197550+150+12771+34340+52243+67707+71132+83878+101161+106048+122745+128236+136646+147292+151317+174116"
      } ->
        Tesla.Mock.json(mock_response(:no_matches))
    end)

    :ok
  end

  @tag capture_log: true
  test "CDDB: query and read cycle" do
    proto = 5

    cmd =
      "cddb+query+940aac0d+13+150+15239+29625+45763+61420+75862+91642+108918+123698+139895+153589+169239+188495+2734"

    query_req = conn(:get, "?cmd=#{cmd}&proto=#{proto}")
    query_resp = CddbPlug.call(query_req, %{})

    expected = ~S"""
    200 misc 940aac0d Marina & the Diamonds / The Family Jewels
    """

    assert query_resp.resp_body == expected

    read_req = conn(:get, "?cmd=cddb+read+misc+940aac0d&proto=#{proto}")
    read_resp = CddbPlug.call(read_req, %{})

    # Notice TTITLE4 having an asterisk instead of an apostrophe
    # The actual disc data has the apostrophe encoded as an angled one which
    # is not supported by ISO-8859-1 so gets replaced with a question mark
    expected_read = ~S"""
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

    assert read_resp.resp_body == expected_read
  end

  @tag capture_log: false
  test "CDDB: query with no hits on MusicBrainz" do
    proto = "6"

    cmd =
      "cddb+query+c50a480f+15+150+12771+34340+52243+67707+71132+83878+101161+106048+122745+128236+136646+147292+151317+174116+2634&hello=xrecode3+xrecode.com+XRECODE3+1.163"

    query_req = conn(:get, "?cmd=#{cmd}&proto=#{proto}")
    query_resp = CddbPlug.call(query_req, %{})

    assert query_resp.resp_body == "202 No match"
  end

  @tag capture_log: true
  test "CDDB: query for CD2 in a multi-disc release" do
    proto = 6

    cmd =
      "cddb+query+1F11A513+19+150+18064+34719+48510+64506+82409+99569+117860+137646+147539+166275+184290+205587+223455+241522+258378+275550+294931+320173+4519&hello=ExactAudioCopy+freedb+v0.99"

    query_req = conn(:get, "?cmd=#{cmd}&proto=#{proto}")
    query_resp = CddbPlug.call(query_req, %{})

    expected = ~S"""
    200 misc 1F11A513 Taylor Swift / THE TORTURED POETS DEPARTMENT: THE ANTHOLOGY
    """

    assert query_resp.resp_body == expected

    read_req = conn(:get, "?cmd=cddb+read+misc+1F11A513&proto=#{proto}")
    read_resp = CddbPlug.call(read_req, %{})

    # Notice TTITLE4 having an asterisk instead of an apostrophe
    # The actual disc data has the apostrophe encoded as an angled one which
    # is not supported by ISO-8859-1 so gets replaced with a question mark
    expected_read = ~S"""
    210 misc 1F11A513 CD database entry follows (until terminating `.')
    DISCID=1F11A513
    DTITLE=Taylor Swift / THE TORTURED POETS DEPARTMENT: THE ANTHOLOGY
    DYEAR=2024
    DGENRE=misc
    TTITLE0=The Black Dog
    TTITLE1=imgonnagetyouback
    TTITLE2=The Albatross
    TTITLE3=Chloe or Sam or Sophia or Marcus
    TTITLE4=How Did It End?
    TTITLE5=So High School
    TTITLE6=I Hate It Here
    TTITLE7=thanK you aIMee
    TTITLE8=I Look in People's Windows
    TTITLE9=The Prophecy
    TTITLE10=Cassandra
    TTITLE11=Peter
    TTITLE12=The Bolter
    TTITLE13=Robin
    TTITLE14=The Manuscript
    TTITLE15=Fortnight (acoustic version)
    TTITLE16=Down Bad (acoustic version)
    TTITLE17=But Daddy I Love Him (acoustic version)
    TTITLE18=Guilty as Sin? (acoustic version)
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
    EXTT13=
    EXTT14=
    EXTT15=
    EXTT16=
    EXTT17=
    EXTT18=
    PLAYORDER=
    .
    """

    assert read_resp.resp_body == expected_read
  end

  @tag capture_log: true
  test "MSCD: query CD2 of a two-disc release" do
    cd =
      "13+96+4690+879F+BD7E+FBFA+141E9+184F1+1CC64+219AE+24053+28983+2CFE2+32313+368DF+3AF72+3F14A+4345E+48013+4E2AD+52C08"

    req = conn(:get, "/tunes-cgi2/tunes/disc_info/203/cd=#{cd}")
    resp = MscdPlug.call(req, %{cd: cd})

    expected = ~S"""
    [CD]
    CERTIFICATE=41d602112509916cb8f45f81164805e29bfef1946c88dc57
    Mode=0
    Title=THE TORTURED POETS DEPARTMENT: THE ANTHOLOGY
    Artist=Taylor Swift
    Track1=The Black Dog
    Track2=imgonnagetyouback
    Track3=The Albatross
    Track4=Chloe or Sam or Sophia or Marcus
    Track5=How Did It End?
    Track6=So High School
    Track7=I Hate It Here
    Track8=thanK you aIMee
    Track9=I Look in People's Windows
    Track10=The Prophecy
    Track11=Cassandra
    Track12=Peter
    Track13=The Bolter
    Track14=Robin
    Track15=The Manuscript
    Track16=Fortnight (acoustic version)
    Track17=Down Bad (acoustic version)
    Track18=But Daddy I Love Him (acoustic version)
    Track19=Guilty as Sin? (acoustic version)
    """

    assert resp.resp_body == String.strip(expected)
  end
end
