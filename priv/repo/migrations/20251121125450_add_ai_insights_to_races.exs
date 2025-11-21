defmodule TrailChronicle.Repo.Migrations.AddAiInsightsToRaces do
  use Ecto.Migration

  def change do
    alter table(:races) do
      add :ai_insight, :text
      add :ai_generated_at, :utc_datetime
    end
  end
end
