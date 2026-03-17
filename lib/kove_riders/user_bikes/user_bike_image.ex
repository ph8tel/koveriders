defmodule KoveRiders.UserBikes.UserBikeImage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_bike_images" do
    field :r2_key, :string
    field :url, :string
    field :caption, :string
    field :sort_order, :integer, default: 0

    belongs_to :user_bike, KoveRiders.UserBikes.UserBike

    timestamps(type: :utc_datetime)
  end

  def changeset(img, attrs) do
    img
    |> cast(attrs, [:r2_key, :url, :caption, :sort_order, :user_bike_id])
    |> validate_required([:r2_key, :url, :user_bike_id])
  end
end
