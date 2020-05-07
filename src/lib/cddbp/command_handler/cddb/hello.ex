defmodule Cddbp.CommandHandler.Cddb.Hello do
  @moduledoc false

  use Cddbp.CommandHandler

  def usage, do: "HELLO <username> <hostname> <clientname> <version>"

  def help do
    ~s"""
    Register necessary information with CD database server.
    Arguments are:
        username:    login name of user.
        hostname:    host name of client system.
        clientname:  name of client software.
        version:     version number of client software.
    """
  end

  def handle(state, args) do
    case State.set_hello(state, args) do
      {:ok, new_state} ->
        new_state
        |> puts("200 Hello and welcome #{format_hello(new_state.hello)}")
        |> finish_response()

      {:error, :already_set} ->
        state
        |> puts("402 Already shook hands.")
        |> finish_response()

      _ ->
        cmd_syntax_error(state)
    end
  end

  defp format_hello(hello) do
    "#{hello.user}@#{hello.host} running #{hello.app} #{hello.version}"
  end
end
