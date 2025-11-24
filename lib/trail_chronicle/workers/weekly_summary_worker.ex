defmodule TrailChronicle.Workers.WeeklySummaryWorker do
  use Oban.Worker, queue: :emails

  alias TrailChronicle.{Accounts, Racing}
  alias TrailChronicle.Accounts.AthleteNotifier

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    # Send weekly summaries to all athletes
    Accounts.list_athletes()
    |> Enum.each(&send_weekly_summary/1)

    :ok
  end

  defp send_weekly_summary(athlete) do
    today = Date.utc_today()
    week_ago = Date.add(today, -7)

    races = Racing.list_races_between(athlete, week_ago, today)

    if length(races) > 0 do
      total_distance =
        races
        |> Enum.map(& &1.distance_km)
        |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

      AthleteNotifier.deliver_weekly_summary(athlete, races, total_distance)
    end
  end
end
