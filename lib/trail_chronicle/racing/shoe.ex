defmodule TrailChronicle.Racing.Shoe do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "shoes" do
    field :brand, :string
    field :model, :string
    field :nickname, :string
    field :distance_limit_km, :integer, default: 800
    field :current_distance_km, :decimal, default: Decimal.new("0.0")
    field :is_retired, :boolean, default: false
    field :purchased_at, :date

    belongs_to :athlete, TrailChronicle.Accounts.Athlete
    has_many :races, TrailChronicle.Racing.Race

    timestamps(type: :utc_datetime)
  end

  def changeset(shoe, attrs) do
    shoe
    |> cast(attrs, [
      :brand,
      :model,
      :nickname,
      :distance_limit_km,
      :is_retired,
      :purchased_at,
      :athlete_id
    ])
    |> validate_required([:brand, :model, :distance_limit_km, :athlete_id])
    |> validate_number(:distance_limit_km, greater_than: 0)
  end
end
