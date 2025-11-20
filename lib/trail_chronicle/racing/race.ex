defmodule TrailChronicle.Racing.Race do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  # Valid race types
  @race_types ~w(trail road ultra marathon half_marathon 10k 5k other)

  # Valid race statuses
  @statuses ~w(upcoming completed cancelled dns dnf)

  # Valid surface types
  @surface_types ~w(trail asphalt mixed gravel sand snow)

  schema "races" do
    # Relationship
    belongs_to :athlete, TrailChronicle.Accounts.Athlete

    # Basic info
    field :name, :string
    field :race_date, :date
    field :race_type, :string
    field :status, :string, default: "upcoming"

    # Location
    field :country, :string
    field :city, :string
    field :latitude, :decimal
    field :longitude, :decimal

    # Distance & Elevation
    field :distance_km, :decimal
    field :elevation_gain_m, :integer
    field :elevation_loss_m, :integer

    # Performance (for completed races)
    field :finish_time_seconds, :integer
    field :overall_position, :integer
    field :category_position, :integer
    field :total_participants, :integer

    # Conditions
    field :weather_conditions, :string
    field :temperature_celsius, :integer
    field :surface_type, :string
    field :terrain_difficulty, :integer

    # Your story
    field :race_report, :string
    field :highlights, :string
    field :difficulties, :string
    field :gear_used, :string

    # Media
    field :cover_photo_url, :string
    field :has_gpx, :boolean, default: false

    # Registration & Cost
    field :official_website, :string
    field :registration_url, :string
    field :cost_eur, :decimal
    field :registration_deadline, :date
    field :is_registered, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc """
  Returns list of valid race types.
  """
  def race_types, do: @race_types

  @doc """
  Returns list of valid statuses.
  """
  def statuses, do: @statuses

  @doc """
  Returns list of valid surface types.
  """
  def surface_types, do: @surface_types

  @doc """
  Changeset for creating a new race.
  """
  def changeset(race, attrs) do
    race
    |> cast(attrs, [
      :athlete_id,
      :name,
      :race_date,
      :race_type,
      :status,
      :country,
      :city,
      :latitude,
      :longitude,
      :distance_km,
      :elevation_gain_m,
      :elevation_loss_m,
      :finish_time_seconds,
      :overall_position,
      :category_position,
      :total_participants,
      :weather_conditions,
      :temperature_celsius,
      :surface_type,
      :terrain_difficulty,
      :race_report,
      :highlights,
      :difficulties,
      :gear_used,
      :cover_photo_url,
      :has_gpx,
      :official_website,
      :registration_url,
      :cost_eur,
      :registration_deadline,
      :is_registered
    ])
    |> validate_required([:athlete_id, :name, :race_date])
    |> validate_inclusion(:race_type, @race_types)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:surface_type, @surface_types)
    |> validate_number(:distance_km, greater_than: 0, less_than: 1000)
    |> validate_number(:elevation_gain_m, greater_than_or_equal_to: 0)
    |> validate_number(:elevation_loss_m, greater_than_or_equal_to: 0)
    |> validate_number(:terrain_difficulty, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_number(:latitude, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:longitude, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
    |> validate_number(:finish_time_seconds, greater_than: 0)
    |> validate_number(:overall_position, greater_than: 0)
    |> validate_number(:category_position, greater_than: 0)
    |> validate_number(:total_participants, greater_than: 0)
    |> validate_performance_fields()
    |> foreign_key_constraint(:athlete_id)
  end

  @doc """
  Changeset for completing a race (updating with results).
  """
  def completion_changeset(race, attrs) do
    race
    |> cast(attrs, [
      :status,
      :finish_time_seconds,
      :overall_position,
      :category_position,
      :total_participants,
      :weather_conditions,
      :temperature_celsius,
      :race_report,
      :highlights,
      :difficulties,
      :gear_used
    ])
    |> validate_required([:status])
    |> validate_inclusion(:status, ["completed", "dnf", "dns"])
    |> validate_performance_fields()
  end

  # Private function to validate performance fields consistency
  defp validate_performance_fields(changeset) do
    status = get_field(changeset, :status)
    finish_time = get_change(changeset, :finish_time_seconds)

    cond do
      status == "completed" && is_nil(finish_time) ->
        add_error(changeset, :finish_time_seconds, "is required for completed races")

      status in ["dns", "dnf", "cancelled"] && !is_nil(finish_time) ->
        add_error(
          changeset,
          :finish_time_seconds,
          "should not be set for DNS/DNF/cancelled races"
        )

      true ->
        changeset
    end
  end
end
