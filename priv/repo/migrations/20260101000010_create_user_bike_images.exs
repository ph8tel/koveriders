defmodule KoveRiders.Repo.Migrations.CreateUserBikeImages do
  use Ecto.Migration

  def change do
    create table(:user_bike_images) do
      add :url, :string, null: false
      add :storage_key, :string
      add :position, :integer, default: 0
      add :user_bike_id, references(:user_bikes, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create index(:user_bike_images, [:user_bike_id])
  end
end
