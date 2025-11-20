defmodule TrailChronicle.Accounts.Athlete do
  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: TrailChronicleWeb.Gettext

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "athletes" do
    # Authentication
    field :email, :string
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :confirmed_at, :naive_datetime

    # Profile
    field :first_name, :string
    field :last_name, :string
    field :bio, :string
    field :date_of_birth, :date
    field :gender, :string
    field :country, :string
    field :city, :string

    # Physical stats
    field :height_cm, :integer
    field :weight_kg, :decimal

    # Running stats
    field :running_since_year, :integer
    field :favorite_distance, :string
    field :max_heart_rate, :integer
    field :resting_heart_rate, :integer

    # Preferences
    field :preferred_language, :string, default: "en"
    field :preferred_unit_system, :string, default: "metric"
    field :timezone, :string, default: "Europe/Bucharest"

    # Computed stats
    field :total_races, :integer, default: 0
    field :total_distance_km, :decimal
    field :total_elevation_m, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a new athlete (registration).
  """
  def registration_changeset(athlete, attrs) do
    athlete
    |> cast(attrs, [:email, :first_name, :last_name, :password])
    |> validate_required([:email, :password])
    |> validate_email()
    |> validate_password()
    |> hash_password()
  end

  @doc """
  Changeset for updating athlete profile.
  """
  def profile_changeset(athlete, attrs) do
    available_locales = Gettext.known_locales(TrailChronicleWeb.Gettext)

    athlete
    |> cast(attrs, [
      :first_name,
      :last_name,
      :bio,
      :date_of_birth,
      :gender,
      :country,
      :city,
      :height_cm,
      :weight_kg,
      :running_since_year,
      :favorite_distance,
      :max_heart_rate,
      :resting_heart_rate,
      :preferred_language,
      :preferred_unit_system,
      :timezone
    ])
    |> validate_number(:height_cm, greater_than: 0, less_than: 300)
    |> validate_number(:weight_kg, greater_than: 0, less_than: 500)
    |> validate_number(:max_heart_rate, greater_than: 0, less_than: 300)
    |> validate_number(:resting_heart_rate, greater_than: 0, less_than: 200)
    |> validate_inclusion(:preferred_language, available_locales)
    |> validate_inclusion(:preferred_unit_system, ["metric", "imperial"])
  end

  # Private functions

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, TrailChronicle.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> validate_format(:password, ~r/[a-z]/,
      message: "must contain at least one lowercase letter"
    )
    |> validate_format(:password, ~r/[A-Z]/,
      message: "must contain at least one uppercase letter"
    )
    |> validate_format(:password, ~r/[0-9]/, message: "must contain at least one digit")
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end
end
