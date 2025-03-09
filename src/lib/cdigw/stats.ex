defmodule Cdigw.Stats do
  @moduledoc """
  Simple query logging and "stats" about lookup history
  """

  alias Cdigw.Repo
  alias Cdigw.Stats.Query, as: Q
  import Ecto.Query, only: [from: 2]

  def list_recent_albums(limit \\ 10) do
    # Explicitly casting to `text` avoids an issue where SQLite returns data
    # that looks like an integer as an integer, e.g. the album title "1989"
    query =
      from(q in Q,
        distinct: true,
        select: {
          fragment("CAST(? AS text)", q.artist),
          fragment("CAST(? AS text)", q.title)
        },
        order_by: [desc: q.ts],
        where: q.success,
        limit: ^limit
      )

    Repo.all(query)
  end

  def log_successful_query(params) do
    params
    |> Q.new_success()
    |> Repo.insert!()
  end

  def log_unsuccessful_query(params) do
    params
    |> Q.new_failure()
    |> Repo.insert!()
  end
end
