defmodule Cddbp.CommandHandler.Stat do
  @moduledoc false

  use Cddbp.CommandHandler, usage: "STAT"

  def help, do: "Get server capabilities and stats."

  def handle(state, []) do
    server_info = :ranch.info(:cddbp)

    state
    |> puts("210 Ok, status information follows")
    |> puts("current proto: #{state.proto}")
    |> puts("max proto:     #{Cddbp.State.max_protocol_level()}")
    |> puts("gets:          no")
    |> puts("updates:       no")
    |> puts("posting:       no")
    |> puts("quotes:        no")
    |> puts("current users: #{server_info.active_connections}")
    |> puts("max users:     #{server_info.max_connections}")
    |> puts("strip ext:     no")
    |> finish_response()
  end
end
