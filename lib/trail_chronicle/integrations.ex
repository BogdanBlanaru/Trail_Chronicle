defmodule TrailChronicle.Integrations do
  @moduledoc """
  Context for managing external integrations (Strava, etc.)
  """

  alias TrailChronicle.Repo
  alias TrailChronicle.Integrations.{StravaIntegration, StravaClient}
  alias TrailChronicle.Accounts.Athlete
  alias TrailChronicle.Racing

  # --- Strava Integration CRUD ---

  def get_strava_integration(%Athlete{id: athlete_id}) do
    Repo.get_by(StravaIntegration, athlete_id: athlete_id)
  end

  def create_strava_integration(%Athlete{} = athlete, token_data) do
    %StravaIntegration{}
    |> StravaIntegration.changeset(%{
      athlete_id: athlete.id,
      strava_athlete_id: token_data["athlete"]["id"],
      access_token: token_data["access_token"],
      refresh_token: token_data["refresh_token"],
      expires_at: DateTime.from_unix!(token_data["expires_at"])
    })
    |> Repo.insert()
  end

  def update_strava_tokens(integration, token_data) do
    integration
    |> StravaIntegration.changeset(%{
      access_token: token_data["access_token"],
      refresh_token: token_data["refresh_token"],
      expires_at: DateTime.from_unix!(token_data["expires_at"])
    })
    |> Repo.update()
  end

  def disconnect_strava(%Athlete{} = athlete) do
    case get_strava_integration(athlete) do
      nil -> {:error, :not_connected}
      integration -> Repo.delete(integration)
    end
  end

  def refresh_strava_token(%StravaIntegration{} = integration) do
    case StravaClient.refresh_token(integration.refresh_token) do
      {:ok, %{status: 200, body: token_data}} ->
        update_strava_tokens(integration, token_data)

      {:ok, %{status: status}} ->
        {:error, "Failed to refresh token: HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def ensure_valid_token(%StravaIntegration{} = integration) do
    now = DateTime.utc_now()

    if DateTime.compare(integration.expires_at, now) == :lt do
      # Token expired, refresh it
      case refresh_strava_token(integration) do
        {:ok, updated} -> {:ok, updated}
        error -> error
      end
    else
      {:ok, integration}
    end
  end

  # --- Strava Activity Import ---

  def import_strava_activities(%Athlete{} = athlete) do
    with {:ok, integration} <- fetch_valid_integration(athlete),
         {:ok, activities} <- fetch_strava_activities(integration) do
      imported =
        activities
        |> Enum.map(&map_strava_activity_to_race/1)
        |> Enum.map(&import_activity(athlete, &1))
        |> Enum.count(fn result -> match?({:ok, _}, result) end)

      # Update last sync timestamp
      integration
      |> StravaIntegration.changeset(%{last_sync_at: DateTime.utc_now()})
      |> Repo.update()

      {:ok, imported}
    end
  end

  defp fetch_valid_integration(athlete) do
    case get_strava_integration(athlete) do
      nil -> {:error, :not_connected}
      integration -> ensure_valid_token(integration)
    end
  end

  defp fetch_strava_activities(integration) do
    # Fetch activities from last 90 days
    after_timestamp = DateTime.utc_now() |> DateTime.add(-90, :day) |> DateTime.to_unix()

    case StravaClient.get_activities(integration.access_token, after: after_timestamp) do
      {:ok, %{status: 200, body: activities}} when is_list(activities) ->
        {:ok, activities}

      {:ok, %{status: status}} ->
        {:error, "Failed to fetch activities: HTTP #{status}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp map_strava_activity_to_race(strava_activity) do
    %{
      "name" => strava_activity["name"],
      "race_date" => parse_strava_date(strava_activity["start_date_local"]),
      "distance_km" => strava_activity["distance"] / 1000.0,
      "elevation_gain_m" => round(strava_activity["total_elevation_gain"] || 0),
      "finish_time_seconds" => strava_activity["moving_time"],
      "race_type" => classify_strava_activity(strava_activity),
      "status" => "completed",
      "surface_type" => determine_surface(strava_activity),
      "race_report" => "Imported from Strava"
    }
  end

  defp parse_strava_date(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _} -> DateTime.to_date(datetime)
      _ -> Date.utc_today()
    end
  end

  defp classify_strava_activity(activity) do
    dist = activity["distance"] / 1000.0

    cond do
      dist >= 43 -> "ultra"
      dist >= 42 -> "marathon"
      dist >= 21 -> "half_marathon"
      dist >= 9 && dist <= 11 -> "10k"
      dist >= 4 && dist <= 6 -> "5k"
      true -> "trail"
    end
  end

  defp determine_surface(activity) do
    type = String.downcase(activity["type"] || "")
    if type == "trail_run" or type == "hike", do: "trail", else: "asphalt"
  end

  defp import_activity(athlete, attrs) do
    # Check if activity already exists (by name + date)
    existing =
      Racing.list_races(athlete)
      |> Enum.find(fn race ->
        race.name == attrs["name"] && race.race_date == attrs["race_date"]
      end)

    if existing do
      {:ok, existing}
    else
      Racing.create_race(athlete, attrs)
    end
  end
end
