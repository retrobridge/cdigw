defmodule CddbGateway.MixProject do
  use Mix.Project

  def project do
    [
      app: :cddb_gateway,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {CddbGateway.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:tesla, "~> 1.3"},
      {:jason, "~> 1.0"}
    ]
  end
end
