import Config

config :cdigw, :http_server,
  hostname: "localhost",
  port: 80

config :cdigw, :cddbp_server,
  hostname: "localhost",
  port: 888

config :cdigw, Cdigw.Repo, database: "tmp/cdigw.db"
config :cdigw, ecto_repos: [Cdigw.Repo]

import_config "#{Mix.env()}.exs"
