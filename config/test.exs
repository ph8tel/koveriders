import Config

config :kove_riders, KoveRiders.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "kove_riders_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :kove_riders, KoveRidersWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_that_is_at_least_64_bytes_long_for_phoenix_tests",
  server: false

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime
config :swoosh, :api_client, false
config :phoenix_live_view, enable_expensive_runtime_checks: true
