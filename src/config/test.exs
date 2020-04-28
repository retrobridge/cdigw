use Mix.Config

config :tesla, adapter: Tesla.Mock

config :mix_test_watch,
  tasks: ["test", "format --check-formatted", "credo --strict"]
