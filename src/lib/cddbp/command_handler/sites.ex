defmodule Cddbp.CommandHandler.Sites do
  @moduledoc """
  Get the servers available for handling CDDB queries.

  For protocol level 1 - 3, only return one server
  For protocol levels 3 - 6, return a list
  """

  use Cddbp.CommandHandler, usage: "SITES"

  def help, do: "Print a list of known server sites."

  def handle(%{proto: proto} = state, []) when proto < 3 do
    site = Enum.find(sites(), fn site -> site.protocol == :cddbp end)

    state
    |> puts("210 OK, site information follows (until terminating `.')")
    |> puts("#{site.hostname} #{site.port} N000.00 W000.00 Primary CDDB Server")
    |> puts(".")
    |> finish_response()
  end

  def handle(%{proto: proto} = state, []) when proto <= 6 do
    puts(state, "210 OK, site information follows (until terminating `.')")

    for %{hostname: host, protocol: protocol, port: port, path: path} <- sites() do
      puts(state, "#{host} #{protocol} #{port} #{path} N000.00 W000.00 Primary server")
    end

    state
    |> puts(".")
    |> finish_response()
  end

  def handle(state, _), do: cmd_syntax_error(state)
end
