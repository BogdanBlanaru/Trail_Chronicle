defmodule TrailChronicle.Repo.Migrations.CreateAthleteTokens do
  use Ecto.Migration

  def change do
    create table(:athlete_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :athlete_id, references(:athletes, type: :binary_id, on_delete: :delete_all),
        null: false

      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:athlete_tokens, [:athlete_id])
    create unique_index(:athlete_tokens, [:context, :token])
  end
end
