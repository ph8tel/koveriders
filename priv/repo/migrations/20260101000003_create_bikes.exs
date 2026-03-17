defmodule KoveRiders.Repo.Migrations.CreateBikes do
  use Ecto.Migration

  def change do
    create table(:bikes) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :year, :integer, null: false
      add :msrp_cents, :integer
      add :tagline, :string
      add :color, :string
      add :engine_id, references(:engines, on_delete: :restrict)
      timestamps(type: :utc_datetime)
    end

    create unique_index(:bikes, [:slug])
    create index(:bikes, [:engine_id])
    create index(:bikes, [:year])
  end
end
