defmodule KoveRiders.UserBikes.UserBike do
  use Ecto.Schema
  import Ecto.Changeset

  @models [
    {"800X Pro", "800x_pro"},
    {"800X Rally", "800x_rally"},
    {"MX250", "mx250"},
    {"MX450", "mx450"},
    {"450 Rally Street Legal", "450_rally_street"},
    {"450 Rally Off Road", "450_rally_offroad"}
  ]

  def models, do: @models
  def model_slugs, do: Enum.map(@models, fn {_, slug} -> slug end)

  def model_label(slug),
    do: Enum.find_value(@models, slug, fn {label, s} -> if s == slug, do: label end)

  schema "user_bikes" do
    field :nickname, :string
    field :year, :integer
    field :mileage, :integer, default: 0
    field :color, :string
    field :model, :string
    field :is_public, :boolean, default: true

    belongs_to :user, KoveRiders.Accounts.User
    has_many :images, KoveRiders.UserBikes.UserBikeImage
    has_many :mods, KoveRiders.UserBikes.UserBikeMod

    timestamps(type: :utc_datetime)
  end

  def changeset(user_bike, attrs) do
    user_bike
    |> cast(attrs, [:nickname, :year, :mileage, :color, :model, :is_public])
    |> validate_required([:model, :year])
    |> validate_inclusion(:model, model_slugs())
    |> validate_number(:year, greater_than_or_equal_to: 2020, less_than_or_equal_to: 2030)
    |> validate_number(:mileage, greater_than_or_equal_to: 0)
    |> validate_length(:nickname, max: 60)
  end
end
