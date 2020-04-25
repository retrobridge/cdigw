use Mix.Config

if Mix.env() == :dev do
  config :mix_test_watch,
    tasks: ["test", "format --check-formatted", "credo --strict"]
end
