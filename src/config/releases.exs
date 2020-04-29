use Mix.Config

config :cdigw, hostname: System.get_env("HOSTNAME", "cddb.retrobridge.org")
