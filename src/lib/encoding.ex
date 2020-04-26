defmodule Encoding do
  @moduledoc """
  Character encoding.

  CDDB needs replies in ISO-8859-1. That's the one encoding that OTP supports
  out of the box, so we don't need any other dependencies.
  (The `iconv` library uses a NIF which caused problems on Alpine Linux)
  """

  @doc """
  Convert a string to ISO-8859-1 (Latin1).

  Unsupported characters are replaced with the `invalid_char`.

      iex> "Hello Łódź" |> Encoding.to_latin1()
      <<72, 101, 108, 108, 111, 32, 63, 243, 100, 63>>

      iex> "Hello Łódź" |> Encoding.to_latin1() |> String.codepoints
      ["H", "e", "l", "l", "o", " ", "?", <<243>>, "d", "?"]

  """
  def to_latin1(str, invalid_char \\ "?") when is_binary(str) do
    str |> String.to_charlist() |> to_latin1("", invalid_char)
  end

  defp to_latin1(chars, acc, invalid_char) when is_list(chars) do
    case :unicode.characters_to_binary(chars, :utf8, :latin1) do
      {:error, valid, [[_error_char] | tail]} ->
        to_latin1(tail, acc <> valid <> invalid_char, invalid_char)

      result when is_binary(result) ->
        acc <> result
    end
  end
end
