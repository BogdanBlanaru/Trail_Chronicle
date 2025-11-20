defmodule TrailChronicle.Racing.RacePhoto do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "race_photos" do
    field :image_path, :string
    field :caption, :string
    field :is_featured, :boolean, default: false
    belongs_to :race, TrailChronicle.Racing.Race

    timestamps(type: :utc_datetime)
  end

  def changeset(photo, attrs) do
    photo
    |> cast(attrs, [:race_id, :image_path, :caption, :is_featured])
    |> validate_required([:race_id, :image_path])
  end
end
