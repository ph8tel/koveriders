defmodule KoveRiders.Repo.Migrations.CreateEngines do
  use Ecto.Migration

  def change do
    create table(:engines) do
      add :type, :string
      add :displacement_cc, :integer
      add :bore_mm, :float
      add :stroke_mm, :float
      add :compression_ratio, :string
      add :max_power_hp, :float
      add :max_power_rpm, :integer
      add :max_torque_nm, :float
      add :max_torque_rpm, :integer
      add :cooling, :string
      add :transmission, :string
      add :fuel_system, :string
      timestamps(type: :utc_datetime)
    end
  end
end
