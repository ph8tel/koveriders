defmodule KoveRiders.Bikes.Dimension do
  use Ecto.Schema
  import Ecto.Changeset

  schema "dimensions" do
    field :label, :string
    field :value, :string
    field :sort_order, :integer, default: 0

    belongs_to :bike, KoveRiders.Bikes.Bike

    timestamps(type: :utc_datetime)
  end

  def changeset(dim, attrs) do
    dim
    |> cast(attrs, [:label, :value, :sort_order, :bike_id])
    |> validate_required([:label, :value, :bike_id])
  end
end
