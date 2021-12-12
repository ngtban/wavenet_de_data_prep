defmodule DataPrepration.MixProject do
  use Mix.Project

  def project do
    [
      app: :data_prepration,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DataPrepration, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:ecto_sql, "~> 3.7.0"},
      {:postgrex, "~> 0.15.10"},
      {:jason, "~> 1.2"},
      {:jaxon, "~> 2.0"},
      {:nimble_parsec, "~> 1.0"}
    ]
  end
end
