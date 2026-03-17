defmodule KoveRiders.Bikes.ChassisSpec do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chassis_specs" do
    field :frame_type, :string
    field :front_suspension, :string
    field :rear_suspension, :string
    field :front_travel_mm, :integer
    field :rear_travel_mm, :integer
    field :front_brake, :string
    field :rear_brake, :string
    field :front_tire, :string
    field :rear_tire, :string
    field :wheel_base_mm, :integer
    field :seat_height_mm, :integer
    field :ground_clearance_mm, :integer
    field :wet_weight_kg, :float
    field :fuel_capacity_l, :float

    belongs_to :bike, KoveRiders.Bikes.Bike

    timestamps(type: :utc_datetime)
  end

  def changeset(chassis, attrs) do
    chassis
    |> cast(attrs, [
      :frame_type,
      :front_suspension,
      :rear_suspension,
      :front_travel_mm,
      :rear_travel_mm,
      :front_brake,
      :rear_brake,
      :front_tire,
      :rear_tire,
      :wheel_base_mm,
      :seat_height_mm,
      :ground_clearance_mm,
      :wet_weight_kg,
      :fuel_capacity_l,
      :bike_id
    ])
    |> validate_required([:bike_id])
  end
end
