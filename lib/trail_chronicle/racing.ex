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

  @doc """
  Gets year-to-date summary.
  """
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

  @doc """
  Returns a list of years that have race data for the athlete.
  """
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

  def update_race_gpx(race, gpx_file_path) do
    case File.read(gpx_file_path) do
      {:ok, xml_content} ->
        points =
          xml_content
          |> xpath(~x"//trkpt"l, lat: ~x"./@lat"s, lon: ~x"./@lon"s)
          |> Enum.map(fn %{lat: lat, lon: lon} ->
            [String.to_float(lat), String.to_float(lon)]
          end)

        update_race(race, %{route_data: points, has_gpx: true})

      _ ->
        {:error, :invalid_file}
    end
  end
end
