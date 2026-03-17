defmodule KoveRiders.Repo.Migrations.CreateUserBikes do
  use Ecto.Migration

  def change do
    create table(:user_bikes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :bike_id, references(:bikes, on_delete: :restrict)
      add :nickname, :string
      add :year, :integer
      add :mileage, :integer, default: 0
      add :bike_image_url, :string
      timestamps(type: :utc_datetime)
    end

    create index(:user_bikes, [:user_id])
    create index(:user_bikes, [:bike_id])
  end
end
