defmodule TrailChronicle.Repo.Migrations.AddSecurityIndexes do
  use Ecto.Migration

  def change do
    # Improve query performance for authentication lookups
    create_if_not_exists index(:athletes, [:email],
                           where: "confirmed_at IS NOT NULL",
                           name: :athletes_confirmed_email_index
                         )

    # Add index for token lookups (security-critical)
    create_if_not_exists index(:athlete_tokens, [:athlete_id, :context])

    # Add index for session cleanup queries
    create_if_not_exists index(:athlete_tokens, [:inserted_at])
  end
end
