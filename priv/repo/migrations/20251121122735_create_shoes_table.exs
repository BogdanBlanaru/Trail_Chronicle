defmodule TrailChronicle.Repo.Migrations.CreateShoesTable do
  use Ecto.Migration

  def change do
    create table(:shoes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :athlete_id, references(:athletes, on_delete: :delete_all, type: :binary_id)

      add :brand, :string, null: false
      add :model, :string, null: false
      add :nickname, :string

      # Tracking
      # Standard lifespan
      add :distance_limit_km, :integer, default: 800
      add :current_distance_km, :decimal, default: 0.0
      add :is_retired, :boolean, default: false, null: false
      add :purchased_at, :date

      timestamps(type: :utc_datetime)
    end

    create index(:shoes, [:athlete_id])

    # Add the relationship to the existing races table
    alter table(:races) do
      add :shoe_id, references(:shoes, on_delete: :nilify_all, type: :binary_id)
    end

    create index(:races, [:shoe_id])
  end
end
