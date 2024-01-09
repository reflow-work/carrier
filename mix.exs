defmodule Carrier.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "1.8.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      releases: releases()
    ]
  end

  defp deps do
    [
      {:phoenix_live_view, "~> 0.19.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  #
  # Aliases listed here are available only for this project
  # and cannot be accessed from applications inside the apps/ folder.
  defp aliases do
    [
      # run `mix setup` in all child apps
      setup: ["cmd mix setup"],
      "ecto.reset": ["cmd --app carrier mix ecto.reset"],
      "release.setup": ["cmd mix release.setup"],
      sobelow: ["cmd mix sobelow"]
    ]
  end

  defp releases() do
    [
      carrier_app: [
        applications: [
          carrier: :permanent,
          carrier_worker: :permanent,
          carrier_web: :permanent
          # carrier_admin: :permanent,
          # carrier_webhook: :permanent
        ],
        include_executables_for: [:unix],
        steps: [:assemble, :tar],
        config_providers: [{Config.Reader, {:system, "RELEASE_ROOT", "/config_#{Mix.env()}.exs"}}]
      ]
    ]
  end
end
