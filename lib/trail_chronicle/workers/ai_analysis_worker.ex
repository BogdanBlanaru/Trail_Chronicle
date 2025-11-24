defmodule TrailChronicle.Workers.AiAnalysisWorker do
  use Oban.Worker, queue: :ai_analysis, max_attempts: 3

  alias TrailChronicle.Racing

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"race_id" => race_id}}) do
    race = Racing.get_race!(race_id)

    case Racing.save_ai_insight(race) do
      {:ok, _updated_race} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
