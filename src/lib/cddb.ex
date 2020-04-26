defmodule Cddb do
  @moduledoc """
  High level interface and configuration for CDDB
  """

  # Official list of genres in the CDDB protocol, but it seems that just about
  # any string is acceptable and indeed found in CDDB resources.
  @genres ~w[data folk jazz misc rock country blues newage reggae classical soundtrack]

  @doc """
  Default protocol version when not specified by the client.

  Valid levels are 1 - 6
  """
  def default_proto, do: 5

  @doc """
  Line ending to use in CDDB responses.

  The CDDB protocol specifies that `\\n`, `\\r\\n`, and `\\r` are all valid.
  """
  def line_separator, do: "\n"

  @doc """
  Terminator for message replies.
  """
  def eof_marker, do: "."

  @doc """
  Default list of known genres as specified in the CDDB protocol.
  """
  def genres, do: @genres
end
