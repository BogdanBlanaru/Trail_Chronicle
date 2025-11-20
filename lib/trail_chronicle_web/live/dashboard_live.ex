defmodule TrailChronicleWeb.DashboardLive do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.Racing

  @impl true
  def mount(_params, _session, socket) do
    athlete = socket.assigns.current_athlete

    if athlete do
      stats = Racing.get_race_stats(athlete)
      upcoming_races = Racing.list_upcoming_races(athlete) |> Enum.take(3)
      recent_races = Racing.list_completed_races(athlete) |> Enum.take(3)

      {:ok,
       socket
       |> assign(:athlete, athlete)
       |> assign(:stats, stats)
       |> assign(:upcoming_races, upcoming_races)
       |> assign(:recent_races, recent_races)
       |> assign(:current_path, "/")
       |> assign(:page_title, gettext("Dashboard"))}
    else
      {:ok, redirect(socket, to: ~p"/athletes/log_in")}
    end
  end

  @impl true
  def handle_event("switch-locale", %{"locale" => locale}, socket) do
    {:noreply, TrailChronicleWeb.LiveHelpers.handle_locale_switch(socket, locale)}
  end

  defp format_time(nil), do: "—"

  defp format_time(seconds) when is_integer(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    secs = rem(seconds, 60)

    "#{pad(hours)}:#{pad(minutes)}:#{pad(secs)}"
  end

  defp pad(num), do: String.pad_leading(to_string(num), 2, "0")
end
