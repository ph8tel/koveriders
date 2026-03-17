defmodule KoveRiders.Repo.Migrations.AlignUserBikeImagesSchema do
  use Ecto.Migration

  def up do
    rename table(:user_bike_images), :storage_key, to: :r2_key
    rename table(:user_bike_images), :position, to: :sort_order

    alter table(:user_bike_images) do
      add :caption, :string
    end
  end

  def down do
    rename table(:user_bike_images), :r2_key, to: :storage_key
    rename table(:user_bike_images), :sort_order, to: :position

    alter table(:user_bike_images) do
      remove :caption
    end
  end
end
