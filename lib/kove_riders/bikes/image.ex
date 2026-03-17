defmodule KoveRiders.Bikes.Image do
  use Ecto.Schema
  import Ecto.Changeset

  schema "images" do
    field :url, :string
    field :alt, :string
    field :is_hero, :boolean, default: false
    field :sort_order, :integer, default: 0

    belongs_to :bike, KoveRiders.Bikes.Bike

    timestamps(type: :utc_datetime)
  end

  def changeset(image, attrs) do
    image
    |> cast(attrs, [:url, :alt, :is_hero, :sort_order, :bike_id])
    |> validate_required([:url, :bike_id])
  end
end
