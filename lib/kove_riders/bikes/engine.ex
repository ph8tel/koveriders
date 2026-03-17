defmodule KoveRiders.Bikes.Engine do
  use Ecto.Schema
  import Ecto.Changeset

  schema "engines" do
    field :type, :string
    field :displacement_cc, :integer
    field :bore_mm, :float
    field :stroke_mm, :float
    field :compression_ratio, :string
    field :max_power_hp, :float
    field :max_power_rpm, :integer
    field :max_torque_nm, :float
    field :max_torque_rpm, :integer
    field :cooling, :string
    field :transmission, :string
    field :fuel_system, :string

    has_many :bikes, KoveRiders.Bikes.Bike

    timestamps(type: :utc_datetime)
  end

  def changeset(engine, attrs) do
    engine
    |> cast(attrs, [
      :type,
      :displacement_cc,
      :bore_mm,
      :stroke_mm,
      :compression_ratio,
      :max_power_hp,
      :max_power_rpm,
      :max_torque_nm,
      :max_torque_rpm,
      :cooling,
      :transmission,
      :fuel_system
    ])
    |> validate_required([:type, :displacement_cc])
  end
end
