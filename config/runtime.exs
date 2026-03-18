import Config

# Load .env from parent directory if it exists (dev/test convenience).
env_file = Path.expand("../.env", __DIR__)

if File.exists?(env_file) do
  env_file
  |> File.read!()
  |> String.split("\n", trim: true)
  |> Enum.reject(&String.starts_with?(&1, "#"))
  |> Enum.each(fn line ->
    case String.split(line, "=", parts: 2) do
      [key, val] ->
        key = String.trim(key)
        # Only set if not already present — lets CI/Playwright env vars take precedence
        if System.get_env(key) == nil do
          System.put_env(key, String.trim(val))
        end

      _ ->
        :ok
    end
  end)
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "expected DATABASE_URL environment variable to be set"

  config :kove_riders, KoveRiders.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    ssl: true,
    ssl_opts: [verify: :verify_none]

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "expected SECRET_KEY_BASE environment variable to be set"

  host = System.get_env("PHX_HOST") || "koveriders.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :kove_riders, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :kove_riders, KoveRidersWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base,
    server: true
end

# Cloudflare R2 storage
config :kove_riders, KoveRiders.Storage,
  enabled: System.get_env("R2_ACCOUNT_ID") != nil,
  endpoint: "https://#{System.get_env("R2_ACCOUNT_ID") || "dev"}.r2.cloudflarestorage.com",
  bucket: System.get_env("R2_BUCKET") || "koveriders-uploads",
  access_key_id: System.get_env("R2_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("R2_SECRET_ACCESS_KEY"),
  public_url: System.get_env("R2_PUBLIC_URL") || "https://images.koveriders.com",
  region: "auto"

# Google OAuth
if client_id = System.get_env("GOOGLE_OAUTH_CLIENT_ID") do
  config :kove_riders, :google_oauth,
    client_id: client_id,
    client_secret: System.get_env("GOOGLE_OAUTH_CLIENT_SECRET"),
    redirect_uri: System.get_env("GOOGLE_OAUTH_REDIRECT_URI")
end

if base_url = System.get_env("GOOGLE_OAUTH_BASE_URL") do
  config :kove_riders, :google_oauth_base_url, base_url
end
