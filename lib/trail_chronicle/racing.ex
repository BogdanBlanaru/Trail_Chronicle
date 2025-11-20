defmodule TrailChronicle.Racing do
  @moduledoc """
  The Racing context.
  """
  import Ecto.Query, warn: false
  alias TrailChronicle.Repo
  alias TrailChronicle.Racing.{Race, RacePhoto}
  alias TrailChronicle.Accounts.Athlete
  import SweetXml

  # --- RACE CRUD ---

  def list_races(%Athlete{id: athlete_id}) do
    Race
    |> where([r], r.athlete_id == ^athlete_id)
    |> order_by([r], desc: r.race_date)
    |> Repo.all()
  end

  def list_upcoming_races(%Athlete{id: athlete_id}) do
    today = Date.utc_today()

    Race
    |> where([r], r.athlete_id == ^athlete_id)
    |> where([r], r.status == "upcoming")
    |> where([r], r.race_date >= ^today)
    |> order_by([r], asc: r.race_date)
    |> Repo.all()
  end

  def list_completed_races(%Athlete{id: athlete_id}) do
    Race
    |> where([r], r.athlete_id == ^athlete_id)
    |> where([r], r.status == "completed")
    |> order_by([r], desc: r.race_date)
    |> Repo.all()
  end

  def get_race!(id), do: Repo.get!(Race, id)

  def get_race_with_athlete!(id) do
    Race
    |> Repo.get!(id)
    |> Repo.preload(:athlete)
  end

  def create_race(%Athlete{id: athlete_id}, attrs \\ %{}) do
    attrs_with_athlete = Map.put(attrs, "athlete_id", athlete_id)

    %Race{}
    |> Race.changeset(attrs_with_athlete)
    |> Repo.insert()
  end

  def update_race(%Race{} = race, attrs) do
    race
    |> Race.changeset(attrs)
    |> Repo.update()
  end

  def complete_race(%Race{} = race, results) do
    results_with_status = Map.put(results, "status", "completed")

    race
    |> Race.completion_changeset(results_with_status)
    |> Repo.update()
  end

  def delete_race(%Race{} = race) do
    Repo.delete(race)
  end

  def change_race(%Race{} = race, attrs \\ %{}) do
    Race.changeset(race, attrs)
  end

  # --- STATS & CHARTS ---

  def get_race_stats(%Athlete{id: athlete_id}) do
    stats =
      Race
      |> where([r], r.athlete_id == ^athlete_id)
      |> where([r], r.status == "completed")
      |> select([r], %{
        total_races: count(r.id),
        total_distance_km: sum(r.distance_km),
        total_elevation_gain_m: sum(r.elevation_gain_m)
      })
      |> Repo.one()

    %{
      total_races: stats.total_races || 0,
      total_distance_km: stats.total_distance_km || Decimal.new(0),
      total_elevation_gain_m: stats.total_elevation_gain_m || 0
    }
  end

  def get_ytd_stats(%Athlete{id: athlete_id}, year) do
    start_of_year = Date.new!(year, 1, 1)
    end_of_year = Date.new!(year, 12, 31)

    Race
    |> where([r], r.athlete_id == ^athlete_id)
    |> where([r], r.status == "completed")
    |> where([r], r.race_date >= ^start_of_year and r.race_date <= ^end_of_year)
    |> select([r], %{
      count: count(r.id),
      distance: sum(r.distance_km),
      elevation: sum(r.elevation_gain_m),
      time: sum(r.finish_time_seconds)
    })
    |> Repo.one()
  end

  def list_race_years(%Athlete{id: athlete_id}) do
    query =
      from r in Race,
        where: r.athlete_id == ^athlete_id,
        select: fragment("DISTINCT EXTRACT(YEAR FROM ?)::integer", r.race_date),
        order_by: [desc: fragment("EXTRACT(YEAR FROM ?)::integer", r.race_date)]

    Repo.all(query)
  end

  def list_races_between(%Athlete{id: athlete_id}, start_date, end_date) do
    Race
    |> where([r], r.athlete_id == ^athlete_id)
    |> where([r], r.race_date >= ^start_date and r.race_date <= ^end_date)
    |> order_by([r], asc: r.race_date)
    |> Repo.all()
  end

  def get_monthly_distance_stats(%Athlete{id: athlete_id}, year) do
    start_of_year = Date.new!(year, 1, 1)
    end_of_year = Date.new!(year, 12, 31)

    Race
    |> where([r], r.athlete_id == ^athlete_id)
    |> where([r], r.status == "completed")
    |> where([r], r.race_date >= ^start_of_year and r.race_date <= ^end_of_year)
    |> group_by([r], fragment("EXTRACT(MONTH FROM ?)", r.race_date))
    |> select([r], %{
      month: fragment("EXTRACT(MONTH FROM ?)::integer", r.race_date),
      total_km: sum(r.distance_km)
    })
    |> order_by([r], fragment("EXTRACT(MONTH FROM ?)", r.race_date))
    |> Repo.all()
  end

  def get_yearly_stats(%Athlete{id: athlete_id}, year) do
    start_of_year = Date.new!(year, 1, 1)
    end_of_year = Date.new!(year, 12, 31)

    stats =
      Race
      |> where([r], r.athlete_id == ^athlete_id)
      |> where([r], r.status == "completed")
      |> where([r], r.race_date >= ^start_of_year and r.race_date <= ^end_of_year)
      |> select([r], %{
        count: count(r.id),
        distance: sum(r.distance_km),
        elevation: sum(r.elevation_gain_m),
        time: sum(r.finish_time_seconds)
      })
      |> Repo.one()

    %{
      count: stats.count || 0,
      distance: stats.distance || Decimal.new(0),
      elevation: stats.elevation || 0,
      time: stats.time || 0
    }
  end

  def get_personal_bests(%Athlete{id: athlete_id}) do
    ["marathon", "half_marathon", "10k", "ultra"]
    |> Enum.map(fn type ->
      best_race =
        Race
        |> where([r], r.athlete_id == ^athlete_id)
        |> where([r], r.status == "completed")
        |> where([r], r.race_type == ^type)
        |> order_by([r], asc: r.finish_time_seconds)
        |> limit(1)
        |> Repo.one()

      {type, best_race}
    end)
    |> Enum.filter(fn {_, race} -> race != nil end)
    |> Enum.into(%{})
  end

  def get_races_by_type(%Athlete{id: athlete_id}, year) do
    start_of_year = Date.new!(year, 1, 1)
    end_of_year = Date.new!(year, 12, 31)

    Race
    |> where([r], r.athlete_id == ^athlete_id)
    |> where([r], r.race_date >= ^start_of_year and r.race_date <= ^end_of_year)
    |> group_by([r], r.race_type)
    |> select([r], {r.race_type, count(r.id)})
    |> Repo.all()
    |> Enum.into(%{})
  end

  def get_activity_dates(%Athlete{id: athlete_id}, year) do
    start_of_year = Date.new!(year, 1, 1)
    end_of_year = Date.new!(year, 12, 31)

    Race
    |> where([r], r.athlete_id == ^athlete_id)
    |> where([r], r.race_date >= ^start_of_year and r.race_date <= ^end_of_year)
    |> select([r], {r.race_date, r.status})
    |> Repo.all()
    |> Enum.into(%{})
  end

  # --- PHOTOS & GPX ---

  def create_photo(attrs \\ %{}) do
    %RacePhoto{}
    |> RacePhoto.changeset(attrs)
    |> Repo.insert()
  end

  def list_race_photos(race_id) do
    RacePhoto
    |> where([p], p.race_id == ^race_id)
    |> order_by([p], desc: p.inserted_at)
    |> Repo.all()
  end

  @doc """
  Parses a GPX file, extracts the track, calculates stats, and updates the race.
  """
  def update_race_gpx(race, gpx_file_path) do
    case File.read(gpx_file_path) do
      {:ok, xml_content} ->
        # 1. Extract Points with Elevation
        points =
          xml_content
          |> xpath(
            ~x"//trkpt"l,
            lat: ~x"./@lat"s,
            lon: ~x"./@lon"s,
            ele: ~x"./ele/text()"s
          )
          |> Enum.map(fn %{lat: lat, lon: lon, ele: ele} ->
            %{
              lat: String.to_float(lat),
              lon: String.to_float(lon),
              ele: parse_float(ele)
            }
          end)

        if length(points) > 0 do
          # 2. Calculate Stats
          {total_dist, total_gain, total_loss} = calculate_track_stats(points)

          # 3. Format: Wrap in a Map because Ecto :map requires %{}
          # Leaflet expects [[lat, lon], ...] so we store it under a key "coordinates"
          route_wrapper = %{
            "coordinates" => Enum.map(points, fn p -> [p.lat, p.lon] end)
          }

          # 4. Update Race with new data
          update_race(race, %{
            # Pass the map, not the list
            route_data: route_wrapper,
            has_gpx: true,
            distance_km: Float.round(total_dist / 1000, 2),
            elevation_gain_m: round(total_gain),
            elevation_loss_m: round(total_loss)
          })
        else
          {:error, :no_track_points}
        end

      _ ->
        {:error, :invalid_file}
    end
  end

  # --- GPS Math Helpers ---

  defp parse_float(""), do: 0.0
  defp parse_float(nil), do: 0.0

  defp parse_float(str) do
    String.to_float(str)
  rescue
    _ -> 0.0
  end

  defp calculate_track_stats(points) do
    # Reduce list to calculate running totals
    {_, dist, gain, loss} =
      Enum.reduce(points, {nil, 0.0, 0.0, 0.0}, fn point, {prev, d, g, l} ->
        if prev do
          # Distance (Haversine formula simplified)
          new_dist = distance_between(prev, point)

          # Elevation
          ele_diff = point.ele - prev.ele
          new_gain = if ele_diff > 0, do: g + ele_diff, else: g
          new_loss = if ele_diff < 0, do: l + abs(ele_diff), else: l

          {point, d + new_dist, new_gain, new_loss}
        else
          {point, 0.0, 0.0, 0.0}
        end
      end)

    {dist, gain, loss}
  end

  # Calculate distance in meters between two coords
  defp distance_between(p1, p2) do
    rad = :math.pi() / 180
    # Earth radius in meters
    r = 6_371_000

    d_lat = (p2.lat - p1.lat) * rad
    d_lon = (p2.lon - p1.lon) * rad
    lat1 = p1.lat * rad
    lat2 = p2.lat * rad

    a =
      :math.sin(d_lat / 2) * :math.sin(d_lat / 2) +
        :math.sin(d_lon / 2) * :math.sin(d_lon / 2) * :math.cos(lat1) * :math.cos(lat2)

    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))
    r * c
  end
end
