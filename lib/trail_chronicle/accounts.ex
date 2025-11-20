defmodule TrailChronicle.Accounts do
  @moduledoc """
  The Accounts context.

  Manages athlete accounts, authentication, and profiles.
  """

  import Ecto.Query, warn: false
  alias TrailChronicle.Repo
  alias TrailChronicle.Accounts.Athlete

  ## Athlete CRUD (Create, Read, Update, Delete)

  @doc """
  Returns the list of all athletes.

  ## Examples

      iex> list_athletes()
      [%Athlete{}, ...]

  """
  def list_athletes do
    Repo.all(Athlete)
  end

  @doc """
  Gets a single athlete by ID.

  Raises `Ecto.NoResultsError` if the Athlete does not exist.

  ## Examples

      iex> get_athlete!(123)
      %Athlete{}

      iex> get_athlete!(456)
      ** (Ecto.NoResultsError)

  """
  def get_athlete!(id), do: Repo.get!(Athlete, id)

  @doc """
  Gets a single athlete by email.

  Returns nil if the Athlete does not exist.

  ## Examples

      iex> get_athlete_by_email("bogdan@example.com")
      %Athlete{}

      iex> get_athlete_by_email("unknown@example.com")
      nil

  """
  def get_athlete_by_email(email) when is_binary(email) do
    Repo.get_by(Athlete, email: email)
  end

  @doc """
  Creates an athlete (registration).

  ## Examples

      iex> create_athlete(%{email: "test@example.com", password: "Secret123"})
      {:ok, %Athlete{}}

      iex> create_athlete(%{email: "bad-email"})
      {:error, %Ecto.Changeset{}}

  """
  def create_athlete(attrs \\ %{}) do
    %Athlete{}
    |> Athlete.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an athlete's profile.

  ## Examples

      iex> update_athlete(athlete, %{first_name: "Bogdan"})
      {:ok, %Athlete{}}

      iex> update_athlete(athlete, %{height_cm: -100})
      {:error, %Ecto.Changeset{}}

  """
  def update_athlete(%Athlete{} = athlete, attrs) do
    athlete
    |> Athlete.profile_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an athlete.

  ## Examples

      iex> delete_athlete(athlete)
      {:ok, %Athlete{}}

      iex> delete_athlete(athlete)
      {:error, %Ecto.Changeset{}}

  """
  def delete_athlete(%Athlete{} = athlete) do
    Repo.delete(athlete)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking athlete changes.

  ## Examples

      iex> change_athlete(athlete)
      %Ecto.Changeset{data: %Athlete{}}

  """
  def change_athlete(%Athlete{} = athlete, attrs \\ %{}) do
    Athlete.profile_changeset(athlete, attrs)
  end

  ## Authentication

  @doc """
  Authenticates an athlete by email and password.

  Returns `{:ok, athlete}` if credentials are valid.
  Returns `{:error, :invalid_credentials}` if credentials are invalid.

  ## Examples

      iex> authenticate_athlete("bogdan@example.com", "Secret123")
      {:ok, %Athlete{}}

      iex> authenticate_athlete("bogdan@example.com", "wrong-password")
      {:error, :invalid_credentials}

  """
  def authenticate_athlete(email, password) when is_binary(email) and is_binary(password) do
    athlete = get_athlete_by_email(email)

    cond do
      athlete && Bcrypt.verify_pass(password, athlete.hashed_password) ->
        {:ok, athlete}

      athlete ->
        # Password is wrong, but still run verify_pass to prevent timing attacks
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      true ->
        # No athlete found, run verify_pass to prevent timing attacks
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
    end
  end
end
