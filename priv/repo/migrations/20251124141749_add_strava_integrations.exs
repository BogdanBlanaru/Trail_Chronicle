defmodule TrailChronicle.Repo.Migrations.AddStravaIntegrations do
  use Ecto.Migration

  def change do
    create table(:strava_integrations, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :athlete_id, references(:athletes, type: :binary_id, on_delete: :delete_all),
        null: false

      add :strava_athlete_id, :bigint, null: false
      add :access_token, :text, null: false
      add :refresh_token, :text, null: false
      add :expires_at, :utc_datetime, null: false

      add :last_sync_at, :utc_datetime
      add :is_active, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:strava_integrations, [:athlete_id])
    create index(:strava_integrations, [:strava_athlete_id])
  end
end
