defmodule KoveRiders.Repo do
  use Ecto.Repo,
    otp_app: :kove_riders,
    adapter: Ecto.Adapters.Postgres
end
