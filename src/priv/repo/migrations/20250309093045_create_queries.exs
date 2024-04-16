defmodule Cdigw.Repo.Migrations.CreateQueries do
  use Ecto.Migration

  def change do
    create table(:queries) do
      add :ts, :timestamp, index: true
      add :interface, :text
      add :host, :text
      add :query, :text
      add :user_agent, :text
      add :success, :boolean
      add :artist, :string
      add :title, :string
    end
  end
end
