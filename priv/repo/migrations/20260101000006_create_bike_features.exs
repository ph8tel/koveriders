defmodule KoveRiders.Repo.Migrations.CreateBikeFeatures do
  use Ecto.Migration

  def change do
    create table(:bike_features) do
      add :feature, :string, null: false
      add :position, :integer, default: 0
      add :bike_id, references(:bikes, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create index(:bike_features, [:bike_id])
  end
end
