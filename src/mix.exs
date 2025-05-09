defmodule Cdigw.MixProject do
  use Mix.Project

  def project do
    [
      app: :cdigw,
      version: version(),
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      build_path: build_path(Mix.env())
    ]
  end

  def application do
    [
      mod: {Cdigw.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.7"},
      {:tesla, "~> 1.14"},
      {:jason, "~> 1.4"},
      {:ecto, "~> 3.12"},
      {:ecto_sqlite3, "~> 0.18"},
      {:ranch, "~> 2.2"},
      {:mix_test_watch, "~> 1.2", only: :dev},
      {:credo, "~> 1.7", only: [:dev, :test]}
    ]
  end

  defp version do
    case File.read("VERSION") do
      {:ok, version} -> String.trim_trailing(version)
      {:error, _} -> "0.0.1-alpha"
    end
  end

  # When you use the MIX_BUILD_PATH environment variable it overrides all
  # other configuration and disables building per environment.
  # This causes problems with some applications that have different compile-time
  # behaviour per environment. For example, mix_text_watch was totally broken.
  defp build_path(env) do
    root = System.get_env("MIX_BUILD_PATH_ROOT", "_build")
    Path.join(root, to_string(env))
  end
end
