defmodule KoveRiders.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :url, :string, null: false
      add :alt, :string
      add :is_hero, :boolean, default: false
      add :position, :integer, default: 0
      add :bike_id, references(:bikes, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create index(:images, [:bike_id])
  end
end
