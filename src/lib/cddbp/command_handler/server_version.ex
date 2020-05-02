defmodule Cddbp.CommandHandler.ServerVersion do
  @moduledoc """
  Send the server software and version
  """

  use Cddbp.CommandHandler, usage: "VER"

  def help, do: "Print cddbp version information."

  def handle(state, []) do
    state
    |> puts_line("200 #{server_software()} v#{server_version()} #{server_config(:hostname)}")
    |> finish_response()
  end
end
