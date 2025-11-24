defmodule TrailChronicle.Workers.StravaSyncWorker do
  use Oban.Worker, queue: :strava_sync, max_attempts: 2

  alias TrailChronicle.Integrations
  alias TrailChronicle.Accounts

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"athlete_id" => athlete_id}}) do
    athlete = Accounts.get_athlete!(athlete_id)

    case Integrations.import_strava_activities(athlete) do
      {:ok, count} ->
        {:ok, "Imported #{count} activities"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
