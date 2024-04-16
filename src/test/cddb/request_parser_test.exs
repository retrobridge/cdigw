defmodule Cddb.RequestParserTest do
  use ExUnit.Case, async: true

  alias Cddb.RequestParser

  doctest RequestParser

  test "parse_cmd/1 with a query" do
    cmd =
      "cddb query 940aac0d 13 150 15239 29625 45763 61420 75862 91642 108918 123698 139895 153589 169239 188495 2734"

    expected =
      {:query,
       %{
         query:
           "940aac0d 13 150 15239 29625 45763 61420 75862 91642 108918 123698 139895 153589 169239 188495 2734",
         disc_id: "940aac0d",
         track_count: 13,
         length_seconds: 2734,
         track_lbas: [
           150,
           15239,
           29625,
           45763,
           61420,
           75862,
           91642,
           108_918,
           123_698,
           139_895,
           153_589,
           169_239,
           188_495
         ]
       }}

    assert RequestParser.parse_cmd(cmd) == expected
  end

  test "parse_md/1 with read request" do
    cmd = "cddb  read data 940aac0d"

    expected = {:read, %{genre: "data", disc_id: "940aac0d"}}

    assert RequestParser.parse_cmd(cmd) == expected
  end
end
