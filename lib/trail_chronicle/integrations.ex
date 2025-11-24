defmodule TrailChronicle.Integrations do
  @moduledoc """
  Context for managing external integrations (Strava, etc.)
  """
  import Bitwise
  import Ecto.Query

  alias TrailChronicle.Repo
  alias TrailChronicle.Integrations.{StravaIntegration, StravaClient}
  alias TrailChronicle.Accounts.Athlete
  alias TrailChronicle.Racing
  alias TrailChronicle.Racing.Shoe

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
         {:ok, activities} <- fetch_all_strava_activities(integration) do
      # Import one by one (accumulate count)
      imported_count =
        Enum.reduce(activities, 0, fn activity, count ->
          case import_activity(activity, athlete, integration.access_token) do
            {:ok, _} -> count + 1
            _ -> count
          end
        end)

      # Update last sync timestamp
      integration
      |> StravaIntegration.changeset(%{last_sync_at: DateTime.utc_now()})
      |> Repo.update()

      {:ok, imported_count}
    end
  end

  defp fetch_valid_integration(athlete) do
    case get_strava_integration(athlete) do
      nil -> {:error, :not_connected}
      integration -> ensure_valid_token(integration)
    end
  end

  # --- PAGINATION LOGIC ---
  defp fetch_all_strava_activities(integration) do
    # Go back 10 years (approx 3650 days)
    after_timestamp = DateTime.utc_now() |> DateTime.add(-3650, :day) |> DateTime.to_unix()
    fetch_activities_recursive(integration.access_token, after_timestamp, 1, [])
  end

  defp fetch_activities_recursive(access_token, after_ts, page, acc) do
    IO.puts("Fetching Strava page #{page}...")

    case StravaClient.get_activities(access_token, after: after_ts, page: page, per_page: 50) do
      {:ok, %{status: 200, body: []}} ->
        {:ok, List.flatten(acc)}

      {:ok, %{status: 200, body: activities}} when is_list(activities) ->
        fetch_activities_recursive(access_token, after_ts, page + 1, [activities | acc])

      error ->
        IO.warn("Strava fetch error on page #{page}: #{inspect(error)}")
        {:ok, List.flatten(acc)}
    end
  end

  defp import_activity(activity, athlete, access_token) do
    # Check for duplicates first
    existing =
      Racing.get_race_by_name_and_date(
        athlete,
        activity["name"],
        parse_date(activity["start_date_local"])
      )

    if existing do
      {:ok, :duplicate}
    else
      # 1. Try to fetch DETAILED STREAMS (for Elevation Chart)
      stream_route = fetch_detailed_route(activity["id"], access_token)

      # 2. Fallback to simple polyline if stream fails (flat chart, but works)
      route_data = stream_route || build_route_from_polyline(activity["map"]["summary_polyline"])

      race_date = parse_date(activity["start_date_local"])
      surface_type = determine_surface(activity["type"])

      # 3. Find Smart Shoe
      shoe_id = find_matching_shoe(athlete, race_date, surface_type)

      attrs = %{
        "athlete_id" => athlete.id,
        "shoe_id" => shoe_id,
        "name" => activity["name"],
        "race_date" => race_date,
        "distance_km" => Decimal.from_float(activity["distance"] / 1000.0),
        "elevation_gain_m" => round(activity["total_elevation_gain"] || 0),
        "finish_time_seconds" => activity["moving_time"],
        "status" => "completed",
        "race_type" => classify_race_type(activity["distance"]),
        "surface_type" => surface_type,
        "has_gpx" => route_data != nil,
        "route_data" => route_data,
        "race_report" => "Imported from Strava",
        "is_registered" => false
      }

      Racing.create_race(athlete, attrs)
    end
  end

  # --- STREAM FETCHING (The Chart Fix) ---
  defp fetch_detailed_route(activity_id, access_token) do
    # Sleep briefly to be nice to Strava API rate limits
    Process.sleep(100)

    case StravaClient.get_activity_streams(access_token, activity_id) do
      {:ok, %{status: 200, body: streams}} ->
        latlngs = get_in(streams, ["latlng", "data"])
        alts = get_in(streams, ["altitude", "data"])

        if latlngs && alts do
          # Combine [lat, lng] with altitude -> [lat, lng, alt]
          # Zip ensures we only take points where we have both data
          coordinates =
            Enum.zip(latlngs, alts)
            |> Enum.map(fn {[lat, lng], alt} -> [lat, lng, alt] end)

          %{"coordinates" => coordinates}
        else
          nil
        end

      _ ->
        nil
    end
  end

  # --- SHOE LOGIC ---
  defp find_matching_shoe(athlete, race_date, surface) do
    required_category = if surface == "trail", do: "trail", else: "road"

    # Find shoe purchased BEFORE race, matches category, newest first
    query =
      from s in Shoe,
        where: s.athlete_id == ^athlete.id,
        where: s.purchased_at <= ^race_date,
        where: s.category == ^required_category,
        order_by: [desc: s.purchased_at],
        limit: 1

    case Repo.one(query) do
      nil -> nil
      shoe -> shoe.id
    end
  end

  # --- HELPERS ---

  defp parse_date(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _} -> DateTime.to_date(datetime)
      _ -> Date.utc_today()
    end
  end

  defp classify_race_type(distance_meters) do
    dist_km = distance_meters / 1000.0

    cond do
      dist_km >= 45 -> "ultra"
      dist_km >= 40 && dist_km <= 45 -> "marathon"
      dist_km >= 19 && dist_km <= 25 -> "half_marathon"
      dist_km >= 9 && dist_km <= 12 -> "10k"
      dist_km >= 4 && dist_km <= 6 -> "5k"
      true -> "trail"
    end
  end

  defp determine_surface(activity_type) do
    type = String.downcase(activity_type || "")
    if type == "trail_run" or type == "hike", do: "trail", else: "asphalt"
  end

  # --- Fallback Polyline Decoder ---
  defp build_route_from_polyline(nil), do: nil
  defp build_route_from_polyline(""), do: nil

  defp build_route_from_polyline(polyline) do
    points = decode_polyline(polyline)

    if length(points) > 0 do
      %{"coordinates" => Enum.map(points, fn {lat, lon} -> [lat, lon, 0.0] end)}
    else
      nil
    end
  end

  defp decode_polyline(encoded), do: decode_polyline(encoded, [], 0, 0)
  defp decode_polyline("", acc, _lat, _lng), do: Enum.reverse(acc)

  defp decode_polyline(encoded, acc, lat, lng) do
    {new_lat, rest1} = decode_value(encoded, 0, 0)
    {new_lng, rest2} = decode_value(rest1, 0, 0)
    lat = lat + new_lat
    lng = lng + new_lng
    decode_polyline(rest2, [{lat / 1.0e5, lng / 1.0e5} | acc], lat, lng)
  end

  defp decode_value(<<>>, value, _), do: {value, ""}

  defp decode_value(<<char, rest::binary>>, value, shift) do
    b = char - 63
    value = value ||| (b &&& 0x1F) <<< shift

    if (b &&& 0x20) != 0 do
      decode_value(rest, value, shift + 5)
    else
      value = if (value &&& 1) != 0, do: ~~~value >>> 1, else: value >>> 1
      {value, rest}
    end
  end
end
