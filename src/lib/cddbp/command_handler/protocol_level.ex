defmodule Cddbp.CommandHandler.ProtocolLevel do
  @moduledoc """
  Get or set the protocol version.

  Without any arguments, tell the client what the current protocol level is.

  The only accepted argument is an integer between 1 and 6 to set the level.
  """

  use Cddbp.CommandHandler, usage: "PROTO [level]"

  def help do
    ~S"""
    Displays the current and supported protocol level, and sets the current level.
    Arguments are:
      level:  the protocol level to set
    """
  end

  def handle(%{proto: proto} = state, []) do
    state
    |> puts_line("200 CDDB protocol level: current #{proto}, supported 6")
    |> finish_response()
  end

  def handle(state, [new_level]) do
    case Integer.parse(new_level) do
      :error -> cmd_syntax_error(state)
      {level, _} -> set_protocol_level(state, level)
    end
  end

  defp set_protocol_level(state, level) do
    case State.set_protocol_level(state, level) do
      {:ok, new_state} ->
        new_state
        |> send("201 OK, CDDB protocol level now #{new_state.proto}")
        |> finish_response()

      {:error, :invalid_level} ->
        state
        |> send("500 Illegal CDDB protocol level.")
        |> finish_response()

      _ ->
        cmd_syntax_error(state)
    end
  end
end
