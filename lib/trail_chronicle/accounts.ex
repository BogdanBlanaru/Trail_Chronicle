defmodule TrailChronicle.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias TrailChronicle.Repo

  alias TrailChronicle.Accounts.{Athlete, AthleteToken, AthleteNotifier}

  ## Database getters

  @doc """
  Gets a athlete by email.
  """
  def get_athlete_by_email(email) when is_binary(email) do
    Repo.get_by(Athlete, email: email)
  end

  @doc """
  Gets a athlete by email and password.
  """
  def get_athlete_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    athlete = Repo.get_by(Athlete, email: email)
    if Athlete.valid_password?(athlete, password), do: athlete
  end

  @doc """
  Gets a single athlete.
  """
  def get_athlete!(id), do: Repo.get!(Athlete, id)

  ## Athlete registration

  @doc """
  Registers a athlete.
  """
  def register_athlete(attrs) do
    %Athlete{}
    |> Athlete.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking athlete changes.
  """
  def change_athlete_registration(%Athlete{} = athlete, attrs \\ %{}) do
    Athlete.registration_changeset(athlete, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the athlete email.
  """
  def change_athlete_email(athlete, attrs \\ %{}) do
    Athlete.email_changeset(athlete, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing it in the database.
  """
  def apply_athlete_email(athlete, password, attrs) do
    athlete
    |> Athlete.email_changeset(attrs)
    |> Athlete.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the athlete email using the given token.
  """
  def update_athlete_email(athlete, token) do
    context = "change:#{athlete.email}"

    with {:ok, query} <- AthleteToken.verify_email_token_query(token, context),
         %Athlete{} = athlete <- Repo.one(query),
         {:ok, _} <- Repo.transaction(athlete_email_multi(athlete, athlete.email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  @doc """
  Updates the athlete's preferred language.
  """
  def update_athlete_locale(athlete, locale) when locale in ["en", "ro", "fr"] do
    athlete
    |> Ecto.Changeset.change(preferred_language: locale)
    |> Repo.update()
  end

  defp athlete_email_multi(athlete, email, context) do
    changeset =
      athlete
      |> Athlete.email_changeset(%{email: email})
      |> Athlete.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:athlete, changeset)
    |> Ecto.Multi.delete_all(
      :tokens,
      AthleteToken.by_athlete_and_contexts_query(athlete, [context])
    )
  end

  @doc """
  Delivers the update email instructions to the given athlete.
  """
  def deliver_athlete_update_email_instructions(
        %Athlete{} = athlete,
        current_email,
        update_email_url_fun
      )
      when is_function(update_email_url_fun, 1) do
    {encoded_token, athlete_token} =
      AthleteToken.build_email_token(athlete, "change:#{current_email}")

    Repo.insert!(athlete_token)

    AthleteNotifier.deliver_update_email_instructions(
      athlete,
      update_email_url_fun.(encoded_token)
    )
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the athlete password.
  """
  def change_athlete_password(athlete, attrs \\ %{}) do
    Athlete.password_changeset(athlete, attrs, hash_password: false)
  end

  @doc """
  Updates the athlete password.
  """
  def update_athlete_password(athlete, password, attrs) do
    changeset =
      athlete
      |> Athlete.password_changeset(attrs)
      |> Athlete.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:athlete, changeset)
    |> Ecto.Multi.delete_all(:tokens, AthleteToken.by_athlete_and_contexts_query(athlete, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{athlete: athlete}} -> {:ok, athlete}
      {:error, :athlete, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_athlete_session_token(athlete) do
    {token, athlete_token} = AthleteToken.build_session_token(athlete)
    Repo.insert!(athlete_token)
    token
  end

  @doc """
  Gets the athlete with the given signed token.
  """
  def get_athlete_by_session_token(token) do
    {:ok, query} = AthleteToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_athlete_session_token(token) do
    Repo.delete_all(AthleteToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given athlete.
  """
  def deliver_athlete_confirmation_instructions(%Athlete{} = athlete, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if athlete.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, athlete_token} = AthleteToken.build_email_token(athlete, "confirm")
      Repo.insert!(athlete_token)

      AthleteNotifier.deliver_confirmation_instructions(
        athlete,
        confirmation_url_fun.(encoded_token)
      )
    end
  end

  @doc """
  Confirms a athlete by the given token.
  """
  def confirm_athlete(token) do
    with {:ok, query} <- AthleteToken.verify_email_token_query(token, "confirm"),
         %Athlete{} = athlete <- Repo.one(query),
         {:ok, %{athlete: athlete}} <- Repo.transaction(confirm_athlete_multi(athlete)) do
      {:ok, athlete}
    else
      _ -> :error
    end
  end

  defp confirm_athlete_multi(athlete) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:athlete, Athlete.confirm_changeset(athlete))
    |> Ecto.Multi.delete_all(
      :tokens,
      AthleteToken.by_athlete_and_contexts_query(athlete, ["confirm"])
    )
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given athlete.
  """
  def deliver_athlete_reset_password_instructions(%Athlete{} = athlete, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, athlete_token} = AthleteToken.build_email_token(athlete, "reset_password")
    Repo.insert!(athlete_token)

    AthleteNotifier.deliver_reset_password_instructions(
      athlete,
      reset_password_url_fun.(encoded_token)
    )
  end

  @doc """
  Gets the athlete by reset password token.
  """
  def get_athlete_by_reset_password_token(token) do
    with {:ok, query} <- AthleteToken.verify_email_token_query(token, "reset_password"),
         %Athlete{} = athlete <- Repo.one(query) do
      athlete
    else
      _ -> nil
    end
  end

  @doc """
  Resets the athlete password.
  """
  def reset_athlete_password(athlete, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:athlete, Athlete.password_changeset(athlete, attrs))
    |> Ecto.Multi.delete_all(:tokens, AthleteToken.by_athlete_and_contexts_query(athlete, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{athlete: athlete}} -> {:ok, athlete}
      {:error, :athlete, changeset, _} -> {:error, changeset}
    end
  end

  ## Profile management

  @doc """
  Updates athlete profile.
  """
  def update_athlete_profile(%Athlete{} = athlete, attrs) do
    athlete
    |> Athlete.profile_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking athlete profile changes.
  """
  def change_athlete_profile(%Athlete{} = athlete, attrs \\ %{}) do
    Athlete.profile_changeset(athlete, attrs)
  end

  @doc """
  Lists all athletes.
  """
  def list_athletes do
    Repo.all(Athlete)
  end
end
