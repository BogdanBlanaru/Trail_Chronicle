defmodule TrailChronicle.Repo.Migrations.AddCategoryToShoes do
  use Ecto.Migration

  def change do
    alter table(:shoes) do
      # Categories: "trail", "road", "mixed"
      add :category, :string, default: "road"
    end
  end
end
