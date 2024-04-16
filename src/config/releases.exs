import Config

config :cdigw, :http_server,
  hostname: System.get_env("HOSTNAME", "cddb.retrobridge.org"),
  port: System.get_env("HTTP_PORT", "80") |> String.to_integer()

config :cdigw, :cddbp_server,
  hostname: System.get_env("HOSTNAME", "cddb.retrobridge.org"),
  port: System.get_env("CDDBP_PORT", "888") |> String.to_integer()

config :cdigw, Cdigw.Repo, database: System.get_env("DATABASE_PATH")
