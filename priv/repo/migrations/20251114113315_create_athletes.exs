defmodule TrailChronicle.Repo.Migrations.CreateAthletes do
  use Ecto.Migration

  def change do
    create table(:athletes, primary_key: false) do
      add :id, :binary_id, primary_key: true

      # Authentication
      add :email, :string, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime

      # Profile
      add :first_name, :string
      add :last_name, :string
      add :bio, :text
      add :date_of_birth, :date
      add :gender, :string
      add :country, :string
      add :city, :string

      # Physical stats
      add :height_cm, :integer
      add :weight_kg, :decimal, precision: 5, scale: 2

      # Running stats
      add :running_since_year, :integer
      add :favorite_distance, :string
      add :max_heart_rate, :integer
      add :resting_heart_rate, :integer

      # Preferences
      add :preferred_language, :string, default: "en"
      add :preferred_unit_system, :string, default: "metric"
      add :timezone, :string, default: "Europe/Bucharest"

      # Computed stats (updated by app logic)
      add :total_races, :integer, default: 0
      add :total_distance_km, :decimal, precision: 10, scale: 2, default: 0
      add :total_elevation_m, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    # Indexes for fast lookups
    create unique_index(:athletes, [:email])
  end
end
