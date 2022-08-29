import Config

config :tesla, adapter: Tesla.Mock

config :cdigw, :http_server,
  hostname: "localhost",
  port: 9980

config :cdigw, :cddbp_server,
  hostname: "localhost",
  port: 9888

config :mix_test_watch,
  tasks: ["test", "format --check-formatted", "credo --strict"]
