import Config

config :tesla, adapter: Tesla.Mock

config :cdigw, Cdigw.Repo, database: "tmp/cdigw_test.db"

config :cdigw, :http_server,
  hostname: "localhost",
  port: 9980

config :cdigw, :cddbp_server,
  hostname: "localhost",
  port: 9888,
  max_errors: 10

config :mix_test_watch,
  tasks: ["test", "format --check-formatted", "credo --strict"]
