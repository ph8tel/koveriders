defmodule KoveRiders.Repo.Migrations.AddColorAndIsPublicToUserBikes do
  use Ecto.Migration

  def change do
    alter table(:user_bikes) do
      add :color, :string
      add :is_public, :boolean, default: true, null: false
    end
  end
end
