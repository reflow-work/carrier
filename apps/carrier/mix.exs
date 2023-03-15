defmodule Carrier.MixProject do
  use Mix.Project

  def project do
    [
      app: :carrier,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Carrier.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix_pubsub, "~> 2.0"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:myxql, "~> 0.6.2"},
      {:jason, "~> 1.2"},
      {:swoosh, "~> 1.3"},
      {:oban, "~> 2.14"},
      {:cloak_ecto, "~> 1.2.0"},
      {:ex_machina, "~> 2.7"},
      {:doumi, "~> 0.2.3"},
      {:tesla, "~> 1.4"},
      {:finch, "~> 0.12"},
      {:table_rex, "~> 3.1"},
      {:timex, "~> 3.7"},
      {:tzdata, "~> 1.1"},
      {:explorer, "~> 0.5.1"},
      {:aws, "~> 0.13.1"},
      {:hackney, "~> 1.18"},
      {:logger_papertrail_backend, "~> 1.1"},
      {:sentry, "~> 8.0"},
      {:ex_cldr, "~> 2.33"},
      {:ex_cldr_numbers, "~> 2.0"},
      {:ex_cldr_dates_times, "~> 2.0"},
      {:hashids, "~> 2.0"},
      {:goth, "~> 1.3.0"},
      {:req, "~> 0.3.6"},
      {:req_bigquery, "~> 0.1.0"},
      {:req_athena, "~> 0.1.2"},
      {:nebulex, "~> 2.4"},
      {:shards, "~> 1.1"},
      {:decorator, "~> 1.4"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop --force-drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "release.setup": []
    ]
  end
end
