defmodule KoveRiders.UserBikes.UserBikeMod do
  use Ecto.Schema
  import Ecto.Changeset

  @categories ~w(exhaust suspension gearing wheels brakes lighting electrical bodywork
    protection handlebars controls ergonomics luggage other)

  def categories, do: @categories

  schema "user_bike_mods" do
    field :category, :string
    field :title, :string
    field :description, :string
    field :brand, :string
    field :cost_cents, :integer
    field :rating, :integer

    belongs_to :user_bike, KoveRiders.UserBikes.UserBike

    timestamps(type: :utc_datetime)
  end

  def changeset(mod, attrs) do
    mod
    |> cast(attrs, [:category, :title, :description, :brand, :cost_cents, :rating, :user_bike_id])
    |> validate_required([:category, :title, :user_bike_id])
    |> validate_inclusion(:category, @categories)
    |> validate_number(:cost_cents, greater_than_or_equal_to: 0)
    |> validate_number(:rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_length(:title, max: 120)
  end
end
