defmodule Cddbp.CommandHandler.Root do
  @moduledoc """
  Root/main entrypoint for command handling.
  """

  use Cddbp.CommandHandler

  def usage, do: ""

  def help, do: ""

  command("cddb", Cddbp.CommandHandler.Cddb)
  command("help", Cddbp.CommandHandler.Help)
  command("motd", Cddbp.CommandHandler.Motd)
  command("proto", Cddbp.CommandHandler.ProtocolLevel)
  command("quit", Cddbp.CommandHandler.Quit)
  command("sites", Cddbp.CommandHandler.Sites)
  command("ver", Cddbp.CommandHandler.ServerVersion)

  def handle(state, [cmd | args]) do
    cmd = String.downcase(cmd)
    handle_command(state, cmd, args)
  end

  def handle(state, _), do: cmd_syntax_error(state)

  @doc """
  Generate a tree of commands with subcommands, recursively.

  Example:
      iex> Cddbp.CommandHandler.Root.command_tree()
      [
        {"ver", Cddbp.CommandHandler.ServerVersion, []},
        {"sites", Cddbp.CommandHandler.Sites, []},
        {"quit", Cddbp.CommandHandler.Quit, []},
        {"proto", Cddbp.CommandHandler.ProtocolLevel, []},
        {"motd", Cddbp.CommandHandler.Motd, []},
        {"help", Cddbp.CommandHandler.Help, []},
        {"cddb", Cddbp.CommandHandler.Cddb,
         [
           {"read", Cddbp.CommandHandler.Cddb.Read, []},
           {"query", Cddbp.CommandHandler.Cddb.Query, []},
           {"lscat", Cddbp.CommandHandler.Cddb.Lscat, []},
           {"hello", Cddbp.CommandHandler.Cddb.Hello, []}
         ]}
      ]
  """
  def command_tree do
    Enum.map(command_handlers(), &command_tree/1)
  end

  defp command_tree({prefix, handler}) do
    case handler.command_handlers() do
      [] -> {prefix, handler, []}
      handlers -> {prefix, handler, Enum.map(handlers, &command_tree/1)}
    end
  end
end
