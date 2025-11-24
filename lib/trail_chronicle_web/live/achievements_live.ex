defmodule TrailChronicleWeb.AchievementsLive do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.Gamification.Awards

  @impl true
  def mount(_params, _session, socket) do
    athlete = socket.assigns.current_athlete

    if athlete do
      badges = Awards.calculate_badges(athlete)
      earned_count = Enum.count(badges, & &1.earned)

      {:ok,
       socket
       |> assign(:badges, badges)
       |> assign(:earned_count, earned_count)
       |> assign(:total_count, length(badges))
       |> assign(:current_path, "/achievements")
       |> assign(:page_title, gettext("Hall of Fame"))}
    else
      {:ok, redirect(socket, to: ~p"/athletes/log_in")}
    end
  end

  @impl true
  def handle_event("switch-locale", %{"locale" => locale}, socket) do
    {:noreply, TrailChronicleWeb.LiveHelpers.handle_locale_switch(socket, locale)}
  end
end
