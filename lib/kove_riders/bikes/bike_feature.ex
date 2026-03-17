defmodule KoveRiders.Bikes.BikeFeature do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bike_features" do
    field :title, :string
    field :description, :string
    field :sort_order, :integer, default: 0

    belongs_to :bike, KoveRiders.Bikes.Bike

    timestamps(type: :utc_datetime)
  end

  def changeset(feature, attrs) do
    feature
    |> cast(attrs, [:title, :description, :sort_order, :bike_id])
    |> validate_required([:title, :bike_id])
  end
end
