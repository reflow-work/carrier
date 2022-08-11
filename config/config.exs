# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Configure Mix tasks and generators
config :carrier,
  ecto_repos: [Carrier.Repo]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :carrier, Carrier.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

config :carrier_web,
  ecto_repos: [Carrier.Repo],
  generators: [context_app: :carrier]

# Configures the endpoint
config :carrier_web, CarrierWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: CarrierWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Carrier.PubSub,
  live_view: [signing_salt: "dUjWwWYP"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.0",
  default: [
    args: ~w(
      js/app.js
      vendor/fonts/Lato/lato.css
      --loader:.woff2=file
      --loader:.woff=file
      --loader:.ttf=file
      --bundle
      --target=es2017
      --outdir=../priv/static/assets
      --external:/fonts/*
      --external:/images/*
    ),
    cd: Path.expand("../apps/carrier_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ecto_sql, migration_module: Carrier.Migration

config :carrier, Oban,
  name: Carrier.Oban,
  repo: Carrier.Repo

config :carrier_worker, Oban,
  name: CarrierWorker.Oban,
  repo: Carrier.Repo,
  plugins: [
    {Oban.Plugins.Lifeline, interval: :timer.minutes(1), rescue_after: :timer.minutes(5)},
    Oban.Plugins.Reindexer,
    Oban.Plugins.Stager
  ],
  queues: [default: 10, sample: 10]

config :carrier, Carrier.Vault, json_library: Jason

config :tesla, adapter: {Tesla.Adapter.Finch, name: Carrier.Finch}

config :tailwind,
  version: "3.1.5",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/carrier_web/assets", __DIR__)
  ]

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
config :tzdata, :autoupdate, :disabled

config :carrier, :slack,
  client_id: "3700242262145.3907206908336",
  client_secret: "ea1926306433ead67eea5f55a6855f67",
  bot_token: "xoxb-3700242262145-3896134834753-QZ1WpkILGCgWy7bctc47CoLz"

config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "email"]},
    slack: {Ueberauth.Strategy.SlackV2, []}
  ]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: "136111128651-a4h5k0m79mn64ipar78rspim0kt2d2fj.apps.googleusercontent.com",
  client_secret: "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"

config :ueberauth, Ueberauth.Strategy.SlackV2.OAuth,
  client_id: "3700242262145.3907206908336",
  client_secret: "ea1926306433ead67eea5f55a6855f67"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
