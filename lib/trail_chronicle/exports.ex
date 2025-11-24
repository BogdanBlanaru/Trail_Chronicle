defmodule TrailChronicle.Exports do
  @moduledoc """
  Handles data exports (CSV, PDF, JSON)
  """

  alias TrailChronicle.Racing
  alias TrailChronicle.Accounts.Athlete
  alias NimbleCSV.RFC4180, as: CSV

  # --- CSV Export ---

  def export_races_to_csv(%Athlete{} = athlete) do
    races = Racing.list_races(athlete)

    csv_data =
      races
      |> Enum.map(fn race ->
        [
          race.name,
          Date.to_string(race.race_date),
          race.race_type,
          to_string(race.distance_km),
          to_string(race.elevation_gain_m || 0),
          format_time(race.finish_time_seconds),
          race.status,
          race.city,
          race.country
        ]
      end)

    headers = [
      "Name",
      "Date",
      "Type",
      "Distance (km)",
      "Elevation (m)",
      "Time",
      "Status",
      "City",
      "Country"
    ]

    ([headers] ++ csv_data)
    |> CSV.dump_to_iodata()
    |> IO.iodata_to_binary()
  end

  defp format_time(nil), do: ""

  defp format_time(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    secs = rem(seconds, 60)
    "#{pad(hours)}:#{pad(minutes)}:#{pad(secs)}"
  end

  defp pad(num), do: String.pad_leading(to_string(num), 2, "0")

  # --- JSON Export ---

  def export_races_to_json(%Athlete{} = athlete) do
    races = Racing.list_races(athlete)

    races
    |> Enum.map(fn race ->
      %{
        name: race.name,
        date: race.race_date,
        type: race.race_type,
        distance_km: if(race.distance_km, do: Decimal.to_float(race.distance_km), else: nil),
        elevation_gain_m: race.elevation_gain_m,
        finish_time_seconds: race.finish_time_seconds,
        status: race.status,
        city: race.city,
        country: race.country,
        race_report: race.race_report
      }
    end)
    |> Jason.encode!(pretty: true)
  end

  # --- PDF Export (Simple Implementation) ---

  def export_race_to_pdf(_race) do
    {:error, "PDF export is not available in this version. Use CSV or JSON instead."}
  end
end
