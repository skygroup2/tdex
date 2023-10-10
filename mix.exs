defmodule Tdex.MixProject do
  use Mix.Project

  def project do
    [
      app: :tdex,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [
        :logger,
        :runtime_tools,
        :observer_cli,
        :observer,
        :wx
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      {:gun, git: "git@github.com:skygroup2/gun.git", branch: "master"},
      {:jason, "~> 1.4"},
      {:db_connection, "~> 2.1"},
      {:observer_cli, "~> 1.7"}
    ]
  end
end
