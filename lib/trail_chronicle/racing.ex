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
      {:ok, raw_content} ->
        # 1. Sanitize XML (Remove namespaces aggressively)
        xml_content = sanitize_xml(raw_content)

        # 2. Parse Points
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
              lat: parse_float(lat),
              lon: parse_float(lon),
              ele: parse_float(ele)
            }
          end)
          # Filter out points where parsing failed (0.0 lat/lon is unlikely valid)
          |> Enum.filter(fn p -> p.lat != 0.0 and p.lon != 0.0 end)

        if length(points) > 1 do
          # 3. Calculate Stats
          {total_dist, total_gain, total_loss} = calculate_track_stats(points)
          dist_km = total_dist / 1000.0

          # 4. Format for Map
          route_wrapper = %{
            "coordinates" => Enum.map(points, fn p -> [p.lat, p.lon] end)
          }

          # 5. Auto-Calculate Difficulty
          climb_ratio = if dist_km > 0, do: total_gain / dist_km, else: 0
          difficulty = calculate_difficulty(climb_ratio)

          # 6. Smart Description
          smart_report =
            if is_nil(race.race_report) or race.race_report == "" do
              generate_smart_description(dist_km, total_gain, climb_ratio)
            else
              race.race_report
            end

          # 7. Update
          update_race(race, %{
            route_data: route_wrapper,
            has_gpx: true,
            distance_km: Float.round(dist_km, 2),
            elevation_gain_m: round(total_gain),
            elevation_loss_m: round(total_loss),
            terrain_difficulty: difficulty,
            race_report: smart_report
          })
        else
          {:error, :no_track_points}
        end

      _ ->
        {:error, :invalid_file}
    end
  end

  # --- HELPERS ---

  defp sanitize_xml(content) do
    # Remove XML declaration and namespaces to ensure SweetXml finds tags easily
    content
    |> String.replace(~r/<\?xml.*\?>/, "")
    |> String.replace(~r/xmlns="[^"]*"/, "")
    |> String.replace(~r/xmlns:[a-z0-9]+="[^"]*"/, "")
  end

  defp parse_float(nil), do: 0.0
  defp parse_float(""), do: 0.0

  defp parse_float(val) when is_binary(val) do
    case Float.parse(val) do
      {num, _} ->
        num

      :error ->
        # Fallback for Integers like "592"
        case Integer.parse(val) do
          {int_num, _} -> int_num / 1.0
          :error -> 0.0
        end
    end
  end

  defp parse_float(_), do: 0.0

  defp calculate_track_stats(points) do
    # Threshold: 3 meters vertical to count as "gain".
    # This filters out GPS noise (1m up, 1m down jitter).
    threshold = 3.0

    {_, dist, gain, loss, _ref_ele} =
      Enum.reduce(points, {nil, 0.0, 0.0, 0.0, nil}, fn point, {prev, d, g, l, ref_ele} ->
        if prev do
          # Distance is always accumulated
          new_dist = d + distance_between(prev, point)

          # Elevation Logic
          current_ele = point.ele

          # If no reference elevation yet, set it
          ref = if ref_ele, do: ref_ele, else: prev.ele

          diff = current_ele - ref

          {new_g, new_l, new_ref} =
            cond do
              # Significant Climb (> 3m)
              diff > threshold ->
                {g + diff, l, current_ele}

              # Significant Descent (> 3m)
              diff < -threshold ->
                {g, l + abs(diff), current_ele}

              # Noise (change < 3m) -> Ignore change, keep old ref
              true ->
                {g, l, ref}
            end

          {point, new_dist, new_g, new_l, new_ref}
        else
          # First point
          {point, 0.0, 0.0, 0.0, point.ele}
        end
      end)

    {dist, gain, loss}
  end

  defp calculate_difficulty(ratio) do
    cond do
      ratio < 10 -> 1
      ratio < 25 -> 2
      ratio < 40 -> 3
      ratio < 60 -> 4
      true -> 5
    end
  end

  defp generate_smart_description(dist, gain, ratio) do
    dist_desc =
      cond do
        dist < 10 -> "short effort"
        dist < 22 -> "half-marathon distance"
        dist < 43 -> "marathon distance"
        true -> "ultra endurance challenge"
      end

    terrain_desc =
      cond do
        ratio < 10 -> "mostly flat profile"
        ratio < 30 -> "rolling hills"
        true -> "significant mountain climbing"
      end

    "A #{dist_desc} covering #{Float.round(dist, 1)}km with #{round(gain)}m of gain. The route features a #{terrain_desc}."
  end

  defp distance_between(p1, p2) do
    rad = :math.pi() / 180
    r = 6_371_000

    d_lat = (p2.lat - p1.lat) * rad
    d_lon = (p2.lon - p1.lon) * rad

    a =
      :math.sin(d_lat / 2) * :math.sin(d_lat / 2) +
        :math.sin(d_lon / 2) * :math.sin(d_lon / 2) * :math.cos(p1.lat * rad) *
          :math.cos(p2.lat * rad)

    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))
    r * c
  end
end
