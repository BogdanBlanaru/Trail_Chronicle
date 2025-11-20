defmodule TrailChronicle.Repo.Migrations.EnrichRaces do
  use Ecto.Migration

  def change do
    # 1. Add route data to races (Using JSONB for performance/flexibility)
    alter table(:races) do
      # Stores [[lat, lon], [lat, lon]...]
      add :route_data, :jsonb
      # Snapshot of the map (optional future optimization)
      add :map_image_url, :string
    end

    # 2. Create a separate table for Photos (1-to-Many relationship)
    create table(:race_photos, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :race_id, references(:races, on_delete: :delete_all, type: :binary_id)
      add :image_path, :string
      add :caption, :string
      add :is_featured, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:race_photos, [:race_id])
  end
end
