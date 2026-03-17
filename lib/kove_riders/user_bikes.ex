defmodule KoveRiders.UserBikes do
  import Ecto.Query, warn: false
  alias KoveRiders.Repo
  alias KoveRiders.UserBikes.{UserBike, UserBikeImage, UserBikeMod}
  alias KoveRiders.Storage

  # ── User Bikes ──────────────────────────────────────────────────────────────

  def list_user_bikes(%KoveRiders.Accounts.Scope{user: user}) do
    Repo.all(
      from ub in UserBike,
        where: ub.user_id == ^user.id,
        preload: [:images, :mods],
        order_by: [desc: ub.inserted_at]
    )
  end

  def get_user_bike!(%KoveRiders.Accounts.Scope{user: user}, id) do
    Repo.one!(
      from ub in UserBike,
        where: ub.id == ^id and ub.user_id == ^user.id,
        preload: [:images, :mods]
    )
  end

  def get_user_bike_public(id) do
    Repo.one(
      from ub in UserBike,
        where: ub.id == ^id and ub.is_public == true,
        preload: [:bike, :images, :mods]
    )
  end

  def list_public_user_bikes(%KoveRiders.Accounts.User{id: user_id}) do
    Repo.all(
      from ub in UserBike,
        where: ub.user_id == ^user_id and ub.is_public == true,
        preload: [:images, :mods],
        order_by: [desc: ub.inserted_at]
    )
  end

  def change_user_bike(%UserBike{} = ub, attrs \\ %{}) do
    UserBike.changeset(ub, attrs)
  end

  def create_user_bike(%KoveRiders.Accounts.Scope{user: user}, attrs) do
    %UserBike{user_id: user.id}
    |> UserBike.changeset(attrs)
    |> Repo.insert()
  end

  def update_user_bike(%KoveRiders.Accounts.Scope{} = scope, id, attrs) do
    ub = get_user_bike!(scope, id)
    ub |> UserBike.changeset(attrs) |> Repo.update()
  end

  def delete_user_bike(%KoveRiders.Accounts.Scope{} = scope, id) do
    ub = get_user_bike!(scope, id)
    Repo.delete(ub)
  end

  # ── Images ──────────────────────────────────────────────────────────────────

  def add_image(%KoveRiders.Accounts.Scope{} = scope, user_bike_id, attrs) do
    _ub = get_user_bike!(scope, user_bike_id)

    %UserBikeImage{user_bike_id: user_bike_id}
    |> UserBikeImage.changeset(attrs)
    |> Repo.insert()
  end

  def delete_image(%KoveRiders.Accounts.Scope{user: user}, image_id) do
    img =
      Repo.one!(
        from i in UserBikeImage,
          join: ub in UserBike,
          on: ub.id == i.user_bike_id and ub.user_id == ^user.id,
          where: i.id == ^image_id
      )

    with {:ok, _} <- Storage.delete(img.r2_key) do
      Repo.delete(img)
    end
  end

  def list_images(user_bike_id) do
    Repo.all(
      from i in UserBikeImage,
        where: i.user_bike_id == ^user_bike_id,
        order_by: i.sort_order
    )
  end

  # ── Mods ────────────────────────────────────────────────────────────────────

  def list_mods(user_bike_id) do
    Repo.all(
      from m in UserBikeMod,
        where: m.user_bike_id == ^user_bike_id,
        order_by: [m.category, m.title]
    )
  end

  def add_mod(%KoveRiders.Accounts.Scope{} = scope, user_bike_id, attrs) do
    _ub = get_user_bike!(scope, user_bike_id)

    %UserBikeMod{user_bike_id: user_bike_id}
    |> UserBikeMod.changeset(attrs)
    |> Repo.insert()
  end

  def update_mod(%KoveRiders.Accounts.Scope{} = scope, mod_id, attrs) do
    mod = get_mod!(scope, mod_id)
    mod |> UserBikeMod.changeset(attrs) |> Repo.update()
  end

  def delete_mod(%KoveRiders.Accounts.Scope{} = scope, mod_id) do
    mod = get_mod!(scope, mod_id)
    Repo.delete(mod)
  end

  def change_mod(%UserBikeMod{} = mod, attrs \\ %{}) do
    UserBikeMod.changeset(mod, attrs)
  end

  defp get_mod!(%KoveRiders.Accounts.Scope{user: user}, mod_id) do
    Repo.one!(
      from m in UserBikeMod,
        join: ub in UserBike,
        on: ub.id == m.user_bike_id and ub.user_id == ^user.id,
        where: m.id == ^mod_id
    )
  end
end
