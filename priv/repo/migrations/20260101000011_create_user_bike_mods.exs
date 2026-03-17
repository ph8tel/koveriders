defmodule KoveRiders.Repo.Migrations.CreateUserBikeMods do
  use Ecto.Migration

  def change do
    create table(:user_bike_mods) do
      add :mod_type, :string, null: false
      add :description, :string, null: false
      add :brand, :string
      add :cost_cents, :integer
      add :installed_at, :date
      add :rating, :integer
      add :position, :integer, default: 0
      add :user_bike_id, references(:user_bikes, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create index(:user_bike_mods, [:user_bike_id])
  end
end
