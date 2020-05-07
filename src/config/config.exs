use Mix.Config

config :cdigw, :http_server,
  hostname: "localhost",
  port: 80

config :cdigw, :cddbp_server,
  hostname: "localhost",
  port: 888

import_config "#{Mix.env()}.exs"
