defmodule Cddbp.CommandHandler.Cddb do
  @moduledoc """
  Top-level command handler for the CDDB commands, such as CDDB QUERY
  """

  use Cddbp.CommandHandler

  alias __MODULE__, as: Handlers

  command("hello", Handlers.Hello)
  command("lscat", Handlers.Lscat)
  command("query", Handlers.Query)
  command("read", Handlers.Read)

  def handle_command(state, _, _), do: unrecognized_command(state)

  @cmds @__commands__
        |> Enum.reverse()
        |> Enum.map(fn {prefix, _} -> String.upcase(prefix) end)

  @cmds_str Enum.join(@cmds, " ")

  def usage, do: "CDDB <subcmd> (valid subcmds: #{@cmds_str})"

  def help do
    lines =
      command_handlers()
      |> Enum.map(fn {_prefix, handler} -> handler.usage() end)
      |> Enum.join("\n")

    ~s"""
    Performs a CD database operation.
    Arguments are:
        subcmd:  CDDB subcommand to print help for.
    Subcommands are:

    #{lines}
    """
  end

  def handle(state, [cmd | args]) do
    cmd = String.downcase(cmd)
    handle_command(state, cmd, args)
  end
end
