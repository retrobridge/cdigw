use Mix.Config

config :cdigw, :server,
  hostname: "localhost",
  cddbp_port: 888,
  cddb_http_port: 8880

import_config "#{Mix.env()}.exs"
