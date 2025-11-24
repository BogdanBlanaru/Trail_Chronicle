defmodule TrailChronicle.Workers.BackupWorker do
  use Oban.Worker, queue: :default

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Logger.info("Running daily backup task...")
    # TODO: Implement backup logic (S3 upload, database dump, etc.)
    :ok
  end
end
