defmodule TrailChronicleWeb.DashboardLive do
  use TrailChronicleWeb, :live_view

  alias TrailChronicle.{Accounts, Racing}

  @impl true
  def mount(_params, session, socket) do
    # For now, we'll hardcode the athlete (we'll add authentication later)
    athlete = Accounts.get_athlete_by_email("bogdan@example.com")
    locale = Map.get(session, "locale", "en")

    if athlete do
      # Load data
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
       |> assign(:locale, locale)
       |> assign(:page_title, "Dashboard")}
    else
      {:ok,
       socket
       |> put_flash(:error, "Please create an athlete account first")
       |> assign(:athlete, nil)
       |> assign(:current_path, "/")
       |> assign(:page_title, "Dashboard")}
    end
  end

  # Helper function to format seconds to HH:MM:SS
  defp format_time(nil), do: "N/A"

  defp format_time(seconds) when is_integer(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    secs = rem(seconds, 60)

    "#{pad(hours)}:#{pad(minutes)}:#{pad(secs)}"
  end

  defp pad(num), do: String.pad_leading(to_string(num), 2, "0")
end
