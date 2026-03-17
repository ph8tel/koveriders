defmodule KoveRiders.Bikes.Bike do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bikes" do
    field :name, :string
    field :slug, :string
    field :year, :integer
    field :msrp_cents, :integer
    field :tagline, :string
    field :color, :string

    belongs_to :engine, KoveRiders.Bikes.Engine
    has_one :chassis_spec, KoveRiders.Bikes.ChassisSpec
    has_many :dimensions, KoveRiders.Bikes.Dimension
    has_many :bike_features, KoveRiders.Bikes.BikeFeature
    has_many :images, KoveRiders.Bikes.Image

    timestamps(type: :utc_datetime)
  end

  def changeset(bike, attrs) do
    bike
    |> cast(attrs, [:name, :slug, :year, :msrp_cents, :tagline, :color, :engine_id])
    |> validate_required([:name, :slug, :year, :engine_id])
    |> unique_constraint(:slug)
  end
end
