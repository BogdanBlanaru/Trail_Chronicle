defmodule TrailChronicle.Integrations.StravaClient do
  @moduledoc """
  HTTP client for Strava API v3
  """

  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://www.strava.com/api/v3"
  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.Logger

  @client_id System.get_env("STRAVA_CLIENT_ID")
  @client_secret System.get_env("STRAVA_CLIENT_SECRET")

  def authorize_url(redirect_uri) do
    params = %{
      client_id: @client_id,
      redirect_uri: redirect_uri,
      response_type: "code",
      scope: "activity:read_all"
    }

    query = URI.encode_query(params)
    "https://www.strava.com/oauth/authorize?#{query}"
  end

  def exchange_code(code) do
    post("/oauth/token", %{
      client_id: @client_id,
      client_secret: @client_secret,
      code: code,
      grant_type: "authorization_code"
    })
  end

  def refresh_token(refresh_token) do
    post("/oauth/token", %{
      client_id: @client_id,
      client_secret: @client_secret,
      refresh_token: refresh_token,
      grant_type: "refresh_token"
    })
  end

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
end
