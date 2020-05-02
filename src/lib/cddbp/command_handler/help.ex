defmodule Cddbp.CommandHandler.Help do
  use Cddbp.CommandHandler

  @ok_header "210 OK, help information follows (until terminating `.')"

  def usage, do: "HELP [command [subcmd]]"

  def help do
    ~S"""
    Prints help information for the given server command.
    With no argument, prints a list of server commands.
    Arguments are:
        command:  command to print help for.
        subcmd:   subcommand of command to print help for.
    """
  end

  def handle(state, []) do
    puts_line(state, @ok_header)
    puts_line(state)

    Cddbp.CommandHandler.Root.command_handlers()
    |> Enum.map(fn {_prefix, handler} -> handler.usage() end)
    |> Enum.each(&puts_line(state, &1))

    state
    |> puts_line(".")
    |> finish_response()
  end

  def handle(state, command_path) do
    tree = Cddbp.CommandHandler.Root.command_tree()
    command_path = Enum.map(command_path, &String.downcase/1)

    {prefix, _} = Enum.split(command_path, length(command_path) - 1)
    prefix = prefix |> Enum.map(&String.upcase/1) |> Enum.join(" ")

    case find_handler_in(tree, command_path) do
      nil ->
        cmd_path = maybe_prefix(prefix, "HELP")

        state
        |> State.increment_errors()
        |> puts_line("500 Unknown #{cmd_path} subcommand")
        |> finish_response()

      handler ->
        usage = maybe_prefix(prefix, handler.usage())
        send_help_response(state, usage, handler.help())
    end
  end

  defp maybe_prefix("", other), do: other
  defp maybe_prefix(prefix, other), do: "#{prefix} #{other}"

  defp send_help_response(state, usage, body) do
    state
    |> puts_line(@ok_header)
    |> puts_line(usage)
    |> puts_line(String.replace(body, ~r/^/m, "    "))
    |> puts_line(".")
    |> finish_response()
  end

  def find_handler_in(tree, [key]) do
    Enum.find_value(tree, fn
      {^key, handler, _} -> handler
      _ -> nil
    end)
  end

  def find_handler_in(tree, [key | subs]) do
    Enum.find_value(tree, fn
      {^key, _handler, subcommands} -> find_handler_in(subcommands, subs)
      _ -> nil
    end)
  end
end
