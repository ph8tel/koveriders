defmodule KoveRiders.Repo.Migrations.ReplaceUserBikeBikeIdWithModel do
  use Ecto.Migration

  def up do
    alter table(:user_bikes) do
      add :model, :string
      remove :bike_id
    end
  end

  def down do
    alter table(:user_bikes) do
      remove :model
      add :bike_id, references(:bikes, on_delete: :restrict)
    end
  end
end
