defmodule Cddbp.State do
  @moduledoc """
  Session state for a cddbp user
  """

  defstruct socket: nil,
            transport: nil,
            peername: nil,
            proto: 1,
            hello: nil,
            errors: 0,
            started_at: nil,
            last_command_at: nil

  @type t :: %{
          socket: Port.t(),
          transport: atom(),
          peername: String.t(),
          proto: non_neg_integer(),
          hello: Map.t() | nil,
          errors: non_neg_integer(),
          started_at: DateTime.t(),
          last_command_at: DateTime.t() | nil
        }

  defguard is_protocol_level(val) when is_integer(val) and val >= 1 and val <= 6
  defguard is_hello(list) when is_list(list) and length(list) == 4

  alias __MODULE__

  def new(socket, transport, peername) do
    %State{
      socket: socket,
      transport: transport,
      peername: peername,
      started_at: DateTime.utc_now()
    }
  end

  @doc """
  Set the protocol level for this session.

  Protocol level can be between 1 and 6.
  """
  def set_protocol_level(%State{} = state, level) when is_protocol_level(level) do
    {:ok, Map.put(state, :proto, level)}
  end

  def set_protocol_level(%State{}, level) when is_integer(level) do
    {:error, :invalid_level}
  end

  def set_protocol_level(%State{}, _level) do
    {:error, :invalid_argument}
  end

  def set_hello(%State{hello: nil} = state, args) when is_hello(args) do
    case Cddb.HelloParser.parse(args) do
      {:ok, hello} ->
        {:ok, Map.put(state, :hello, hello)}

      {:error, :invalid} ->
        {:error, :invalid}
    end
  end

  def set_hello(%State{hello: %{} = state}, args) when is_hello(args) do
    {:error, :already_set}
  end

  def set_hello(%State{}, _) do
    {:error, :invalid}
  end

  def increment_errors(%State{} = state) do
    Map.update(state, :errors, 0, &(&1 + 1))
  end
end
