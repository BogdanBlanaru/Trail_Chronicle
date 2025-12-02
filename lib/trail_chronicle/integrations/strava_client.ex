defmodule TrailChronicle.Integrations.StravaClient do
  @moduledoc """
  HTTP client for Strava API v3
  """
  use Tesla
  require Logger

  plug Tesla.Middleware.BaseUrl, "https://www.strava.com/api/v3"
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Logger

  # --- AUTH FLOW ---

  def authorize_url(redirect_uri) do
    client_id = get_client_id()

    if is_nil(client_id) do
      Logger.error("Strava Client ID is missing! Check your environment variables.")
    else
      Logger.info("Generating Strava Authorize URL with Client ID: #{client_id}")
    end

    params = %{
      client_id: client_id,
      redirect_uri: redirect_uri,
      response_type: "code",
      scope: "activity:read_all"
    }

    query = URI.encode_query(params)
    "https://www.strava.com/oauth/authorize?#{query}"
  end

  def exchange_code(code) do
    client_id = get_client_id()
    client_secret = get_client_secret()

    if is_nil(client_id) or is_nil(client_secret) do
      Logger.error("Cannot exchange code: Missing Strava credentials.")
    end

    # Strava requires client_id to be an Integer in JSON payloads
    post("/oauth/token", %{
      client_id: client_id,
      client_secret: client_secret,
      code: code,
      grant_type: "authorization_code"
    })
  end

  def refresh_token(refresh_token) do
    post("/oauth/token", %{
      client_id: get_client_id(),
      client_secret: get_client_secret(),
      refresh_token: refresh_token,
      grant_type: "refresh_token"
    })
  end

  # --- ACTIVITIES ---

  def get_activities(access_token, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 30)
    after_timestamp = Keyword.get(opts, :after)

    params = %{page: page, per_page: per_page}
    params = if after_timestamp, do: Map.put(params, :after, after_timestamp), else: params

    get("/athlete/activities",
      query: params,
      headers: [{"Authorization", "Bearer #{access_token}"}]
    )
  end

  def get_activity_details(access_token, activity_id) do
    get("/activities/#{activity_id}",
      headers: [{"Authorization", "Bearer #{access_token}"}]
    )
  end

  # --- STREAMS ---

  def get_activity_streams(access_token, activity_id) do
    get("/activities/#{activity_id}/streams",
      query: [keys: "latlng,altitude", key_by_type: true],
      headers: [{"Authorization", "Bearer #{access_token}"}]
    )
  end

  # --- HELPER FUNCTIONS ---

  defp get_client_id do
    # Fetch runtime env var
    case System.get_env("STRAVA_CLIENT_ID") do
      nil ->
        nil

      val ->
        # Clean up any accidental quotes or whitespace from bad copy-paste/exports
        clean_val = val |> String.trim() |> String.replace(~r/["']/, "")

        case Integer.parse(clean_val) do
          {int_val, _} ->
            int_val

          :error ->
            Logger.warning("STRAVA_CLIENT_ID is not a valid integer: #{val}")
            nil
        end
    end
  end

  defp get_client_secret do
    case System.get_env("STRAVA_CLIENT_SECRET") do
      nil -> nil
      val -> val |> String.trim() |> String.replace(~r/["']/, "")
    end
  end
end
