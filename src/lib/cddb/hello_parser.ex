defmodule Cddb.HelloParser do
  @doc """
  Parse the `hello` from a CDDB request

      iex> Cddb.HelloParser.parse("mroach sun-ultra cdrdao 1.2.4")
      {:ok, %{user: "mroach", host: "sun-ultra", app: "cdrdao", version: "1.2.4"}}

      iex> Cddb.HelloParser.parse("joe my.host.com sgi-cdplayer 6.5.30f")
      {:ok, %{user: "joe", host: "my.host.com", app: "sgi-cdplayer", version: "6.5.30f"}}

      iex> Cddb.HelloParser.parse("hey")
      {:error, :invalid}
  """
  def parse(str) when is_binary(str) do
    str |> String.split(" ", trim: true, parts: 4) |> parse
  end

  def parse([user, host, app, ver]) do
    {:ok, %{user: user, host: host, app: app, version: ver}}
  end

  def parse(_), do: {:error, :invalid}
end
