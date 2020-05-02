defmodule Cddbp.CommandHandler do
  @moduledoc """
  Behaviour and macro for all command handler modules.

  Creates a tiny DSL for registering subcommands and generating the appropriate
  subcommand handler functions.
  """

  @doc """
  Get the usage string for this command
  """
  @callback usage() :: String.t()

  @doc """
  Get help text for this command
  """
  @callback help() :: String.t()

  @doc """
  Handle the command and return a new state
  """
  @callback handle(Cddbp.State.t(), List.t()) :: Cddbp.State.t()

  defmacro __using__(opts) do
    quote do
      @behaviour Cddbp.CommandHandler
      @before_compile Cddbp.CommandHandler

      Module.register_attribute(__MODULE__, :__commands__, accumulate: true)

      import Cddbp.Helpers
      alias Cddbp.State
      import Cddbp.CommandHandler, only: [command: 2]

      if unquote(opts[:usage]) do
        def usage, do: unquote(opts[:usage])
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def command_handlers, do: @__commands__
    end
  end

  defmacro command(prefix, handler) do
    quote do
      @__commands__ {unquote(prefix), unquote(handler)}

      def handle_command(state, unquote(prefix), args) do
        unquote(handler).handle(state, args)
      end
    end
  end

  def generate_subcommand_help(handlers) do
    handlers
    |> Enum.map(fn h -> h.usage() end)
    |> Enum.join("\n")
  end
end
