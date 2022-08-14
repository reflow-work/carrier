defmodule CarrierWorker.MixProject do
  use Mix.Project

  def project do
    [
      app: :carrier_worker,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {CarrierWorker.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:carrier, in_umbrella: true}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "release.setup": []
    ]
  end
end
