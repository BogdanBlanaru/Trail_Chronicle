defmodule TrailChronicle.Accounts.Athlete do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "athletes" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :naive_datetime

    # Profile fields
    field :first_name, :string
    field :last_name, :string
    field :bio, :string
    field :date_of_birth, :date
    field :gender, :string
    field :country, :string
    field :city, :string
    field :height_cm, :integer
    field :weight_kg, :decimal
    field :running_since_year, :integer
    field :favorite_distance, :string
    field :max_heart_rate, :integer
    field :resting_heart_rate, :integer

    # Preferences
    field :preferred_language, :string, default: "en"
    field :preferred_unit_system, :string, default: "metric"
    field :timezone, :string, default: "UTC"

    # Aggregate stats
    field :total_races, :integer, default: 0
    field :total_distance_km, :decimal, default: Decimal.new("0.00")
    field :total_elevation_m, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  @doc """
  A athlete changeset for registration.
  """
  def registration_changeset(athlete, attrs, opts \\ []) do
    athlete
    |> cast(attrs, [:email, :password, :first_name, :last_name, :preferred_language])
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_required([:first_name, :last_name])
    |> validate_length(:first_name, min: 2, max: 100)
    |> validate_length(:last_name, min: 2, max: 100)
  end

  @doc """
  A athlete changeset for profile updates.
  """
  def profile_changeset(athlete, attrs) do
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
    |> validate_length(:first_name, min: 2, max: 100)
    |> validate_length(:last_name, min: 2, max: 100)
    |> validate_length(:bio, max: 1000)
    |> validate_inclusion(:gender, ["M", "F", "Other"])
    |> validate_inclusion(:preferred_language, ["en", "ro", "fr"])
    |> validate_inclusion(:preferred_unit_system, ["metric", "imperial"])
    |> validate_number(:height_cm, greater_than: 0, less_than: 300)
    |> validate_number(:weight_kg, greater_than: 0, less_than: 300)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/,
      message: "at least one digit or punctuation character"
    )
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, TrailChronicle.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A athlete changeset for changing the email.
  """
  def email_changeset(athlete, attrs, opts \\ []) do
    athlete
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A athlete changeset for changing the password.
  """
  def password_changeset(athlete, attrs, opts \\ []) do
    athlete
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(athlete) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(athlete, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no athlete or the athlete doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(
        %TrailChronicle.Accounts.Athlete{hashed_password: hashed_password},
        password
      )
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{}, [])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
