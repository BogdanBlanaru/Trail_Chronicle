defmodule TrailChronicleWeb.StravaController do
  use TrailChronicleWeb, :controller

  alias TrailChronicle.Integrations
  alias TrailChronicle.Integrations.StravaClient
  alias TrailChronicle.Workers.StravaSyncWorker

  def authorize(conn, _params) do
    redirect_uri = url(~p"/integrations/strava/callback")
    authorize_url = StravaClient.authorize_url(redirect_uri)

    redirect(conn, external: authorize_url)
  end

  def callback(conn, %{"code" => code}) do
    athlete = conn.assigns.current_athlete

    with {:ok, %{status: 200, body: token_data}} <- StravaClient.exchange_code(code),
         {:ok, _integration} <- Integrations.create_strava_integration(athlete, token_data) do
      # Queue background sync job
      %{athlete_id: athlete.id}
      |> StravaSyncWorker.new()
      |> Oban.insert()

      conn
      |> put_flash(:info, "Strava connected! Importing activities in background...")
      |> redirect(to: ~p"/integrations")
    else
      _ ->
        conn
        |> put_flash(:error, "Failed to connect Strava")
        |> redirect(to: ~p"/integrations")
    end
  end

  def disconnect(conn, _params) do
    athlete = conn.assigns.current_athlete

    case Integrations.disconnect_strava(athlete) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Strava disconnected")
        |> redirect(to: ~p"/integrations")

      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to disconnect")
        |> redirect(to: ~p"/integrations")
    end
  end

  def sync(conn, _params) do
    athlete = conn.assigns.current_athlete

    %{athlete_id: athlete.id}
    |> StravaSyncWorker.new()
    |> Oban.insert()

    conn
    |> put_flash(:info, "Sync started in background...")
    |> redirect(to: ~p"/integrations")
  end
end
