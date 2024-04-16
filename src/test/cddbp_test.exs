defmodule CddbpTest do
  use ExUnit.Case

  defp mock_response(:fuzzy) do
    "test/fixtures/music_brainz/fuzzy_response.json"
    |> File.read!()
    |> Jason.decode!()
  end

  # In a loop, receive data until nothing is received for 50ms
  # We can assume after 50ms there's no more data coming our way.
  defp recv(socket, acc \\ "") do
    case :gen_tcp.recv(socket, 0, 50) do
      {:ok, chars} ->
        recv(socket, acc <> to_string(chars))

      {:error, :timeout} ->
        acc

      {:error, :closed} ->
        {:closed, acc}
    end
  end

  def send_recv(socket, command) do
    :ok = :gen_tcp.send(socket, command <> "\n")
    recv(socket)
  end

  setup do
    # use mock_global since the tcp server runs in a different process
    Tesla.Mock.mock_global(fn
      %{method: :get, url: "http://musicbrainz.org/ws/2/discid/-" <> _} ->
        Tesla.Mock.json(mock_response(:fuzzy))
    end)

    port = Cdigw.cddbp_config() |> Keyword.fetch!(:port)

    {:ok, socket} = :gen_tcp.connect('127.0.0.1', port, active: false)
    {:ok, %{socket: socket}}
  end

  @tag capture_log: true
  test "full interactive session", %{socket: socket} do
    assert "201 localhost CDDBP server v0.0.1 ready at " <> _ = recv(socket)

    assert send_recv(socket, "bogus") == "500 Unrecognized command.\n"

    assert send_recv(socket, "motd") == ~S"""
           210 MOTD follows (until terminating `.')
           Welcome to this CDDB server.
           .
           """

    assert send_recv(socket, "CDDB lscat") == ~S"""
           210 OK, category list follows (until terminating `.')
           data
           folk
           jazz
           misc
           rock
           country
           blues
           newage
           reggae
           classical
           soundtrack
           .
           """

    assert send_recv(socket, "help") == ~S"""
           210 OK, help information follows (until terminating `.')
           The following commands are supported:

           CDDB <subcmd> (valid subcmds: HELLO LSCAT QUERY READ)
           HELP [command [subcmd]]
           MOTD
           PROTO [level]
           QUIT
           SITES
           VER

           .
           """

    assert send_recv(socket, "help bogus") == "500 Unknown HELP subcommand\n"

    assert send_recv(socket, "HELP ver") == ~S"""
           210 OK, help information follows (until terminating `.')
           VER
               Print cddbp version information.
           .
           """

    assert send_recv(socket, "help cddb") == ~S"""
           210 OK, help information follows (until terminating `.')
           CDDB <subcmd> (valid subcmds: HELLO LSCAT QUERY READ)
               Performs a CD database operation.
               Arguments are:
                   subcmd:  CDDB subcommand to print help for.
               Subcommands are:

               HELLO <username> <hostname> <clientname> <version>
               LSCAT
               QUERY <discid> <ntrks> <off_1> <off_2> <...> <off_n> <nsecs>
               READ <category> <discid>
           .
           """

    assert send_recv(socket, "HELP cddb READ") == ~S"""
           210 OK, help information follows (until terminating `.')
           CDDB READ <category> <discid>
               Retrieve the database entry for the specified CD.
               Arguments are:
                   category:  CD category.
                   discid:    CD disk ID number.
           .
           """

    assert send_recv(socket, "cddb hello user test.localhost exunit 1.2.3") == ~S"""
           200 Hello and welcome user@test.localhost running exunit 1.2.3
           """

    assert send_recv(socket, "proto") == "200 CDDB protocol level: current 1, supported 6\n"

    query =
      "cddb query 940aac0d 13 150 15239 29625 45763 61420 75862 91642 108918 123698 139895 153589 169239 188495 2734"

    assert send_recv(socket, query) == ~S"""
           200 misc 940aac0d Marina & the Diamonds / The Family Jewels
           """

    assert send_recv(socket, "proto 7") == "500 Illegal CDDB protocol level.\n"

    assert send_recv(socket, "proto 5") == "201 OK, CDDB protocol level now: 5\n"

    query =
      "cddb query 940aac0d 13 150 15239 29625 45763 61420 75862 91642 108918 123698 139895 153589 169239 188495 2734"

    assert send_recv(socket, query) == ~S"""
           210 Found exact matches, list follows (until terminating `.')
           misc 940aac0d Marina & the Diamonds / The Family Jewels
           .
           """

    assert send_recv(socket, "CDDB READ misc 940aac0d") == ~S"""
           210 misc 940aac0d CD database entry follows (until terminating `.')
           DISCID=940aac0d
           DTITLE=Marina & the Diamonds / The Family Jewels
           DYEAR=2010
           DGENRE=misc
           TTITLE0=Are You Satisfied?
           TTITLE1=Shampain
           TTITLE2=I Am Not a Robot
           TTITLE3=Girls
           TTITLE4=Mowgli?s Road
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

    assert {:closed, message} = send_recv(socket, "QUIT")

    assert message == ~S"""
           230 localhost Closing connection. Goodbye.
           """
  end
end
