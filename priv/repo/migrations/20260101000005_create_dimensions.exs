defmodule KoveRiders.Repo.Migrations.CreateDimensions do
  use Ecto.Migration

  def change do
    create table(:dimensions) do
      add :length_mm, :integer
      add :width_mm, :integer
      add :height_mm, :integer
      add :ground_clearance_mm, :integer
      add :wet_weight_kg, :float
      add :dry_weight_kg, :float
      add :fuel_capacity_l, :float
      add :bike_id, references(:bikes, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:dimensions, [:bike_id])
  end
end
