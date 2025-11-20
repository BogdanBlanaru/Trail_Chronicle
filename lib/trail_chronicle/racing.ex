defmodule TrailChronicle.Racing do
  @moduledoc """
  The Racing context.

  Manages races, results, and race-related functionality.
  """

  import Ecto.Query, warn: false
  alias TrailChronicle.Repo
  alias TrailChronicle.Racing.Race
  alias TrailChronicle.Accounts.Athlete

  ## Race CRUD

  @doc """
  Returns the list of all races for an athlete.

  ## Examples

      iex> list_races(athlete)
      [%Race{}, ...]

  """
  def list_races(%Athlete{id: athlete_id}) do
    Race
    |> where([r], r.athlete_id == ^athlete_id)
    |> order_by([r], desc: r.race_date)
    |> Repo.all()
  end

  @doc """
  Returns the list of upcoming races for an athlete.

  ## Examples

      iex> list_upcoming_races(athlete)
      [%Race{status: "upcoming"}, ...]

  """
  def list_upcoming_races(%Athlete{id: athlete_id}) do
    today = Date.utc_today()

    Race
    |> where([r], r.athlete_id == ^athlete_id)
    |> where([r], r.status == "upcoming")
    |> where([r], r.race_date >= ^today)
    |> order_by([r], asc: r.race_date)
    |> Repo.all()
  end

  @doc """
  Returns the list of completed races for an athlete.

  ## Examples

      iex> list_completed_races(athlete)
      [%Race{status: "completed"}, ...]

  """
  def list_completed_races(%Athlete{id: athlete_id}) do
    Race
    |> where([r], r.athlete_id == ^athlete_id)
    |> where([r], r.status == "completed")
    |> order_by([r], desc: r.race_date)
    |> Repo.all()
  end

  @doc """
  Gets a single race by ID.

  Raises `Ecto.NoResultsError` if the Race does not exist.

  ## Examples

      iex> get_race!(123)
      %Race{}

      iex> get_race!(456)
      ** (Ecto.NoResultsError)

  """
  def get_race!(id) do
    Repo.get!(Race, id)
  end

  @doc """
  Gets a single race by ID, preloading the athlete.

  ## Examples

      iex> get_race_with_athlete!(race_id)
      %Race{athlete: %Athlete{}}

  """
  def get_race_with_athlete!(id) do
    Race
    |> Repo.get!(id)
    |> Repo.preload(:athlete)
  end

  @doc """
  Creates a race for an athlete.

  ## Examples

      iex> create_race(athlete, %{name: "Retezat Sky Race", ...})
      {:ok, %Race{}}

      iex> create_race(athlete, %{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_race(%Athlete{id: athlete_id}, attrs \\ %{}) do
    attrs_with_athlete = Map.put(attrs, "athlete_id", athlete_id)

    %Race{}
    |> Race.changeset(attrs_with_athlete)
    |> Repo.insert()
  end

  @doc """
  Updates a race.

  ## Examples

      iex> update_race(race, %{name: "Updated Name"})
      {:ok, %Race{}}

      iex> update_race(race, %{distance_km: -10})
      {:error, %Ecto.Changeset{}}

  """
  def update_race(%Race{} = race, attrs) do
    race
    |> Race.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Marks a race as completed with results.

  ## Examples

      iex> complete_race(race, %{finish_time_seconds: 15000, overall_position: 23})
      {:ok, %Race{status: "completed"}}

  """
  def complete_race(%Race{} = race, results) do
    results_with_status = Map.put(results, "status", "completed")

    race
    |> Race.completion_changeset(results_with_status)
    |> Repo.update()
  end

  @doc """
  Deletes a race.

  ## Examples

      iex> delete_race(race)
      {:ok, %Race{}}

      iex> delete_race(race)
      {:error, %Ecto.Changeset{}}

  """
  def delete_race(%Race{} = race) do
    Repo.delete(race)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking race changes.

  ## Examples

      iex> change_race(race)
      %Ecto.Changeset{data: %Race{}}

  """
  def change_race(%Race{} = race, attrs \\ %{}) do
    Race.changeset(race, attrs)
  end

  ## Statistics

  @doc """
  Gets race statistics for an athlete.

  Returns a map with:
  - total_races: count of completed races
  - total_distance_km: sum of distances
  - total_elevation_gain_m: sum of elevation gains

  ## Examples

      iex> get_race_stats(athlete)
      %{total_races: 15, total_distance_km: 450.5, total_elevation_gain_m: 12000}

  """
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
  Returns races within a specific date range.
  """
  def list_races_between(%Athlete{id: athlete_id}, start_date, end_date) do
    Race
    |> where([r], r.athlete_id == ^athlete_id)
    |> where([r], r.race_date >= ^start_date and r.race_date <= ^end_date)
    |> order_by([r], asc: r.race_date)
    |> Repo.all()
  end

  @doc """
  Gets monthly distance stats for the current year.
  Returns a list of %{month: 1, total_km: 120.5}
  """
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
  Groups races by type for the donut chart.
  Returns: %{"ultra" => 5, "trail" => 2}
  """
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

  @doc """
  Gets a list of all dates where a race occurred in a given year (for Heatmap).
  """
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

  @doc """
  Returns races within a specific date range (for Calendar).
  """
  def list_races_between(%Athlete{id: athlete_id}, start_date, end_date) do
    Race
    |> where([r], r.athlete_id == ^athlete_id)
    |> where([r], r.race_date >= ^start_date and r.race_date <= ^end_date)
    |> order_by([r], asc: r.race_date)
    |> Repo.all()
  end

  @doc """
  Gets monthly distance stats for a specific year.
  """
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

  @doc """
  Gets year-to-date summary for a specific year.
  """
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

    # Handle nil values if no races exist for that year
    %{
      count: stats.count || 0,
      distance: stats.distance || Decimal.new(0),
      elevation: stats.elevation || 0,
      time: stats.time || 0
    }
  end

  @doc """
  Gets personal bests (fastest completed races by type)
  """
  def get_personal_bests(%Athlete{id: athlete_id}) do
    # Group by race type and find the one with max distance (usually implied hierarchy)
    # or specialized logic. For simplicity, let's just get the best of each category.

    ["marathon", "half_marathon", "10k", "ultra"]
    |> Enum.map(fn type ->
      best_race =
        Race
        |> where([r], r.athlete_id == ^athlete_id)
        |> where([r], r.status == "completed")
        |> where([r], r.race_type == ^type)
        # Fastest time
        |> order_by([r], asc: r.finish_time_seconds)
        |> limit(1)
        |> Repo.one()

      {type, best_race}
    end)
    |> Enum.filter(fn {_, race} -> race != nil end)
    |> Enum.into(%{})
  end
end
