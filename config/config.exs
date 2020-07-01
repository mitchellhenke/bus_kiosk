# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :bus_kiosk,
  ecto_repos: [BusKiosk.Repo],
  real_time_module: BusKiosk.TestRealTime,
  # mcts_api_key: "",
  real_time_polling_enabled: System.get_env("REAL_TIME_POLLING_ENABLED") != "false",
  gtfs_import_connections: String.to_integer(System.get_env("GTFS_IMPORT_CONNECTIONS") || "10")

# Configures the endpoint
config :bus_kiosk, BusKioskWeb.Endpoint,
  url: [host: "localhost"],
  http: [compress: true],
  secret_key_base: "5MVdI104va7hVNk23RNuosKx+wMtp2NFoJZBDqNcqJl8GqiWfuwQPyryVIK6hoNd",
  render_errors: [view: BusKioskWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: BusKiosk.PubSub,
  live_view: [
    signing_salt: "z38lsMlljav9khCujms4qszk0wxuXjGE"
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Use Jason for JSON parsing in Phoenix
config :phoenix,
  json_library: Jason,
  static_compressors: [Phoenix.Digester.Gzip, Phoenix.Digester.Brotli]

config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: :prod,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!()

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
