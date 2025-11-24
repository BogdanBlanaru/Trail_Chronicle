defmodule TrailChronicle.Integrations.StravaIntegration do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "strava_integrations" do
    belongs_to :athlete, TrailChronicle.Accounts.Athlete

    field :strava_athlete_id, :integer
    field :access_token, :string
    field :refresh_token, :string
    field :expires_at, :utc_datetime

    field :last_sync_at, :utc_datetime
    field :is_active, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  def changeset(integration, attrs) do
    integration
    |> cast(attrs, [
      :athlete_id,
      :strava_athlete_id,
      :access_token,
      :refresh_token,
      :expires_at,
      :last_sync_at,
      :is_active
    ])
    |> validate_required([
      :athlete_id,
      :strava_athlete_id,
      :access_token,
      :refresh_token,
      :expires_at
    ])
    |> unique_constraint(:athlete_id)
  end
end
