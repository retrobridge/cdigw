import Config

config :mix_test_watch,
  tasks: ["test", "format --check-formatted", "credo --strict"]
