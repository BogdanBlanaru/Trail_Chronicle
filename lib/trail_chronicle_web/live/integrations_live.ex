defmodule TrailChronicleWeb.IntegrationsLive do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.Integrations

  @impl true
  def mount(_params, _session, socket) do
    athlete = socket.assigns.current_athlete

    strava_integration = Integrations.get_strava_integration(athlete)

    {:ok,
     socket
     |> assign(:strava_integration, strava_integration)
     |> assign(:current_path, "/integrations")
     |> assign(:page_title, gettext("Integrations"))}
  end

  @impl true
  def handle_event("switch-locale", %{"locale" => locale}, socket) do
    {:noreply, TrailChronicleWeb.LiveHelpers.handle_locale_switch(socket, locale)}
  end
end
