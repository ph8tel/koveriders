defmodule KoveRiders.Repo.Migrations.CreateChassisSpecs do
  use Ecto.Migration

  def change do
    create table(:chassis_specs) do
      add :frame, :string
      add :front_suspension, :string
      add :rear_suspension, :string
      add :front_travel_mm, :integer
      add :rear_travel_mm, :integer
      add :front_brake, :string
      add :rear_brake, :string
      add :front_wheel, :string
      add :rear_wheel, :string
      add :front_tire, :string
      add :rear_tire, :string
      add :seat_height_mm, :integer
      add :wheelbase_mm, :integer
      add :bike_id, references(:bikes, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:chassis_specs, [:bike_id])
  end
end
