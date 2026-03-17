defmodule KoveRiders.Bikes do
  import Ecto.Query, warn: false
  alias KoveRiders.Repo
  alias KoveRiders.Bikes.{Bike, Engine, Image}

  def list_bikes do
    Repo.all(from b in Bike, order_by: [b.name, b.year])
  end

  def list_bikes_with_images do
    Repo.all(
      from b in Bike,
        left_join: i in Image,
        on: i.bike_id == b.id and i.is_hero == true,
        preload: [images: i],
        order_by: [b.name, b.year]
    )
  end

  def get_bike!(id), do: Repo.get!(Bike, id)

  def get_bike_by_slug(slug) do
    Repo.one(
      from b in Bike,
        where: b.slug == ^slug,
        preload: [:engine, :chassis_spec, :dimensions, :bike_features, :images]
    )
  end

  def hero_image_url(%Bike{images: images}) when is_list(images) do
    case Enum.find(images, & &1.is_hero) || List.first(images) do
      nil -> nil
      img -> img.url
    end
  end

  def hero_image_url(_), do: nil

  def format_msrp(%Bike{msrp_cents: nil}), do: "Contact dealer"
  def format_msrp(%Bike{msrp_cents: cents}), do: KoveRiders.Currency.format_cents(cents)

  def list_engines, do: Repo.all(Engine)

  def get_engine!(id), do: Repo.get!(Engine, id)
end
