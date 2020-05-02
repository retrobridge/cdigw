defmodule Cddbp.CommandHandler.Cddb do
  use Cddbp.CommandHandler

  alias __MODULE__, as: Handlers

  command("hello", Handlers.Hello)
  command("lscat", Handlers.Lscat)
  command("query", Handlers.Query)
  command("read", Handlers.Read)

  @cmds Enum.map(@__commands__, fn {prefix, _} -> String.upcase(prefix) end)
  @cmds_str Enum.join(@cmds, " ")

  def usage, do: "CDDB <subcmd> (valid subcmds: #{@cmds_str})"

  def help do
    ~s"""
    CDDB <subcmd> (valid subcmds: #{@cmds_str})
    Performs a CD database operation.
    Arguments are:
        subcmd:  CDDB subcommand to print help for.
    Subcommands are:
    .
    """
  end

  def handle(state, [cmd | args]) do
    cmd = String.downcase(cmd)
    handle_command(state, cmd, args)
  end
end
