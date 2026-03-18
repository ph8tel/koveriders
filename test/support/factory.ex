defmodule KoveRiders.Factory do
  use ExMachina.Ecto, repo: KoveRiders.Repo

  alias KoveRiders.Accounts.User
  alias KoveRiders.UserBikes.UserBike
  alias KoveRiders.UserBikes.UserBikeImage
  alias KoveRiders.UserBikes.UserBikeMod

  def user_factory do
    %User{
      email: sequence(:email, &"rider#{&1}@example.com"),
      handle: sequence(:handle, &"rider#{&1}"),
      handle_change_count: 0,
      confirmed_at: ~U[2024-01-01 00:00:00Z]
    }
  end

  def user_bike_factory do
    %UserBike{
      model: "800x_pro",
      year: 2024,
      mileage: 0,
      is_public: true,
      user: build(:user)
    }
  end

  def user_bike_image_factory do
    %UserBikeImage{
      r2_key: sequence(:r2_key, &"bike-photos/test-#{&1}.jpg"),
      url: sequence(:url, &"/uploads/bike-photos/test-#{&1}.jpg"),
      sort_order: 0,
      user_bike: build(:user_bike)
    }
  end

  def user_bike_mod_factory do
    %UserBikeMod{
      category: "exhaust",
      title: sequence(:mod_title, &"Mod #{&1}"),
      user_bike: build(:user_bike)
    }
  end
end
