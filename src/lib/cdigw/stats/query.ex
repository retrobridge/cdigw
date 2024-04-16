defmodule Cdigw.Stats.Query do
  @moduledoc """
  Each time a query is made, we log the query and if the lookup was successful
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  schema "queries" do
    field(:ts, :utc_datetime)
    field(:host, :string)
    field(:query, :string)
    field(:interface, :string)
    field(:user_agent, :string)
    field(:success, :boolean)
    field(:artist, :string)
    field(:title, :string)
  end

  def new_success(params) do
    %Query{}
    |> changeset(params)
    |> put_change(:success, true)
  end

  def new_failure(params) do
    %Query{}
    |> changeset(params)
    |> put_change(:success, false)
  end

  def changeset(schema, params) do
    schema
    |> cast(params, [:host, :query, :interface, :user_agent, :success, :artist, :title])
    |> put_change(:ts, DateTime.utc_now() |> DateTime.truncate(:second))
  end
end
