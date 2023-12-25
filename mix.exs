defmodule Tdex.MixProject do
  use Mix.Project

  def project do
    [
      app: :tdex,
      version: "1.0.0",
      elixir: "~> 1.15",
      elixirc_paths: [:lib],
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make] ++ Mix.compilers(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Tdex, []},
      extra_applications: [
        :logger,
        :jason,
        :gun,
        :skn_lib,
        :runtime_tools,
        :observer_cli,
        # :observer,
        # :wx
      ],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:skn_lib, git: "git@github.com:skygroup2/skn_lib.git", branch: "main"},
      {:gun, git: "https://github.com/skygroup2/gun.git", branch: "master"},
      {:elixir_make, "~> 0.7.7", runtime: false},
      {:jason, "~> 1.4"},
      {:db_connection, "~> 2.1"},
      {:observer_cli, "~> 1.7"}
    ]
  end
end
