defmodule TrailChronicle.Accounts.AthleteToken do
  use Ecto.Schema
  import Ecto.Query
  alias TrailChronicle.Accounts.AthleteToken

  @hash_algorithm :sha256
  @rand_size 32

  @session_validity_in_days 60
  @confirm_validity_in_days 7
  @reset_password_validity_in_days 1

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "athlete_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :athlete, TrailChronicle.Accounts.Athlete

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Generates a token that will be stored in a signed place.
  """
  def build_session_token(athlete) do
    token = :crypto.strong_rand_bytes(@rand_size)
    {token, %AthleteToken{token: token, context: "session", athlete_id: athlete.id}}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.
  """
  def verify_session_token_query(token) do
    query =
      from token in by_token_and_context_query(token, "session"),
        join: athlete in assoc(token, :athlete),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: athlete

    {:ok, query}
  end

  @doc """
  Builds a token and its hash to be delivered to the athlete's email.
  """
  def build_email_token(athlete, context) do
    build_hashed_token(athlete, context, athlete.email)
  end

  defp build_hashed_token(athlete, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %AthleteToken{
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       athlete_id: athlete.id
     }}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.
  """
  def verify_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        days = days_for_context(context)

        query =
          from token in by_token_and_context_query(hashed_token, context),
            join: athlete in assoc(token, :athlete),
            where: token.inserted_at > ago(^days, "day") and token.sent_to == athlete.email,
            select: athlete

        {:ok, query}

      :error ->
        :error
    end
  end

  defp days_for_context("confirm"), do: @confirm_validity_in_days
  defp days_for_context("reset_password"), do: @reset_password_validity_in_days

  @doc """
  Returns the token struct for the given token value and context.
  """
  def by_token_and_context_query(token, context) do
    from AthleteToken, where: [token: ^token, context: ^context]
  end

  @doc """
  Gets all tokens for the given athlete for the given contexts.
  """
  def by_athlete_and_contexts_query(athlete, :all) do
    from t in AthleteToken, where: t.athlete_id == ^athlete.id
  end

  def by_athlete_and_contexts_query(athlete, [_ | _] = contexts) do
    from t in AthleteToken, where: t.athlete_id == ^athlete.id and t.context in ^contexts
  end
end
