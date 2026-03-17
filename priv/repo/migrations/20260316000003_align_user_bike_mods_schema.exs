defmodule KoveRiders.Repo.Migrations.AlignUserBikeModsSchema do
  use Ecto.Migration

  def up do
    alter table(:user_bike_mods) do
      add :category, :string
      add :title, :string
      remove :mod_type
      remove :installed_at
      remove :position
    end

    # description was NOT NULL before but is optional in the schema
    execute "ALTER TABLE user_bike_mods ALTER COLUMN description DROP NOT NULL"
  end

  def down do
    alter table(:user_bike_mods) do
      remove :category
      remove :title
      add :mod_type, :string, null: false, default: ""
      add :installed_at, :date
      add :position, :integer, default: 0
    end

    execute "ALTER TABLE user_bike_mods ALTER COLUMN description SET NOT NULL"
  end
end
