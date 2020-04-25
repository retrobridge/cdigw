defmodule CddbGateway.MixProject do
  use Mix.Project

  def project do
    [
      app: :cddb_gateway,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      build_path: build_path(),
      deps_path: deps_path()
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
      {:jason, "~> 1.0"},
      {:mix_test_watch, "~> 1.0", only: :dev},
      {:credo, "~> 1.0", only: [:dev, :test]}
    ]
  end

  defp build_path, do: Mix.env() |> build_path()
  defp build_path(_env), do: System.get_env("MIX_BUILD_PATH", "_build")

  defp deps_path, do: Mix.env() |> deps_path()
  defp deps_path(_env), do: System.get_env("MIX_DEPS_PATH", "deps")
end
