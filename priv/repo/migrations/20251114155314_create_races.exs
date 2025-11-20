defmodule TrailChronicle.Repo.Migrations.CreateRaces do
  use Ecto.Migration

  def change do
    create table(:races, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :athlete_id, references(:athletes, type: :binary_id, on_delete: :delete_all),
        null: false

      # Basic info
      add :name, :string, null: false
      add :race_date, :date, null: false
      add :race_type, :string
      add :status, :string, default: "upcoming", null: false

      # Location (simple lat/long instead of PostGIS)
      add :country, :string
      add :city, :string
      add :latitude, :decimal, precision: 10, scale: 8
      add :longitude, :decimal, precision: 11, scale: 8

      # Distance & Elevation
      add :distance_km, :decimal, precision: 8, scale: 2
      add :elevation_gain_m, :integer
      add :elevation_loss_m, :integer

      # Performance (for completed races)
      add :finish_time_seconds, :integer
      add :overall_position, :integer
      add :category_position, :integer
      add :total_participants, :integer

      # Conditions
      add :weather_conditions, :string
      add :temperature_celsius, :integer
      add :surface_type, :string
      add :terrain_difficulty, :integer

      # Your story
      add :race_report, :text
      add :highlights, :text
      add :difficulties, :text
      add :gear_used, :text

      # Media
      add :cover_photo_url, :string
      add :has_gpx, :boolean, default: false

      # Registration & Cost
      add :official_website, :string
      add :registration_url, :string
      add :cost_eur, :decimal, precision: 10, scale: 2
      add :registration_deadline, :date
      add :is_registered, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    # Indexes for fast queries
    create index(:races, [:athlete_id])
    create index(:races, [:race_date])
    create index(:races, [:status])
    create index(:races, [:race_type])
    create index(:races, [:athlete_id, :status])
  end
end
