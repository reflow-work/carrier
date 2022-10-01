import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
repo_envs = [
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "carrier_test#{System.get_env("MIX_TEST_PARTITION")}",
  port: 48140,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
]

config :carrier, Carrier.Repo, repo_envs
config :carrier, Carrier.TenantRepo, repo_envs

config :carrier, Carrier.Dynamic.PostgresRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "carrier_test#{System.get_env("MIX_TEST_PARTITION")}",
  port: 48140,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :carrier_web, CarrierWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "q7iAfxLO7aidEvcZ4Rrarxj0J6LkDZhQ5weri1yKCLAvjhhT/DdNtNAVZ+7ajNCb",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# In test we don't send emails.
config :carrier, Carrier.Mailer, adapter: Swoosh.Adapters.Test

config :carrier, Oban, testing: :manual
config :carrier_worker, Oban, testing: :manual

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :carrier, Carrier.Vault,
  ciphers: [
    default:
      {Cloak.Ciphers.AES.GCM,
       tag: "AES.GCM.V1", key: Base.decode64!("mO9HUeIWNsMuVoLRcHB9UdPtdZ9PVDZSwUzT8jIIAxI=")}
  ]
