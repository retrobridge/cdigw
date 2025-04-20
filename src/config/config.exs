import Config

config :cdigw, :http_server,
  hostname: "localhost",
  port: 80

config :cdigw, :cddbp_server,
  hostname: "localhost",
  port: 888,
  max_errors: 3

config :cdigw, Cdigw.Repo, database: "tmp/cdigw.db"
config :cdigw, ecto_repos: [Cdigw.Repo]

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:peer, :request_id]

import_config "#{Mix.env()}.exs"
